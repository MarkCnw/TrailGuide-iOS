import Foundation
import MultipeerConnectivity
import Combine

protocol P2PServiceProtocol {
    var myPeerId: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    var availablePeersPublisher: AnyPublisher<[MCPeerID], Never> { get }
    var lastConnectionErrorPublisher: AnyPublisher<MCPeerID?, Never> { get }
    
    var connectedPeersPublisher: AnyPublisher<[MCPeerID], Never> { get }
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }
    
    var onDataReceived: ((Data, MCPeerID) -> Void)? { get set }
    
    /// ชื่อเพื่อนที่เคยเชื่อมต่อแล้ว — ใช้ auto-accept เมื่อ reconnect
    var knownPeerNames: Set<String> { get set }
    
    /// สถานะว่ากำลังพยายามเชื่อมต่อใหม่หรือไม่
    var isReconnecting: Bool { get set }
    var isReconnectingPublisher: AnyPublisher<Bool, Never> { get }
    
    func startHosting()
    func stopHosting()
    func startBrowsing()
    func stopBrowsing()
    func invitePeer(_ peer: MCPeerID)
    func acceptInvitation()
    func declineInvitation()
    func broadcast(data: Data, mode: MCSessionSendDataMode)
    func disconnect()
    
    // 🟢 สำหรับเคลียร์ Session ผีสิง (Ghost Session) ตอน Join พลาด
    func resetSessionForRetry()
    
    // 🟢 เพิ่มตัวนี้สำหรับเปลี่ยนชื่อ
    func updateUsername(_ name: String)
}
