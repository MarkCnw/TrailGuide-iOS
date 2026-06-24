import Foundation

// 🟢 โครงสร้างข้อมูลนี้อยู่ในชั้น Domain เพราะเป็น Business Entity ที่ใช้ร่วมกันทั้งระบบ
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
