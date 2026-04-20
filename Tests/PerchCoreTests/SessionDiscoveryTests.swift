import Foundation
import Testing
@testable import Perch

struct SessionDiscoveryTests {
    @Test
    func refreshReturnsOnlyRecentJsonl() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        let recent = try scratch.writeJsonl(
            project: "proj-a",
            name: "\(UUID().uuidString).jsonl",
            contents: "{}\n",
            modificationDate: .now
        )
        _ = try scratch.writeJsonl(
            project: "proj-b",
            name: "\(UUID().uuidString).jsonl",
            contents: "{}\n",
            modificationDate: Date(timeIntervalSinceNow: -1_200)
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] },
            requireLiveProcess: false
        )

        let results = await discovery.refresh()

        #expect(results.count == 1)
        #expect(results.first?.jsonlURL.resolvingSymlinksInPath() == recent.resolvingSymlinksInPath())
        #expect(results.first?.projectDirectory == "proj-a")
    }

    @Test
    func refreshDiscoversMultipleRecentSessions() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        _ = try scratch.writeJsonl(
            project: "proj-a",
            name: "aaa.jsonl",
            contents: "{}\n",
            modificationDate: Date(timeIntervalSinceNow: -30)
        )
        _ = try scratch.writeJsonl(
            project: "proj-b",
            name: "bbb.jsonl",
            contents: "{}\n",
            modificationDate: .now
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] },
            requireLiveProcess: false
        )

        let results = await discovery.refresh()

        #expect(results.count == 2)
        #expect(results.map(\.sessionID).sorted() == ["aaa", "bbb"])
        // Sorted by lastActivity desc -> proj-b first.
        #expect(results.first?.sessionID == "bbb")
    }

    @Test
    func refreshSurfacesAllJsonlsInSameProject() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        _ = try scratch.writeJsonl(
            project: "proj",
            name: "older.jsonl",
            contents: "{}\n",
            modificationDate: Date(timeIntervalSinceNow: -120)
        )
        _ = try scratch.writeJsonl(
            project: "proj",
            name: "newer.jsonl",
            contents: "{}\n",
            modificationDate: .now
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] },
            requireLiveProcess: false
        )

        let results = await discovery.refresh()
        #expect(results.count == 2)
        #expect(Set(results.map(\.sessionID)) == ["older", "newer"])
        #expect(results.first?.sessionID == "newer")
    }

    @Test
    func defaultsToRequireLiveProcessFalse() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        _ = try scratch.writeJsonl(
            project: "proj",
            name: "x.jsonl",
            contents: "{}\n",
            modificationDate: .now
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] }
        )

        let results = await discovery.refresh()
        #expect(results.count == 1)
        #expect(results.first?.isLive == false)
    }

    @Test
    func refreshIgnoresNonJsonlFiles() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        _ = try scratch.writeJsonl(
            project: "proj",
            name: "notes.txt",
            contents: "hello",
            modificationDate: .now
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] },
            requireLiveProcess: false
        )

        let results = await discovery.refresh()
        #expect(results.isEmpty)
    }

    @Test
    func startInvokesDiscoveryHandler() async throws {
        let scratch = try Scratch.make()
        defer { scratch.cleanup() }

        _ = try scratch.writeJsonl(
            project: "proj",
            name: "live.jsonl",
            contents: "{}\n",
            modificationDate: .now
        )

        let discovery = SessionDiscovery(
            projectsDirectory: scratch.projectsDirectory,
            recencyWindow: 600,
            refreshInterval: .seconds(60),
            liveProcessProvider: { [] },
            requireLiveProcess: false
        )

        let captured: Captured<[DiscoveredSession]> = Captured()
        await discovery.start(
            onDiscovery: { sessions in await captured.set(sessions) },
            onMetrics: { _ in }
        )

        let observed = await captured.waitForValue(timeout: .seconds(2))
        await discovery.stop()

        #expect(observed?.count == 1)
        #expect(observed?.first?.sessionID == "live")
    }
}

private struct Scratch {
    let root: URL
    let projectsDirectory: URL

    static func make() throws -> Scratch {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("perch-session-discovery-\(UUID().uuidString)", isDirectory: true)
        let projects = root.appendingPathComponent("projects", isDirectory: true)
        try FileManager.default.createDirectory(at: projects, withIntermediateDirectories: true)
        return Scratch(root: root, projectsDirectory: projects)
    }

    func writeJsonl(project: String, name: String, contents: String, modificationDate: Date) throws -> URL {
        let projectDir = projectsDirectory.appendingPathComponent(project, isDirectory: true)
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        let fileURL = projectDir.appendingPathComponent(name)
        try contents.data(using: .utf8)?.write(to: fileURL)
        try FileManager.default.setAttributes(
            [.modificationDate: modificationDate],
            ofItemAtPath: fileURL.path
        )
        return fileURL
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: root)
    }
}

private actor Captured<Value: Sendable> {
    private var value: Value?

    func set(_ value: Value) { self.value = value }

    func waitForValue(timeout: Duration) async -> Value? {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if let v = value { return v }
            try? await Task.sleep(for: .milliseconds(25))
        }
        return value
    }
}
