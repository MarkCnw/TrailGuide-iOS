import Foundation

// 🟢 เพิ่มคำว่า Sendable เข้าไปที่ Enum และ Struct
enum PayloadType: String, Codable, Sendable {
    case startAdventure
    case locationUpdate
    case profileImage
    case endAdventure
    case sos
}

struct P2PPayload: Codable, Sendable {
    let type: PayloadType
    let senderName: String
    let lat: Double?
    let lng: Double?
    let heading: Double?
    let imageData: Data?
}
