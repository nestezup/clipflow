import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var clipHistory: [ClipItem] = []
    @Published var isPanelVisible = false

    let maxHistory = 30

    private var clipMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private var panelController: FloatingPanelController?
    private var isPasting = false

    init() {
        panelController = FloatingPanelController(appState: self)

        clipMonitor = ClipboardMonitor { [weak self] item in
            Task { @MainActor in
                self?.addItem(item)
            }
        }
        clipMonitor?.start()

        hotkeyManager = HotkeyManager(
            onTogglePanel: { [weak self] in
                Task { @MainActor in
                    self?.togglePanel()
                }
            },
            onItemSelect: { [weak self] index in
                Task { @MainActor in
                    self?.pasteItem(at: index)
                }
            },
            onDismiss: { [weak self] in
                Task { @MainActor in
                    self?.hidePanel()
                }
            }
        )
        hotkeyManager?.registerToggle()
    }

    func addItem(_ item: ClipItem) {
        guard !isPasting else { return }
        // 중복 제거
        clipHistory.removeAll { $0.content == item.content }
        clipHistory.insert(item, at: 0)
        if clipHistory.count > maxHistory {
            clipHistory.removeLast()
        }
    }

    func togglePanel() {
        if isPanelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        guard !clipHistory.isEmpty else { return }
        isPanelVisible = true
        panelController?.show()
        hotkeyManager?.registerItemKeys()
    }

    func hidePanel() {
        isPanelVisible = false
        panelController?.hide()
        hotkeyManager?.unregisterItemKeys()
    }

    func pasteItem(at index: Int) {
        guard index < clipHistory.count else { return }
        let item = clipHistory[index]

        isPasting = true
        PasteHelper.paste(item.content)

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            isPasting = false
        }
    }

    func clearHistory() {
        clipHistory.removeAll()
    }
}
