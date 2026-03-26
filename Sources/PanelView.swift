import SwiftUI

struct PanelView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clipboard.fill")
                    .foregroundStyle(.blue)
                Text("ClipFlow")
                    .font(.headline)
                Spacer()
                Text("ESC 닫기")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if appState.clipHistory.isEmpty {
                Spacer()
                Text("텍스트 복사 또는 스크린샷을 찍어보세요")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(appState.clipHistory.prefix(9).enumerated()), id: \.element.id) { index, item in
                            ClipItemRow(item: item, number: index + 1)
                        }
                    }
                    .padding(8)
                }

                if appState.clipHistory.count > 9 {
                    Divider()
                    Text("+ \(appState.clipHistory.count - 9)개 더")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(6)
                }
            }
        }
        .frame(width: 320, height: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ClipItemRow: View {
    let item: ClipItem
    let number: Int

    var body: some View {
        HStack(spacing: 10) {
            // 번호 배지
            Text("⌥\(number)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 22)
                .background(Capsule().fill(.blue))

            // 콘텐츠
            contentView

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 68)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
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
                .lineLimit(2)
                .truncationMode(.tail)

            metaView
        }
    }

    private func imageContentView(thumbnail: NSImage, size: CGSize) -> some View {
        HStack(spacing: 8) {
            // 48x48 썸네일 (aspect-fill, center crop)
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                // IMAGE 타입 배지 (green, 구분용)
                Text("IMAGE")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.green))

                Text("\(Int(size.width))×\(Int(size.height))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)

                metaView
            }
        }
    }

    private func placeholderView(_ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            metaView
        }
    }

    private var metaView: some View {
        HStack(spacing: 4) {
            if let app = item.sourceApp {
                Text(app)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(item.timestamp.formatted(.dateTime.hour().minute().second()))
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
    }
}
