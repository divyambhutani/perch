import Foundation

@MainActor
final class JSONLIndexer {
    private let parser = JSONLParser()

    func index(contents: String) throws -> [TranscriptEvent] {
        try parser.parse(contents: contents)
    }
}
