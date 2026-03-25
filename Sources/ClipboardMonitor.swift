import AppKit

final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let onChange: (ClipItem) -> Void

    init(onChange: @escaping (ClipItem) -> Void) {
        self.onChange = onChange
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let string = pasteboard.string(forType: .string),
              !string.isEmpty else { return }

        let frontApp = NSWorkspace.shared.frontmostApplication
        let item = ClipItem(
            content: string,
            timestamp: Date(),
            sourceApp: frontApp?.localizedName
        )
        onChange(item)
    }
}
