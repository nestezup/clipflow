import SwiftUI
import AppKit

@MainActor
final class FloatingPanelController {
    private var window: NSPanel?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        guard let appState else { return }

        if let window {
            window.orderFront(nil)
            return
        }

        let view = PanelView(appState: appState)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 320, height: 420)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        // 화면 우측 중앙
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 340
            let y = screenFrame.midY - 210
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        window = panel
    }

    func hide() {
        window?.close()
        window = nil
    }
}
