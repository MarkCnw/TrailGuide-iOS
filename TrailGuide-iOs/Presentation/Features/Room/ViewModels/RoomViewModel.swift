import Foundation
import MultipeerConnectivity
import Combine

class RoomViewModel: ObservableObject {
    // 🟢 ดึง Manager ที่เราทำไว้มาใช้งาน
    @Published var sessionManager: MultipeerSessionManager
    private var userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        
        // ดึงชื่อผู้ใช้จากฐานข้อมูลมาตั้งเป็นชื่อเครื่อง (Peer ID)
        // ถ้าดึงไม่ได้ ให้ใช้ชื่อ "นักเดินทาง" เป็นค่าเริ่มต้น
        let name = UserDefaults.standard.string(forKey: "current_username") ?? "นักเดินทาง"
        self.sessionManager = MultipeerSessionManager(username: name)
    }
    
    // --- คำสั่งสำหรับฝั่ง Host ---
    func startHosting() {
        sessionManager.startHosting()
    }
    
    func stopHosting() {
        sessionManager.stopHosting()
    }
    
    // --- คำสั่งสำหรับฝั่ง Member ---
    func startBrowsing() {
        sessionManager.startBrowsing()
    }
    
    func stopBrowsing() {
        sessionManager.stopBrowsing()
    }
    
    func join(peer: MCPeerID) {
        sessionManager.invitePeer(peer)
    }
    
    func leaveRoom() {
        sessionManager.disconnect()
    }
}
