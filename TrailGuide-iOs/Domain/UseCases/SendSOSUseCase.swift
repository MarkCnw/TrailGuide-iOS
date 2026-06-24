import Foundation

class SendSOSUseCase {
    private let p2pService: P2PServiceProtocol
    
    init(p2pService: P2PServiceProtocol) {
        self.p2pService = p2pService
    }
    
    // 🟢 หน้าที่เดียวคือ จัดการ Payload และสั่งส่ง
    func execute(senderName: String) {
        let payload = P2PPayload(type: .sos, senderName: senderName, lat: nil, lng: nil, heading: nil, imageData: nil)
        if let data = try? JSONEncoder().encode(payload) {
            p2pService.broadcast(data: data, mode: .reliable)
        }
    }
}
