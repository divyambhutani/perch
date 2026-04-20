import Foundation

actor TranscriptTailer {
    typealias Handler = @Sendable (String, LiveTurn) async -> Void

    private struct Entry {
        let transcriptPath: String
        let watcher: TranscriptFileWatcher
    }

    private var entries: [String: Entry] = [:]
    private var turns: [String: LiveTurn] = [:]
    private var handler: Handler?

    init() {}

    func setHandler(_ handler: @escaping Handler) {
        self.handler = handler
    }

    func reconcile(activeTranscripts: [String: String]) {
        let activeSessionIDs = Set(activeTranscripts.keys)

        for sessionID in entries.keys where !activeSessionIDs.contains(sessionID) {
            stop(sessionID: sessionID)
        }

        for (sessionID, path) in activeTranscripts {
            if let existing = entries[sessionID], existing.transcriptPath == path { continue }
            stop(sessionID: sessionID)
            start(sessionID: sessionID, transcriptPath: path)
        }
    }

    func stopAll() {
        for sessionID in Array(entries.keys) {
            stop(sessionID: sessionID)
        }
    }

    private func start(sessionID: String, transcriptPath: String) {
        let watcher = TranscriptFileWatcher(path: transcriptPath) { [weak self] lines in
            Task { [weak self] in
                await self?.ingest(sessionID: sessionID, lines: lines)
            }
        }
        entries[sessionID] = Entry(transcriptPath: transcriptPath, watcher: watcher)
        turns[sessionID] = .empty
        watcher.start()
    }

    private func stop(sessionID: String) {
        entries.removeValue(forKey: sessionID)?.watcher.stop()
        turns.removeValue(forKey: sessionID)
    }

    private func ingest(sessionID: String, lines: [String]) async {
        guard entries[sessionID] != nil else { return }
        var turn = turns[sessionID] ?? .empty
        for line in lines {
            TranscriptLineParser.apply(line: line, into: &turn)
        }
        turns[sessionID] = turn
        await handler?(sessionID, turn)
    }
}
