import Foundation

enum TerminalBundle: String, CaseIterable, Sendable {
    case appleTerminal = "com.apple.Terminal"
    case iterm2 = "com.googlecode.iterm2"
    case ghostty = "com.mitchellh.ghostty"
    case warp = "dev.warp.Warp-Stable"
    case alacritty = "io.alacritty"
    case kitty = "net.kovidgoyal.kitty"
    case vscode = "com.microsoft.VSCode"
    case vscodeOSS = "com.visualstudio.code.oss"
    case cursor = "com.todesktop.230313mzl4w4u92"

    var usesAppleScript: Bool {
        switch self {
        case .appleTerminal, .iterm2: true
        default: false
        }
    }

    static func from(bundleID: String?) -> TerminalBundle? {
        guard let bundleID else { return nil }
        return TerminalBundle.allCases.first(where: { $0.rawValue == bundleID })
    }
}
