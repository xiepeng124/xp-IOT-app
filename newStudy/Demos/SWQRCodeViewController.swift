import UIKit

protocol SWQRCodeViewControllerDelegate: AnyObject {
    func qrCodeViewController(_ controller: SWQRCodeViewController, didScan value: String)
    func qrCodeViewController(_ controller: SWQRCodeViewController, shouldOpenWeb urlString: String)
    func qrCodeViewController(_ controller: SWQRCodeViewController, shouldOpenSystem url: URL)
    func qrCodeViewController(_ controller: SWQRCodeViewController, didScanLogin uuid: String)
}

extension SWQRCodeViewControllerDelegate {
    func qrCodeViewController(_ controller: SWQRCodeViewController, didScan value: String) {}
    func qrCodeViewController(_ controller: SWQRCodeViewController, shouldOpenWeb urlString: String) {}
    func qrCodeViewController(_ controller: SWQRCodeViewController, shouldOpenSystem url: URL) {}
    func qrCodeViewController(_ controller: SWQRCodeViewController, didScanLogin uuid: String) {}
}

final class SWQRCodeViewController: UIViewController {
    var codeConfig = SWQRCodeConfig()
    /// 1 企业信息，2 快速登录，3 返回时无动画
    var type: Int = 0
    /// == 1 时扫描到 http 直接打开网页
    var isOpen: Int = 0
    var searchValueBlock: ((String) -> Void)?
    weak var delegate: SWQRCodeViewControllerDelegate?

    private lazy var scannerView = SWScannerView(frame: .zero, config: codeConfig)
    private let camera = SWQRCodeCameraController()
    private var isHandlingResult = false
    private var isCameraConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupNavigation()
        setupScanner()
        camera.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scannerView.frame = view.bounds
        camera.layoutPreview(in: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        applyTransparentNavigationBar()
        resumeScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerView.setFlashlightOn(false)
//        restoreNavigationBar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseScanning()
        navigationController?.navigationBar.backgroundColor = codeConfig.restoredNavigationBarColor
    }

    func orientationChange() {
        view.setNeedsLayout()
        scannerView.setNeedsLayout()
        scannerView.setNeedsDisplay()
        scannerView.addScannerLineAnimation()
    }

    private func setupNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: roundButton(
            image: UIImage(named: "Icon_nav_reback"),
            action: #selector(popBack)
        ))
        let albumButton = roundButton(title: "相册", action: #selector(showAlbum))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: albumButton)
    }

    private func setupScanner() {
        scannerView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(scannerView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        view.addGestureRecognizer(pinch)

        SWQRCodeManager.checkCameraAuthorization(from: self) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.configureCameraIfNeeded()
            }
        }
    }

    private func configureCameraIfNeeded() {
        guard !isCameraConfigured else {
            camera.start()
            return
        }
//        view.layoutIfNeeded()
        camera.configure(
            in: view,
            config: codeConfig,
            scannerRect: scannerView.scannerRect()
        )
        isCameraConfigured = true
        camera.start()
    }

    private func roundButton(title: String? = nil, image: UIImage? = nil, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.layer.cornerRadius = 22
        button.backgroundColor = codeConfig.navButtonBackgroundColor
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func applyTransparentNavigationBar() {
        navigationController?.navigationBar.backgroundColor = .clear
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func restoreNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = codeConfig.restoredNavigationBarColor
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func popBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func showAlbum() {
        SWQRCodeManager.checkAlbumAuthorization(from: self) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.presentAlbumPicker()
            }
        }
    }

    private func presentAlbumPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func toggleZoom() {
        camera.toggleZoom()
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        camera.pinchScale(gesture.scale)
    }

    @objc private func appDidBecomeActive() {
        resumeScanning()
    }

    @objc private func appWillResignActive() {
        pauseScanning()
    }

    private func resumeScanning() {
        isHandlingResult = false
        camera.start()
        scannerView.addScannerLineAnimation()
    }

    private func pauseScanning() {
        camera.stop()
        scannerView.pauseScannerLineAnimation()
    }

    private func handleScanValue(_ value: String) {
        guard !isHandlingResult else { return }
        isHandlingResult = true
        pauseScanning()
        let alert = UIAlertController(title: "扫描结果", message: value, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default,handler: { [weak self] action in
            self?.resumeScanning()
        }))
        self.present(alert, animated: true) {
            
        }
      
        
//        switch SWQRCodePayload.parse(value) {
//        case .inAppWeb(let url, let injectToken):
//            let resolved = injectToken
//                ? url.replacingOccurrences(of: "{token}", with: codeConfig.tokenProvider?() ?? "")
//                : url
//            openWeb(resolved)
//        case .http(let url):
//            if isOpen == 1 {
//                openWeb(url)
//            } else if !codeConfig.isOpenWeb {
//                finishWithValue(url)
//            } else {
//                openWeb(url)
//            }
//        case .systemWeb(let raw):
//            guard let url = URL(string: raw), UIApplication.shared.canOpenURL(url) else {
//                presentMessage("无效地址")
//                resumeScanning()
//                return
//            }
//            if delegate != nil {
//                delegate?.qrCodeViewController(self, shouldOpenSystem: url)
//            } else {
//                UIApplication.shared.open(url)
//            }
//            resumeScanning()
//        case .loginScan(let uuid):
//            if delegate != nil {
//                delegate?.qrCodeViewController(self, didScanLogin: uuid)
//            } else {
//                finishWithValue(value)
//            }
//        case .plain:
//            finishWithValue(value)
//        }
    }

    private func openWeb(_ urlString: String) {
        if delegate != nil {
            delegate?.qrCodeViewController(self, shouldOpenWeb: urlString)
        } else {
            finishWithValue(urlString)
        }
    }

    private func finishWithValue(_ value: String) {
        delegate?.qrCodeViewController(self, didScan: value)
        searchValueBlock?(value)
        navigationController?.popViewController(animated: type != 3)
    }

    private func presentMessage(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SWQRCodeViewController: SWQRCodeCameraDelegate {
    func cameraDidScan(_ value: String) {
        handleScanValue(value)
    }

    func cameraDidUpdateBrightness(_ value: CGFloat) {
        if !scannerView.isFlashlightOn, value < 0 {
            scannerView.showFlashlight(animated: true)
        }
    }
}

extension SWQRCodeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer {
            camera.rememberPinchBegin()
        }
        return true
    }
}

extension SWQRCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            self?.recognizeQRCode(in: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func recognizeQRCode(in image: UIImage?) {
        guard let image,
              let ciImage = CIImage(image: image),
              let detector = CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: nil,
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
              ),
              let feature = detector.features(in: ciImage).first as? CIQRCodeFeature,
              let value = feature.messageString,
              !value.isEmpty else {
            let alert = UIAlertController(title: "照片中未识别到二维码/条码", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
                self?.resumeScanning()
            })
            present(alert, animated: true)
            return
        }
        handleScanValue(value)
    }
}
