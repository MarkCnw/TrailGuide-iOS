import Foundation
import CoreLocation
import UIKit
import MultipeerConnectivity

// 🟢 Entity ตัวนี้จะทำหน้าที่เป็น "ตัวแทน" ของเพื่อนแต่ละคนในห้อง
struct TrailMember: Identifiable {
    let id: MCPeerID // ใช้ MCPeerID เป็น ID หลักชั่วคราวเพื่อให้ผูกกับ P2P ได้ง่าย
    var name: String { id.displayName }
    
    var location: CLLocationCoordinate2D?
    var heading: Double?
    var lastSeen: Date?
    var profileImage: UIImage?
    
    // คืนค่าสถานะว่าสัญญาณหายหรือไม่ (สมมติว่าถ้าไม่เห็นเกิน 30 วินาที = ขาดการติดต่อ)
    var isSignalLost: Bool {
        guard let lastSeen = lastSeen else { return true }
        return Date().timeIntervalSince(lastSeen) > 30
    }
}
