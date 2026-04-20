import Foundation

enum HookServerConfiguration {
    static let host = "127.0.0.1"
    static let defaultPort: UInt16 = 45321
    static let hooksPath = "/hooks"
    static let portFallbackAttempts = 20

    static var endpointURL: URL {
        url(for: defaultPort)
    }

    static func url(for port: UInt16) -> URL {
        URL(string: "http://\(host):\(port)\(hooksPath)")!
    }
}
