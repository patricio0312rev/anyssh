#if canImport(UIKit)
import AnySSHCore
import AnySSHMocks
import TerminalEmulator
import Testing
import UIKit

@testable import AnySSHUI

@Suite struct SurfaceStoreSurvivalTests {
    @Test func theSurfaceOutlivesTheHostThatBorrowedIt() async throws {
        let store = Self.store()
        let id = SessionID(rawValue: "session-1")
        let surface = store.open(id, on: Self.connection())

        try await Self.feed(surface, text: "hello from the host\r\n")

        let first = Self.window(hosting: surface)
        let bytesBefore = surface.bytesReceived
        let screenBefore = surface.engine.describeScreen()

        let second = Self.window(hosting: surface)

        #expect(first.rootViewController !== second.rootViewController)
        #expect(store.surface(for: id) === surface)
        #expect(surface.sessionID == id)
        #expect(surface.view.superview === second.rootViewController?.view)
        #expect(bytesBefore > 0)
        #expect(surface.bytesReceived == bytesBefore)
        #expect(surface.engine.describeScreen() == screenBefore)
        #expect(surface.isDraining)
    }

    @Test func bytesKeepArrivingThroughTheRehost() async throws {
        let store = Self.store()
        let id = SessionID(rawValue: "session-1")
        let surface = store.open(id, on: Self.connection())

        try await Self.feed(surface, text: "before the navigation\r\n")
        let bytesBefore = surface.bytesReceived
        _ = Self.window(hosting: surface)
        _ = Self.window(hosting: surface)
        try await Self.feed(surface, text: "after the navigation\r\n")

        #expect(surface.bytesReceived > bytesBefore)
        #expect(surface.engine.describeScreen().contains("before the navigation"))
        #expect(surface.engine.describeScreen().contains("after the navigation"))
    }

    private static func store() -> TerminalSurfaceStore {
        TerminalSurfaceStore { size in SwiftTermEngine(size: size, renderer: .coreText) }
    }

    private static func connection() -> MockRemoteConnection {
        MockRemoteConnection(connectionID: ConnectionID(rawValue: "workstation.1"))
    }

    private static func feed(_ surface: TerminalSurface, text: String) async throws {
        let pump = surface.pump
        let bytes = Array(text.utf8)
        let target = await pump.metrics.deliveredBytes + bytes.count

        await Task.detached { await pump.ingest(bytes[...]) }.value
        for _ in 0..<1000 where await pump.metrics.deliveredBytes < target {
            try await Task.sleep(for: .milliseconds(1))
        }
        #expect(await pump.metrics.deliveredBytes == target)
    }

    private static func window(hosting surface: TerminalSurface) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = TerminalHostController(engine: surface.engine)
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }
}
#endif
