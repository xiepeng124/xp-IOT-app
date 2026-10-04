import AVFoundation
import Photos
import UIKit

enum SWQRCodeManager {
    static func checkCameraAuthorization(from presenter: UIViewController?, completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        case .denied, .restricted:
            presentSettingsAlert(
                title: "请在“设置-隐私-相机”选项中，允许访问你的相机",
                from: presenter
            )
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    static func checkAlbumAuthorization(from presenter: UIViewController?, completion: @escaping (Bool) -> Void) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            } else {
                PHPhotoLibrary.requestAuthorization { newStatus in
                    completion(newStatus == .authorized)
                }
            }
        case .denied, .restricted:
            presentSettingsAlert(
                title: "请在“设置-隐私-相片”选项中，允许访问你的相册",
                from: presenter
            )
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    static func metadataObjectTypes(for type: SWScannerType) -> [AVMetadataObject.ObjectType] {
        let barcodes: [AVMetadataObject.ObjectType] = [
            .ean13, .ean8, .upce, .code39, .code39Mod43, .code93, .code128, .pdf417
        ]
        switch type {
        case .qrCode:
            return [.qr]
        case .barCode:
            return barcodes
        case .both:
            return [.qr] + barcodes
        }
    }

    static func navigationTitle(for type: SWScannerType) -> String {
        switch type {
        case .qrCode: return "二维码"
        case .barCode: return "条码"
        case .both: return "二维码/条码"
        }
    }

    static func setFlashlightOn(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            if device.hasFlash {
                device.flashMode = on ? .on : .off
            }
            device.unlockForConfiguration()
        } catch {
            print("SWQRCode flashlight error: \(error)")
        }
    }

    private static func presentSettingsAlert(title: String, from presenter: UIViewController?) {
        guard let presenter else { return }
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            presenter.present(alert, animated: true)
        }
    }
}
