//
//  CameraViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/4/15.
//

import UIKit
import AVFoundation
import CoreImage
import Photos

// MARK: - Photo Preview View
class PhotoPreviewView: UIView {
    private let imageView = UIImageView()
    private let saveButton = UIButton(type: .system)
    private let retakeButton = UIButton(type: .system)
    
    var onSave: ((UIImage) -> Void)?
    var onRetake: (() -> Void)?
    
    init(image: UIImage, frame: CGRect) {
        super.init(frame: frame)
        setupUI(image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(image: UIImage) {
        backgroundColor = .black
        
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = bounds
        addSubview(imageView)
        
        let buttonHeight: CGFloat = 50
        let buttonWidth: CGFloat = 120
        let bottomPadding: CGFloat = 50
        
        retakeButton.setTitle("重拍", for: .normal)
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.backgroundColor = .darkGray
        retakeButton.layer.cornerRadius = 25
        retakeButton.frame = CGRect(x: 40, y: bounds.height - buttonHeight - bottomPadding, width: buttonWidth, height: buttonHeight)
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
        addSubview(retakeButton)
        
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 25
        saveButton.frame = CGRect(x: bounds.width - buttonWidth - 40, y: bounds.height - buttonHeight - bottomPadding, width: buttonWidth, height: buttonHeight)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        addSubview(saveButton)
    }
    
    @objc private func retakeTapped() {
        onRetake?()
    }
    
    @objc private func saveTapped() {
        if let image = imageView.image {
            onSave?(image)
        }
    }
}

class CameraViewController: UIViewController {

    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let context = CIContext()
    
    // 渲染层，用于显示带滤镜的画面
    private let metalView = UIImageView()
    
    // UI Elements
    private let captureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("美颜: 关", for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let stickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("贴纸", for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("返回", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let stickerContainer = UIView()
    private let watermarkView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "Shot on newStudy"
        label.textColor = .white.withAlphaComponent(0.8)
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.tag = 100
        
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: Date())
        dateLabel.textColor = .white.withAlphaComponent(0.6)
        dateLabel.font = .systemFont(ofSize: 10)
        dateLabel.tag = 101
        
        view.addSubview(label)
        view.addSubview(dateLabel)
        return view
    }()
    
    private var isBeautyOn = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            previewLayer.frame = view.bounds
        }
        metalView.frame = view.bounds
        stickerContainer.frame = view.bounds
        
        // 设置水印位置
        let watermarkWidth: CGFloat = 150
        let watermarkHeight: CGFloat = 40
        watermarkView.frame = CGRect(
            x: 20,
            y: view.bounds.height - 230, // 避开按钮
            width: watermarkWidth,
            height: watermarkHeight
        )
        if let label = watermarkView.viewWithTag(100) as? UILabel {
            label.frame = CGRect(x: 0, y: 0, width: watermarkWidth, height: 20)
        }
        if let dateLabel = watermarkView.viewWithTag(101) as? UILabel {
            dateLabel.frame = CGRect(x: 0, y: 22, width: watermarkWidth, height: 14)
        }
        
        captureButton.frame = CGRect(x: (view.bounds.width - 70) / 2, y: view.bounds.height - 120, width: 70, height: 70)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // 渲染视图 (用于显示滤镜效果)
        metalView.contentMode = .scaleAspectFill
        view.addSubview(metalView)
        metalView.isHidden = true // 默认隐藏，开启美颜时显示
        
        // 贴纸容器
        view.addSubview(stickerContainer)
        stickerContainer.isUserInteractionEnabled = true
        
        // 添加水印视图
        view.addSubview(watermarkView)
        
        // 返回按钮
        backButton.frame = CGRect(x: 20, y: 50, width: 60, height: 44)
        backButton.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
        view.addSubview(backButton)
        
        // 拍照按钮
        view.addSubview(captureButton)
        captureButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        
        // 功能按钮
        let stackView = UIStackView(arrangedSubviews: [filterButton, stickerButton])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.frame = CGRect(x: 20, y: view.bounds.height - 180, width: view.bounds.width - 40, height: 44)
        view.addSubview(stackView)
        
        filterButton.addTarget(self, action: #selector(toggleBeauty), for: .touchUpInside)
        stickerButton.addTarget(self, action: #selector(addSticker), for: .touchUpInside)
    }
    
    private func checkPermissions() {
        // 相机权限
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showErrorAlert(message: "相机权限被拒绝，无法使用该功能")
                    }
                }
            }
        case .denied, .restricted:
            showErrorAlert(message: "相机权限已被禁用，请在系统设置中开启")
        @unknown default:
            break
        }
        
