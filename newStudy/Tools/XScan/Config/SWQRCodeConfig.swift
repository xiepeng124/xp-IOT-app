import UIKit

@objc enum SWScannerType: Int {
    case qrCode
    case barCode
    case both
}

@objc enum SWScannerArea: Int {
    case `default`
    case fullScreen
}

final class SWQRCodeConfig {
    var scannerType: SWScannerType = .qrCode
    var scannerArea: SWScannerArea = .default
    var scannerCornerColor = UIColor(red: 63 / 255, green: 187 / 255, blue: 54 / 255, alpha: 1)
    var scannerBorderColor: UIColor = .white
    var indicatorViewStyle: UIActivityIndicatorView.Style = .large
    /// 扫描到 http(s) 链接时是否由模块直接打开
    var isOpenWeb = true
    var navButtonBackgroundColor = UIColor(white: 0.85, alpha: 0.9)
    var restoredNavigationBarColor = UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)
    /// 替换 `yyzd://web=` 中 `{token}` 的取值
    var tokenProvider: (() -> String)?
}
