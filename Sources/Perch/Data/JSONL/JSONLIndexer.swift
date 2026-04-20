import Foundation

@MainActor
public final class JSONLIndexer {
    private let parser = JSONLParser()
    private(set) var metricsBySession: [String: SessionMetrics] = [:]

    func index(contents: String) throws -> [TranscriptEvent] {
        let events = try parser.parse(contents: contents)
        fold(events)
        return events
    }

    func index(url: URL) throws -> [TranscriptEvent] {
        let data = try Data(contentsOf: url)
        let parsed = try parser.parseStream(data, flushTrailing: true)
        fold(parsed.events)
        return parsed.events
    }

    func fold(_ events: [TranscriptEvent]) {
        for event in events {
            guard let sessionID = event.sessionID, !sessionID.isEmpty else { continue }
            var metrics = metricsBySession[sessionID] ?? .empty(sessionID: sessionID)
            metrics.fold(event)
            metricsBySession[sessionID] = metrics
        }
    }

    func reset() {
        metricsBySession.removeAll()
    }

    func metrics(for sessionID: String) -> SessionMetrics? {
        metricsBySession[sessionID]
    }

    func allMetrics() -> [SessionMetrics] {
        Array(metricsBySession.values)
    }
}
