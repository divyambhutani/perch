import Foundation

struct JSONLTailer {
    func lines(in url: URL) throws -> [String] {
        let contents = try String(contentsOf: url)
        return contents.split(whereSeparator: \.isNewline).map(String.init)
    }
}
