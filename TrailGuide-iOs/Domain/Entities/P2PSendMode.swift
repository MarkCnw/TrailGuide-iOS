import Foundation

/// โหมดการส่งข้อมูล P2P — Domain ใช้แทน MCSessionSendDataMode โดยไม่ต้อง import MultipeerConnectivity
enum P2PSendMode {
    case reliable    // ส่งแบบรับประกันว่าจะถึง (สำหรับข้อมูลสำคัญ เช่น SOS)
    case unreliable  // ส่งแบบเร็วแต่อาจหลุด (สำหรับอัปเดตตำแหน่งบ่อยๆ)
}
