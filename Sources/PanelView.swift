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
                Text("클립보드 히스토리가 비어있습니다")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                // Clip list
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
            Text("\(number)")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(.blue))

            // 내용 미리보기
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.tail)

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

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
    }
}
