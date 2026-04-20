import Foundation

struct JSONLParser: Sendable {
    struct Parsed: Equatable, Sendable {
        var events: [TranscriptEvent]
        var remainder: Data
    }

    private let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func parse(contents: String) throws -> [TranscriptEvent] {
        let parsed = try parseStream(Data(contents.utf8), flushTrailing: true)
        return parsed.events
    }

    func parseStream(_ data: Data, flushTrailing: Bool) throws -> Parsed {
        var events: [TranscriptEvent] = []
        var cursor = data.startIndex
        let newline = UInt8(ascii: "\n")

        while let nl = data[cursor...].firstIndex(of: newline) {
            let slice = data[cursor ..< nl]
            cursor = data.index(after: nl)
            try append(slice: slice, into: &events)
        }

        if flushTrailing, cursor < data.endIndex {
            try append(slice: data[cursor ..< data.endIndex], into: &events)
            return Parsed(events: events, remainder: Data())
        }

        return Parsed(events: events, remainder: Data(data[cursor ..< data.endIndex]))
    }

    private func append(slice: Data, into events: inout [TranscriptEvent]) throws {
        let trimmed = slice.drop(while: { $0 == UInt8(ascii: "\r") || $0 == UInt8(ascii: " ") })
        guard !trimmed.isEmpty else { return }
        do {
            events.append(try decoder.decode(TranscriptEvent.self, from: Data(trimmed)))
        } catch {
            throw JSONLError.malformedLine(String(decoding: trimmed, as: UTF8.self))
        }
    }
}
