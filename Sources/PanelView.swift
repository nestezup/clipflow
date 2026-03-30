import SwiftUI

struct PanelView: View {
    @ObservedObject var appState: AppState

    private var theme: AppTheme { appState.theme }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "clipboard.fill")
                    .foregroundStyle(theme.accent)
                Text("ClipFlow")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                Spacer()

                // 테마 순환 버튼
                Button {
                    let all = AppTheme.allCases
                    let idx = all.firstIndex(of: appState.theme) ?? 0
                    appState.theme = all[(idx + 1) % all.count]
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "paintbrush.fill")
                            .font(.caption2)
                        Text(theme.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.rowBackground))
                }
                .buttonStyle(.plain)

                Text("ESC")
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.rowBackground))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Rectangle().fill(theme.divider).frame(height: 1)

            if appState.clipHistory.isEmpty {
                Spacer()
                Text("텍스트 복사 또는 스크린샷을 찍어보세요")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(appState.visibleItems.enumerated()), id: \.element.id) { index, item in
                            ClipItemRow(item: item, number: index + 1, theme: theme)
                        }
                    }
                    .padding(8)
                }

                if appState.clipHistory.count > 9 {
                    Rectangle().fill(theme.divider).frame(height: 1)
                    Text("+ \(appState.clipHistory.count - 9)개 이전 항목")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                        .padding(6)
                }
            }
        }
        .frame(width: 320, height: 420)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.divider, lineWidth: 1))
    }
}

struct ClipItemRow: View {
    let item: ClipItem
    let number: Int
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 10) {
            Text("⌥\(number)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(theme.background)
                .frame(width: 28, height: 22)
                .background(Capsule().fill(theme.accent))

            contentView

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 68)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.rowBackground))
    }

    @ViewBuilder
    private var contentView: some View {
        switch item.content {
        case .text(let str):
            textContentView(str)

        case .image(_, let thumbnail, let size):
            imageContentView(thumbnail: thumbnail, size: size)

        case .richText:
            placeholderView("Rich Text (coming soon)")

        case .file(_, let name):
            placeholderView("File: \(name) (coming soon)")
        }
    }

    private func textContentView(_ str: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(str)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(2)
                .truncationMode(.tail)

            metaView
        }
    }

    private func imageContentView(thumbnail: NSImage, size: CGSize) -> some View {
        HStack(spacing: 8) {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text("IMAGE")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(theme.background)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.green))

                Text("\(Int(size.width))×\(Int(size.height))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)

                metaView
            }
        }
    }

    private func placeholderView(_ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            metaView
        }
    }

    private var metaView: some View {
        HStack(spacing: 4) {
            if let app = item.sourceApp {
                Text(app)
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            Text(item.timestamp.formatted(.dateTime.hour().minute().second()))
                .font(.caption2)
                .foregroundStyle(theme.textSecondary.opacity(0.6))
        }
    }
}
