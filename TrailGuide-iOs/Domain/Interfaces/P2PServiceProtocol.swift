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
    
    func startHosting()
    func stopHosting()
    func startBrowsing()
    func stopBrowsing()
    func invitePeer(_ peer: MCPeerID)
    func acceptInvitation()
    func declineInvitation()
    func broadcast(data: Data, mode: MCSessionSendDataMode)
    func disconnect()
    
    // 🟢 เพิ่มตัวนี้สำหรับเปลี่ยนชื่อ
    func updateUsername(_ name: String)
}
