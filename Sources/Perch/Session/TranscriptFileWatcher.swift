import Foundation

final class TranscriptFileWatcher: @unchecked Sendable {
    typealias LinesHandler = @Sendable ([String]) -> Void

    let path: String

    private var fd: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var offset: UInt64 = 0
    private var residual = Data()
    private let queue = DispatchQueue(label: "com.perch.jsonltail", qos: .utility)
    private let handler: LinesHandler

    init(path: String, onLines: @escaping LinesHandler) {
        self.path = path
        self.handler = onLines
    }

    func start() {
        queue.async { [weak self] in
            self?.openAndWatch()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.teardown()
        }
    }

    private func openAndWatch() {
        let descriptor = open(path, O_RDONLY)
        guard descriptor >= 0 else { return }
        fd = descriptor

        // Backfill: read the existing tail so the UI shows the current turn immediately.
        let tailLineLimit = 500
        if let initial = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)).readToEnd() {
            offset = UInt64(initial.count)
            let lines = parse(data: initial)
            if !lines.isEmpty {
                let bounded = Array(lines.suffix(tailLineLimit))
                handler(bounded)
            }
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.extend, .delete, .rename],
            queue: queue
        )
        src.setEventHandler { [weak self] in
            guard let self else { return }
            let events = src.data
            if events.contains(.delete) || events.contains(.rename) {
                self.teardown()
                return
            }
            self.readAppended()
        }
        src.setCancelHandler { [fd] in
            if fd >= 0 { close(fd) }
        }
        source = src
        src.resume()
    }

    private func readAppended() {
        guard fd >= 0 else { return }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        do {
            try handle.seek(toOffset: offset)
        } catch {
            return
        }
        let data = handle.availableData
        guard !data.isEmpty else { return }
        offset += UInt64(data.count)
        let lines = parse(data: data)
        if !lines.isEmpty {
            handler(lines)
        }
    }

    private func parse(data: Data) -> [String] {
        residual.append(data)
        var lines: [String] = []
        while let newlineIndex = residual.firstIndex(of: 0x0A) {
            let lineSlice = residual.prefix(upTo: newlineIndex)
            if !lineSlice.isEmpty, let line = String(data: lineSlice, encoding: .utf8) {
                lines.append(line)
            }
            residual.removeSubrange(residual.startIndex...newlineIndex)
        }
        return lines
    }

    private func teardown() {
        source?.cancel()
        source = nil
        fd = -1
        offset = 0
        residual.removeAll(keepingCapacity: false)
    }
}
