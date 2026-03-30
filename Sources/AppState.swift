import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.clipflow", category: "AppState")

// MARK: - Theme

enum AppTheme: String, CaseIterable {
    case dark, light, ocean, graphite, rose

    var displayName: String {
        switch self {
        case .dark:     "Dark"
        case .light:    "Light"
        case .ocean:    "Ocean"
        case .graphite: "Graphite"
        case .rose:     "Rose"
        }
    }

    var background: Color {
        switch self {
        case .dark:     .black
        case .light:    .white
        case .ocean:    Color(red: 0.05, green: 0.10, blue: 0.20)
        case .graphite: Color(red: 0.15, green: 0.15, blue: 0.17)
        case .rose:     Color(red: 0.15, green: 0.05, blue: 0.10)
        }
    }

    var textPrimary: Color {
        switch self {
        case .light:    .black
        default:        .white
        }
    }

    var textSecondary: Color {
        switch self {
        case .light:    Color(white: 0.35)
        default:        Color(white: 0.65)
        }
    }

    var accent: Color {
        switch self {
        case .dark:     .blue
        case .light:    .blue
        case .ocean:    Color(red: 0.30, green: 0.60, blue: 1.0)
        case .graphite: Color(white: 0.70)
        case .rose:     Color(red: 1.0, green: 0.40, blue: 0.60)
        }
    }

    var rowBackground: Color {
        switch self {
        case .light:    Color.black.opacity(0.05)
        default:        Color.white.opacity(0.08)
        }
    }

    var divider: Color {
        switch self {
        case .light:    Color.black.opacity(0.12)
        default:        Color.white.opacity(0.12)
        }
    }
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {
    @Published var clipHistory: [ClipItem] = []
    @Published var isPanelVisible = false
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "clipflow.theme") }
    }

    let maxHistory = 30

    /// 패널에 보이는 항목 (최근 9개, 시간순 — 먼저 복사한 것이 ⌥1)
    var visibleItems: [ClipItem] {
        Array(clipHistory.suffix(9))
    }

    private var clipMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private var panelController: FloatingPanelController?
    private var isPasting = false
    private var pasteResetTask: Task<Void, Never>?

    init() {
        let saved = UserDefaults.standard.string(forKey: "clipflow.theme") ?? ""
        self.theme = AppTheme(rawValue: saved) ?? .dark

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
        clipHistory.removeAll { $0.content == item.content }
        clipHistory.append(item)
        if clipHistory.count > maxHistory {
            clipHistory.removeFirst()
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
        let visible = visibleItems
        guard index < visible.count else { return }
        let item = visible[index]

        pasteResetTask?.cancel()

        isPasting = true
        PasteHelper.paste(item.content)

        pasteResetTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                isPasting = false
            }
        }
    }

    func clearHistory() {
        clipHistory.removeAll()
    }
}
