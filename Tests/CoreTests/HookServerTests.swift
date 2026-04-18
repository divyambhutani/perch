import Foundation
import Testing
@testable import Perch

struct HookServerTests {
    @Test
    func parsesPermissionEventFromHTTPPayload() async throws {
        let data = Self.request(
            method: "POST",
            path: "/hooks",
            body: #"{"hook_event_name":"Notification","message":"Permission required.","diffPreview":"-old\n+new"}"#
        )
        let server = HookServer()
        let event = try await server.ingest(data: data)

        #expect(event.kind == .permissionRequired(summary: "Permission required.", diffPreview: "-old\n+new"))
    }

    @Test
    func incompleteFrameSurfacedAsError() async {
        let partial = Data("POST /hooks HTTP/1.1\r\nHost: localhost\r\n".utf8)
        let server = HookServer()
        await #expect(throws: HookServerError.incompleteRequest) {
            try await server.ingest(data: partial)
        }
    }

    @Test
    func respectsContentLengthAndIgnoresTrailingBytes() async throws {
        let body = #"{"hook_event_name":"SessionEnd","reason":"user quit"}"#
        let frame = "POST /hooks HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)  trailing-junk"
        let server = HookServer()
        let event = try await server.ingest(data: Data(frame.utf8))
        #expect(event.kind == .sessionEnded(reason: "user quit"))
    }

    @Test
    func rejectsInvalidContentLength() async {
        let frame = "POST /hooks HTTP/1.1\r\nContent-Length: -3\r\n\r\n{}"
        let server = HookServer()
        await #expect(throws: HookRequestParser.ParseError.invalidContentLength) {
            try await server.ingest(data: Data(frame.utf8))
        }
    }

    @Test
    func parserSurfacesPathAndMethodForRouting() throws {
        let parser = HookRequestParser()
        let frame = Self.request(method: "GET", path: "/ping", body: "")
        guard case .complete(let request, _) = try parser.parse(frame) else {
            Issue.record("expected complete parse")
            return
        }
        #expect(request.method == "GET")
        #expect(request.path == "/ping")
    }

    @Test
    func liveServerAcceptsPermissionOverTCP() async throws {
        let server = HookServer()
        let received = EventBox()
        let port = try await server.start(preferredPort: 0) { event in
            await received.set(event)
        }
        defer { Task { await server.stop() } }

        let body = #"{"hook_event_name":"Notification","message":"Permission required.","diffPreview":""}"#
        let status = try await Self.sendRequest(
            method: "POST",
            path: "/hooks",
            body: body,
            host: HookServerConfiguration.host,
            port: port
        )

        #expect(status == 202)
        try await Self.waitUntil(timeout: 1.0) { await received.value != nil }

        let event = await received.value
        #expect(event?.kind == .permissionRequired(summary: "Permission required.", diffPreview: ""))
    }

    @Test
    func liveServerRejectsOtherPaths() async throws {
        let server = HookServer()
        let port = try await server.start(preferredPort: 0) { _ in }
        defer { Task { await server.stop() } }

        let status = try await Self.sendRequest(
            method: "POST",
            path: "/not-hooks",
            body: "{}",
            host: HookServerConfiguration.host,
            port: port
        )
        #expect(status == 404)
    }

    @Test
    func liveServerRejectsNonPostMethods() async throws {
        let server = HookServer()
        let port = try await server.start(preferredPort: 0) { _ in }
        defer { Task { await server.stop() } }

        let status = try await Self.sendRequest(
            method: "GET",
            path: "/hooks",
            body: "",
            host: HookServerConfiguration.host,
            port: port
        )
        #expect(status == 405)
    }

    @Test
    func stopReleasesPortForReuse() async throws {
        let server1 = HookServer()
        let port = try await server1.start(preferredPort: 0) { _ in }
        await server1.stop()

        let server2 = HookServer()
        let rebound = try await server2.start(preferredPort: port) { _ in }
        await server2.stop()

        #expect(rebound == port)
    }
}

private extension HookServerTests {
    static func request(method: String, path: String, body: String) -> Data {
        let bytes = Array(body.utf8)
        let frame = "\(method) \(path) HTTP/1.1\r\nHost: localhost\r\nContent-Length: \(bytes.count)\r\n\r\n\(body)"
        return Data(frame.utf8)
    }

    static func sendRequest(method: String, path: String, body: String, host: String, port: UInt16) async throws -> Int {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let url = URL(string: "http://\(host):\(port)\(path)")!
            var request = URLRequest(url: url)
            request.httpMethod = method
            if !body.isEmpty {
                request.httpBody = Data(body.utf8)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            let session = URLSession(configuration: .ephemeral)
            session.dataTask(with: request) { _, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                continuation.resume(returning: status)
            }.resume()
        }
    }

    static func waitUntil(timeout: TimeInterval, _ predicate: @Sendable () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await predicate() { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        throw CancellationError()
    }
}

private actor EventBox {
    private(set) var value: HookEvent?

    func set(_ event: HookEvent) {
        value = event
    }
}
