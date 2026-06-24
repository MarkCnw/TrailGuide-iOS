import Foundation
import CoreLocation

// 🟢 Entity ตัวนี้จะทำหน้าที่เป็น "ตัวแทน" ของเพื่อนแต่ละคนในห้อง
// ใช้ String เป็น ID แทน MCPeerID และ Data แทน UIImage เพื่อให้ Domain บริสุทธิ์
struct TrailMember: Identifiable {
    let id: String // ใช้ชื่อ peer name เป็น ID
    var name: String { id }
    
    var location: CLLocationCoordinate2D?
    var heading: Double?
    var lastSeen: Date?
    var profileImageData: Data? // ใช้ Data แทน UIImage เพื่อไม่ต้อง import UIKit
    
    // คืนค่าสถานะว่าสัญญาณหายหรือไม่ (สมมติว่าถ้าไม่เห็นเกิน 30 วินาที = ขาดการติดต่อ)
    var isSignalLost: Bool {
        guard let lastSeen = lastSeen else { return true }
        return Date().timeIntervalSince(lastSeen) > 30
    }
}
