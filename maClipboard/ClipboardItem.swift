import Foundation

enum ClipboardData: Codable, Hashable {
    case text(String)
    case image(Data)
}

struct ClipboardItem: Codable, Hashable {
    let data: ClipboardData
    let date: Date
}
//just added a comment
