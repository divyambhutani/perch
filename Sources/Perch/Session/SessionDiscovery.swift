import Foundation

actor SessionDiscovery {
    typealias DiscoveryHandler = @Sendable ([DiscoveredSession]) async -> Void
    typealias MetricsHandler = @Sendable (SessionMetrics) async -> Void
    typealias LiveProcessProvider = @Sendable () -> [LiveClaudeProcess]

    static let defaultRecencyWindow: TimeInterval = 24 * 60 * 60
    static let defaultRefreshInterval: Duration = .seconds(30)

    private let projectsDirectory: URL
    private let recencyWindow: TimeInterval
    private let refreshInterval: Duration
    private let fileManager: FileManager
    private let liveProcessProvider: LiveProcessProvider
    private let requireLiveProcess: Bool
    private let parser = JSONLParser()

    private var tailers: [URL: JSONLTailer] = [:]
    private var metricsByURL: [URL: SessionMetrics] = [:]
    private var sessionIDByURL: [URL: String] = [:]
    private var refreshTask: Task<Void, Never>?
    private var discoveryHandler: DiscoveryHandler?
    private var metricsHandler: MetricsHandler?

    init(
        projectsDirectory: URL = SessionDiscovery.defaultProjectsDirectory(),
        recencyWindow: TimeInterval = SessionDiscovery.defaultRecencyWindow,
        refreshInterval: Duration = SessionDiscovery.defaultRefreshInterval,
        fileManager: FileManager = .default,
        liveProcessProvider: @escaping LiveProcessProvider = { LiveClaudeProcessSnapshotter.snapshot() },
        requireLiveProcess: Bool = false
    ) {
        self.projectsDirectory = projectsDirectory
        self.recencyWindow = recencyWindow
        self.refreshInterval = refreshInterval
        self.fileManager = fileManager
        self.liveProcessProvider = liveProcessProvider
        self.requireLiveProcess = requireLiveProcess
    }

    static func defaultProjectsDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude/projects")
    }

    func start(
        onDiscovery: @escaping DiscoveryHandler,
        onMetrics: @escaping MetricsHandler
    ) async {
        discoveryHandler = onDiscovery
        metricsHandler = onMetrics
        await refresh()
        refreshTask?.cancel()
        let interval = refreshInterval
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                if Task.isCancelled { break }
                await self?.refresh()
            }
        }
    }

    func stop() async {
        refreshTask?.cancel()
        refreshTask = nil
        for tailer in tailers.values { await tailer.stop() }
        tailers.removeAll()
        metricsByURL.removeAll()
        sessionIDByURL.removeAll()
        discoveryHandler = nil
        metricsHandler = nil
    }

    @discardableResult
    func refresh() async -> [DiscoveredSession] {
        let discovered = enumerateRecent()
        let liveURLs = Set(discovered.map(\.jsonlURL))

        for (url, tailer) in tailers where !liveURLs.contains(url) {
            await tailer.stop()
            tailers.removeValue(forKey: url)
            metricsByURL.removeValue(forKey: url)
            sessionIDByURL.removeValue(forKey: url)
        }

        for session in discovered where tailers[session.jsonlURL] == nil {
            let tailer = JSONLTailer(url: session.jsonlURL)
            tailers[session.jsonlURL] = tailer
            sessionIDByURL[session.jsonlURL] = session.sessionID
            let jsonlURL = session.jsonlURL
            do {
                try await tailer.start(seekToEnd: false) { [weak self] events in
                    await self?.handleEvents(events, url: jsonlURL)
                }
            } catch {
                tailers.removeValue(forKey: session.jsonlURL)
                sessionIDByURL.removeValue(forKey: session.jsonlURL)
            }
        }

        if let handler = discoveryHandler {
            await handler(discovered)
        }
        return discovered
    }

    private func handleEvents(_ events: [TranscriptEvent], url: URL) async {
        let fallbackID = sessionIDByURL[url] ?? url.deletingPathExtension().lastPathComponent
        var metrics = metricsByURL[url] ?? SessionMetrics.empty(sessionID: fallbackID)
        for event in events {
            metrics.fold(event)
        }
        metricsByURL[url] = metrics
        if let handler = metricsHandler {
            await handler(metrics)
        }
    }

    private func enumerateRecent() -> [DiscoveredSession] {
        guard fileManager.fileExists(atPath: projectsDirectory.path) else { return [] }
        let cutoff = Date().addingTimeInterval(-recencyWindow)

        let projectDirs: [URL]
        do {
            projectDirs = try fileManager.contentsOfDirectory(
                at: projectsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return []
        }

        let liveProcesses = liveProcessProvider()
        let liveBySlug = Dictionary(
            liveProcesses.map { process in
                (LiveClaudeProcessSnapshotter.encodeProjectDirectory(from: process.cwd), process)
            },
            uniquingKeysWith: { first, _ in first }
        )

        var results: [DiscoveredSession] = []
        for projectDir in projectDirs {
            let slug = projectDir.lastPathComponent
            let live = liveBySlug[slug]
            if requireLiveProcess, live == nil { continue }

            let files: [URL]
            do {
                files = try fileManager.contentsOfDirectory(
                    at: projectDir,
                    includingPropertiesForKeys: [.contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                continue
            }

            for file in files where file.pathExtension.lowercased() == "jsonl" {
                let values = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                guard let mtime = values?.contentModificationDate, mtime > cutoff else { continue }
                let sessionID = file.deletingPathExtension().lastPathComponent
                results.append(
                    DiscoveredSession(
                        jsonlURL: file,
                        sessionID: sessionID,
                        projectDirectory: slug,
                        lastActivity: mtime,
                        cwd: live?.cwd,
                        terminalPID: live?.terminalPID,
                        terminalBundleID: live?.terminalBundleID,
                        isLive: live != nil
                    )
                )
            }
        }
        results.sort { $0.lastActivity > $1.lastActivity }
        return results
    }
}
