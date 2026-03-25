import Foundation

struct ClipItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let sourceApp: String?

    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.content == rhs.content
    }
}
