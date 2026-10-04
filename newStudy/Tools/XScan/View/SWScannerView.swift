import UIKit

enum SWScannerLayout {
    static let lineHeight: CGFloat = 15
    static let flashlightButtonSize: CGFloat = 60

    static func scannerWidth(in size: CGSize) -> CGFloat {
        0.7 * min(size.width, size.height)
    }

    static func scannerRect(in size: CGSize) -> CGRect {
        let width = scannerWidth(in: size)
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - width) / 2,
            width: width,
            height: width
        )
    }
}

final class SWScannerView: UIView {
    private let config: SWQRCodeConfig
    private let scannerLine = UIImageView()
    private let flashlightButton = UIButton(type: .custom)
    private var outerView: SWOuterFrameView?
    private var activityIndicator: UIActivityIndicatorView?
    private(set) var isFlashlightOn = false

    init(frame: CGRect, config: SWQRCodeConfig) {
        self.config = config
        super.init(frame: frame)
        backgroundColor = .clear
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scanner = SWScannerLayout.scannerRect(in: bounds.size)
        outerView?.frame = CGRect(x: 0, y: scanner.minY, width: bounds.width, height: scanner.height)
        scannerLine.frame = CGRect(
            x: scanner.minX,
            y: scanner.minY,
            width: scanner.width,
            height: SWScannerLayout.lineHeight
        )
        let buttonSize = SWScannerLayout.flashlightButtonSize
        flashlightButton.frame = CGRect(
            x: (bounds.width - buttonSize) / 2,
            y: bounds.height - safeAreaInsets.bottom - buttonSize * 2,
            width: buttonSize,
            height: buttonSize
        )
    }

    func scannerRect() -> CGRect {
        SWScannerLayout.scannerRect(in: bounds.size)
    }

    func addScannerLineAnimation() {
        scannerLine.layer.removeAllAnimations()
        startOuterPulse()
        let animation = CABasicAnimation(keyPath: "transform")
        animation.toValue = NSValue(caTransform3D: CATransform3DMakeTranslation(0, SWScannerLayout.scannerWidth(in: UIScreen.main.bounds.size) - SWScannerLayout.lineHeight, 1))
      
        animation.duration = 2.5
        animation.repeatCount = .greatestFiniteMagnitude
        scannerLine.layer.add(animation, forKey: "ScannerLineAnimation")
        scannerLine.layer.speed = 1
    }

    func pauseScannerLineAnimation() {
        let pauseTime = scannerLine.layer.convertTime(CACurrentMediaTime(), from: nil)
        scannerLine.layer.timeOffset = pauseTime
        scannerLine.layer.speed = 0
        outerView?.layer.removeAllAnimations()
        outerView?.transform = .identity
    }

    func showFlashlight(animated: Bool) {
        let updates = { self.flashlightButton.alpha = 1 }
        if animated {
            UIView.animate(withDuration: 0.6, animations: updates) { _ in
                self.flashlightButton.isEnabled = true
            }
        } else {
            updates()
            flashlightButton.isEnabled = true
        }
    }

    func hideFlashlight(animated: Bool) {
        flashlightButton.isEnabled = false
        let updates = { self.flashlightButton.alpha = 0 }
        if animated {
            UIView.animate(withDuration: 0.6, animations: updates)
        } else {
            updates()
        }
    }

    func setFlashlightOn(_ on: Bool) {
        SWQRCodeManager.setFlashlightOn(on)
        isFlashlightOn = on
        flashlightButton.isSelected = on
        flashlightButton.backgroundColor = on
            ? config.navButtonBackgroundColor
            : UIColor.black.withAlphaComponent(0.8)
    }

    func addActivityIndicator() {
        if activityIndicator == nil {
            let indicator = UIActivityIndicatorView(style: config.indicatorViewStyle)
            indicator.center = center
            addSubview(indicator)
            activityIndicator = indicator
        }
        activityIndicator?.startAnimating()
    }

    func removeActivityIndicator() {
        activityIndicator?.removeFromSuperview()
        activityIndicator = nil
    }

    private func setupSubviews() {
        let outer = SWOuterFrameView(frame: .zero, color: config.scannerCornerColor)
        outerView = outer
        addSubview(outer)

        scannerLine.image = UIImage(named: "SWQRCode.bundle/ScannerLine")
        addSubview(scannerLine)

        flashlightButton.layer.cornerRadius = 30
        flashlightButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        flashlightButton.setImage(UIImage(named: "flashlight_off"), for: .normal)
        flashlightButton.setImage(UIImage(named: "flashlight_on"), for: .selected)
        flashlightButton.addTarget(self, action: #selector(toggleFlashlight), for: .touchUpInside)
        addSubview(flashlightButton)

        addScannerLineAnimation()
    }

    @objc private func toggleFlashlight() {
        setFlashlightOn(!isFlashlightOn)
    }

    private func startOuterPulse() {
        guard let outerView else { return }
        outerView.layer.removeAllAnimations()
        UIView.animateKeyframes(
            withDuration: 3,
            delay: 0,
            options: [.repeat, .calculationModeCubicPaced, .allowUserInteraction]
        ) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                outerView.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                outerView.transform = .identity
            }
        }
    }
}