        // 相册权限
        PHPhotoLibrary.requestAuthorization { _ in }
    }
    
    private func setupCamera() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.showErrorAlert(message: "模拟器不支持相机功能，请使用真机测试")
        }
        return
        #endif

        // 权限二次确认
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            DispatchQueue.main.async {
                self.showErrorAlert(message: "相机权限未授权，请在设置中开启")
            }
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // 获取前置摄像头 (更通用的获取方式)
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        guard let device = deviceDiscoverySession.devices.first else {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.showErrorAlert(message: "无法获取前置摄像头硬件")
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                throw NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法添加相机输入"])
            }
        } catch {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.showErrorAlert(message: "相机输入初始化失败: \(error.localizedDescription)")
            }
            return
        }
        
        // 预览层 (默认实时画面)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // 视频输出 (用于实时滤镜)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            // 设置输出格式
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            // 设置视频方向和镜像 (注意：要在 addOutput 之后设置)
            if let connection = videoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true // 前置摄像头开启镜像
                }
            }
        }
        
        // 照片输出
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            // 确保拍照的方向也是竖屏
            if let connection = photoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
            }
        }
        
        captureSession.commitConfiguration()
        
        // 在后台线程启动
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "相机错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        self.present(alert, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.stopRunning()
            }
        }
    }

    // MARK: - Actions
    @objc private func dismissCamera() {
        captureSession.stopRunning()
        dismiss(animated: true)
    }
    
    @objc private func toggleBeauty() {
        isBeautyOn.toggle()
        filterButton.setTitle(isBeautyOn ? "美颜: 开" : "美颜: 关", for: .normal)
        metalView.isHidden = !isBeautyOn
        previewLayer.isHidden = isBeautyOn
    }
    
    @objc private func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // 拍照闪烁动画
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = .white
        view.addSubview(flashView)
        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
    }
    
    @objc private func addSticker() {
        let stickers = ["✨", "🌈", "🐱", "🐶", "🍓"]
        let sticker = stickers.randomElement() ?? "✨"
        
        let label = UILabel(frame: CGRect(x: CGFloat.random(in: 50...200), y: CGFloat.random(in: 100...300), width: 100, height: 100))
        label.text = sticker
        label.font = .systemFont(ofSize: 80)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        
        // 添加拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        label.addGestureRecognizer(pan)
        
        // 添加双击删除手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        label.addGestureRecognizer(doubleTap)
        
        stickerContainer.addSubview(label)
        
        label.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            label.transform = .identity
        })
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if let sticker = gesture.view {
            sticker.center = CGPoint(x: sticker.center.x + translation.x, y: sticker.center.y + translation.y)
        }
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if let sticker = gesture.view {
            UIView.animate(withDuration: 0.2, animations: {
                sticker.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                sticker.alpha = 0
            }) { _ in
                sticker.removeFromSuperview()
            }
        }
    }
    
    private func saveToAlbum(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                let message = success ? "照片已保存到相册" : "保存失败"
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                self.present(alert, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    alert.dismiss(animated: true)
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isBeautyOn, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // 更加明显的美颜效果组合：平滑 + 提亮
        // 1. 磨皮效果
        let filter = CIFilter(name: "CIBilateralBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(10.0, forKey: "inputRadius") // 调大半径使效果明显
        
        guard let blurredImage = filter?.outputImage else { return }
        
        // 2. 提亮效果
        let exposureFilter = CIFilter(name: "CIExposureAdjust")
        exposureFilter?.setValue(blurredImage, forKey: kCIInputImageKey)
        exposureFilter?.setValue(0.5, forKey: kCIInputEVKey) // 提高曝光度
        
        if let outputImage = exposureFilter?.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let finalImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.metalView.image = finalImage
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), var capturedImage = UIImage(data: imageData) else { return }
        
        // 1. 处理前置摄像头镜像问题
        if let cgImage = capturedImage.cgImage {
            // 前置摄像头拍摄的照片默认是镜像反向的，需要根据需求调整
            capturedImage = UIImage(cgImage: cgImage, scale: capturedImage.scale, orientation: .leftMirrored)
        }
        
        // 2. 如果开启了美颜，对拍摄的照片应用相同的滤镜
        if isBeautyOn {
            let ciImage = CIImage(image: capturedImage)
            let filter = CIFilter(name: "CIBilateralBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(15.0, forKey: "inputRadius")
            
            let exposureFilter = CIFilter(name: "CIExposureAdjust")
            exposureFilter?.setValue(filter?.outputImage, forKey: kCIInputImageKey)
            exposureFilter?.setValue(0.5, forKey: kCIInputEVKey)
            
            if let outputCIImage = exposureFilter?.outputImage,
               let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
                capturedImage = UIImage(cgImage: cgImage)
            }
        }
        
        // 3. 合成照片：底图(拍摄的照片) + 贴纸层 (排除按钮层)
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let finalImage = renderer.image { context in
            // 计算 Aspect Fill 的绘制区域，防止变形
            let targetRect = view.bounds
            let imageSize = capturedImage.size
            let widthRatio = targetRect.width / imageSize.width
            let heightRatio = targetRect.height / imageSize.height
            let ratio = max(widthRatio, heightRatio)
            
            let newSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
            let drawRect = CGRect(
                x: (targetRect.width - newSize.width) / 2,
                y: (targetRect.height - newSize.height) / 2,
                width: newSize.width,
                height: newSize.height
            )
            
            // 绘制拍摄的照片作为背景
            capturedImage.draw(in: drawRect)
            
            // 绘制贴纸容器 (仅绘制贴纸，不绘制按钮或其他 UI)
            stickerContainer.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            
            // 绘制水印 (直接在最终图片上合成)
            watermarkView.drawHierarchy(in: watermarkView.frame, afterScreenUpdates: true)
        }
        
        // 展示预览视图
        DispatchQueue.main.async {
            self.showPhotoPreview(image: finalImage)
        }
    }
    
    private func showPhotoPreview(image: UIImage) {
        let preview = PhotoPreviewView(image: image, frame: view.bounds)
        view.addSubview(preview)
        
        preview.onSave = { [weak self] image in
            self?.saveToAlbum(image: image)
            preview.removeFromSuperview()
        }
        
        preview.onRetake = {
            preview.removeFromSuperview()
        }
    }
}
