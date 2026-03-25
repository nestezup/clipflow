import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clipboard.fill")
                    .foregroundStyle(.blue)
                Text("ClipFlow")
                    .font(.caption)
                    .bold()
                Spacer()
                Text("\(appState.clipHistory.count)개")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Button("패널 열기 (⌥V)") {
                appState.showPanel()
            }

            if !appState.clipHistory.isEmpty {
                Divider()

                ForEach(Array(appState.clipHistory.prefix(5).enumerated()), id: \.element.id) { index, item in
                    Button {
                        appState.pasteItem(at: index)
                    } label: {
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption.monospaced())
                            Text(String(item.content.prefix(40)) + (item.content.count > 40 ? "..." : ""))
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }

                Divider()

                Button("히스토리 지우기") {
                    appState.clearHistory()
                }
            }

            Divider()

            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 260)
    }
}
