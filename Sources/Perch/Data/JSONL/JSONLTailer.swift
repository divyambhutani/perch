import Foundation

actor JSONLTailer {
    enum TailerError: Error, Equatable, Sendable {
        case openFailed(String)
    }

    private let parser = JSONLParser()
    private let url: URL
    private var handle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var remainder = Data()
    private var onEvents: (@Sendable ([TranscriptEvent]) async -> Void)?

    init(url: URL) {
        self.url = url
    }

    func start(seekToEnd: Bool = true, onEvents: @escaping @Sendable ([TranscriptEvent]) async -> Void) async throws {
        self.onEvents = onEvents
        try openHandle(seekToEnd: seekToEnd)
        await drain()
    }

    func stop() {
        source?.cancel()
        source = nil
        try? handle?.close()
        handle = nil
        remainder.removeAll()
    }

    private func openHandle(seekToEnd: Bool) throws {
        let fd = Darwin.open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            throw TailerError.openFailed(url.path)
        }

        let fileHandle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        if seekToEnd {
            try fileHandle.seekToEnd()
        }
        handle = fileHandle

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.extend, .delete, .rename],
            queue: .global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { await self.handleEvent(source.data) }
        }
        source.setCancelHandler {}
        source.resume()
        self.source = source
    }

    private func handleEvent(_ mask: DispatchSource.FileSystemEvent) async {
        if mask.contains(.extend) {
            await drain()
        }
        if mask.contains(.delete) || mask.contains(.rename) {
            source?.cancel()
            source = nil
            try? handle?.close()
            handle = nil
            try? await reopenOnRotation()
        }
    }

    private func reopenOnRotation() async throws {
        var attempts = 0
        while attempts < 20, !FileManager.default.fileExists(atPath: url.path) {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try openHandle(seekToEnd: false)
        await drain()
    }

    private func drain() async {
        guard let handle else { return }
        var chunk = Data()
        while true {
            guard let data = try? handle.read(upToCount: 65_536), !data.isEmpty else { break }
            chunk.append(data)
        }
        guard !chunk.isEmpty else { return }
        remainder.append(chunk)
        do {
            let parsed = try parser.parseStream(remainder, flushTrailing: false)
            remainder = parsed.remainder
            if !parsed.events.isEmpty {
                await onEvents?(parsed.events)
            }
        } catch {
            remainder.removeAll()
        }
    }
}
