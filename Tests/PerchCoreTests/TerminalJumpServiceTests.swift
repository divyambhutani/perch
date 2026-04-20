import Foundation
import Testing
@testable import Perch

struct TerminalJumpServiceTests {
    @Test
    func appleTerminalTriggersAppleScript() async throws {
        let script = Box<[String]>(value: [])
        let activations = Box<[pid_t]>(value: [])
        let opens = Box<[String]>(value: [])

        let service = TerminalJumpService(
            locator: StubLocator(resolved: ResolvedTerminal(pid: 999, bundle: .appleTerminal, bundleID: TerminalBundle.appleTerminal.rawValue)),
            script: CapturingScriptRunner(box: script),
            activator: CapturingActivator(activations: activations, opens: opens)
        )

        let outcome = await service.jump(to: Self.snapshot(pid: 999, bundle: .appleTerminal))

        #expect(outcome == .appleScriptDispatched(.appleTerminal))
        #expect(script.value.count == 1)
        #expect(script.value[0].contains("Terminal"))
    }

    @Test
    func ghosttyActivatesRunningApp() async throws {
        let script = Box<[String]>(value: [])
        let activations = Box<[pid_t]>(value: [])
        let opens = Box<[String]>(value: [])

        let service = TerminalJumpService(
            locator: StubLocator(resolved: ResolvedTerminal(pid: 42, bundle: .ghostty, bundleID: TerminalBundle.ghostty.rawValue)),
            script: CapturingScriptRunner(box: script),
            activator: CapturingActivator(activations: activations, opens: opens)
        )

        let outcome = await service.jump(to: Self.snapshot(pid: 42, bundle: .ghostty))

        #expect(outcome == .activated(.ghostty))
        #expect(activations.value == [42])
        #expect(script.value.isEmpty)
    }

    @Test
    func unknownEmulatorFallsBackToOpeningCWD() async throws {
        let script = Box<[String]>(value: [])
        let activations = Box<[pid_t]>(value: [])
        let opens = Box<[String]>(value: [])

        let service = TerminalJumpService(
            locator: StubLocator(resolved: nil),
            script: CapturingScriptRunner(box: script),
            activator: CapturingActivator(activations: activations, opens: opens)
        )

        var snapshot = SessionSnapshot.placeholder()
        snapshot.cwd = "/tmp/project"
        snapshot.terminalBundleID = "com.example.unknown"

        let outcome = await service.jump(to: snapshot)

        #expect(outcome == .fallbackOpenedWorkingDirectory("/tmp/project"))
        #expect(opens.value == ["com.example.unknown"])
    }

    @Test
    func whenNothingResolvesReturnsNotLocated() async throws {
        let service = TerminalJumpService(
            locator: StubLocator(resolved: nil),
            script: CapturingScriptRunner(box: Box(value: [])),
            activator: CapturingActivator(activations: Box(value: []), opens: Box(value: []))
        )
        let outcome = await service.jump(to: SessionSnapshot.placeholder())
        #expect(outcome == .notLocated)
    }

    private static func snapshot(pid: pid_t, bundle: TerminalBundle) -> SessionSnapshot {
        var s = SessionSnapshot.placeholder()
        s.terminalPID = pid
        s.terminalBundleID = bundle.rawValue
        return s
    }
}

private final class Box<V>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: V
    init(value: V) { _value = value }
    var value: V {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
    func mutate(_ transform: (inout V) -> Void) {
        lock.withLock { transform(&_value) }
    }
}

private struct StubLocator: ProcessLocating {
    let resolved: ResolvedTerminal?
    func resolve(for snapshot: SessionSnapshot) -> ResolvedTerminal? { resolved }
}

private struct CapturingScriptRunner: AppleScriptRunning {
    let box: Box<[String]>
    func run(_ script: String) throws {
        box.mutate { $0.append(script) }
    }
}

private struct CapturingActivator: AppActivating {
    let activations: Box<[pid_t]>
    let opens: Box<[String]>

    func activate(pid: pid_t) {
        activations.mutate { $0.append(pid) }
    }

    func openApplication(at bundleID: String, cwd: String?) {
        opens.mutate { $0.append(bundleID) }
    }
}
