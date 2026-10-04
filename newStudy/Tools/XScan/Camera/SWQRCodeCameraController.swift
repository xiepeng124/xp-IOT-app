import AVFoundation
import ImageIO
import UIKit

protocol SWQRCodeCameraDelegate: AnyObject {
    func cameraDidScan(_ value: String)
    func cameraDidUpdateBrightness(_ value: CGFloat)
}

final class SWQRCodeCameraController: NSObject {
    let session = AVCaptureSession()
    private(set) var device: AVCaptureDevice?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    weak var delegate: SWQRCodeCameraDelegate?

    private let sessionQueue = DispatchQueue(label: "com.swqrcode.session")
    private let brightnessQueue = DispatchQueue(label: "com.swqrcode.brightness")
    private var lastBrightnessCheck = Date.distantPast
    private let zoomRange: ClosedRange<CGFloat> = 1.0 ... 2.5
    private var beginGestureScale: CGFloat = 1
    private(set) var currentZoom: CGFloat = 1

    func configure(in view: UIView, config: SWQRCodeConfig, scannerRect: CGRect) {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        self.device = device

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            let types = SWQRCodeManager.metadataObjectTypes(for: config.scannerType)
            metadataOutput.metadataObjectTypes = types.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }
            if config.scannerArea == .default, view.bounds.width > 0, view.bounds.height > 0 {
                metadataOutput.rectOfInterest = CGRect(
                    x: scannerRect.minY / view.bounds.height,
                    y: scannerRect.minX / view.bounds.width,
                    width: scannerRect.height / view.bounds.height,
                    height: scannerRect.width / view.bounds.width
                )
            }
        }

        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: brightnessQueue)
        }

        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    func layoutPreview(in view: UIView) {
        previewLayer?.frame = view.layer.bounds
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func setZoom(_ scale: CGFloat, fromGestureBegin: Bool = false) {
        guard let device else { return }
        if fromGestureBegin {
            beginGestureScale = max(currentZoom, 1)
        }
        let maxZoom = min(zoomRange.upperBound, device.maxAvailableVideoZoomFactor)
        let target = min(max(scale, zoomRange.lowerBound), maxZoom)
        applyZoom(target)
    }

    func pinchScale(_ gestureScale: CGFloat) {
        setZoom(beginGestureScale * gestureScale)
    }

    func toggleZoom() {
        setZoom(currentZoom > 1 ? 1 : 2)
        focus()
    }

    func rememberPinchBegin() {
        beginGestureScale = max(currentZoom, 1)
    }

    private func applyZoom(_ scale: CGFloat) {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = scale
            currentZoom = scale
            device.unlockForConfiguration()
        } catch {
            print("SWQRCode zoom error: \(error)")
        }
    }

    private func focus() {
        guard let device, device.isFocusModeSupported(.autoFocus) else { return }
        do {
            try device.lockForConfiguration()
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {
            print("SWQRCode focus error: \(error)")
        }
    }
}

extension SWQRCodeCameraController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = code.stringValue,
              !value.isEmpty else { return }
        delegate?.cameraDidScan(value)
    }
}

extension SWQRCodeCameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastBrightnessCheck) > 0.4 else { return }
        lastBrightnessCheck = now

        guard let metadata = CMCopyDictionaryOfAttachments(
            allocator: nil,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        ) as? [String: Any],
              let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let brightness = exif[kCGImagePropertyExifBrightnessValue as String] as? CGFloat else { return }

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.cameraDidUpdateBrightness(brightness)
        }
    }
}
