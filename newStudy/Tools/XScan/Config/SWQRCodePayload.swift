import Foundation

enum SWQRCodePayload: Equatable {
    case inAppWeb(url: String, injectToken: Bool)
    case http(String)
    case systemWeb(String)
    case loginScan(uuid: String)
    case plain(String)

    static func parse(_ value: String) -> SWQRCodePayload {
        if value.hasPrefix("yyzd://web=") {
            let url = value.components(separatedBy: "//web=").last ?? value
            return .inAppWeb(url: url, injectToken: true)
        }
        if value.hasPrefix("yyzd://sysweb=") {
            return .systemWeb(value.components(separatedBy: "//sysweb=").last ?? "")
        }
        if value.hasPrefix("qyzd://loginscan=") {
            let payload = value.components(separatedBy: "loginscan=").last ?? ""
            if let data = payload.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let uuid = json["uuid"] as? String {
                return .loginScan(uuid: uuid)
            }
            return .plain(value)
        }
        if value.hasPrefix("http") {
            return .http(value)
        }
        return .plain(value)
    }
}
