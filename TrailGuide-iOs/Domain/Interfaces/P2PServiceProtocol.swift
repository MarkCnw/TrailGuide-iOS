import Foundation
import Combine

/// Protocol สำหรับบริการ P2P — Domain ไม่จำเป็นต้องรู้จัก MultipeerConnectivity
/// ใช้ String แทน MCPeerID เพื่อให้ Domain Layer บริสุทธิ์
protocol P2PServiceProtocol {
    var myPeerName: String { get }
    var connectedPeerNames: [String] { get }
    var availablePeersPublisher: AnyPublisher<[String], Never> { get }
    var lastConnectionErrorPublisher: AnyPublisher<String?, Never> { get }
    
    var connectedPeersPublisher: AnyPublisher<[String], Never> { get }
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }
    
    var onDataReceived: ((Data, String) -> Void)? { get set }
    
    /// ชื่อเพื่อนที่เคยเชื่อมต่อแล้ว — ใช้ auto-accept เมื่อ reconnect
    var knownPeerNames: Set<String> { get set }
    
    /// สถานะว่ากำลังพยายามเชื่อมต่อใหม่หรือไม่
    var isReconnecting: Bool { get set }
    var isReconnectingPublisher: AnyPublisher<Bool, Never> { get }
    
    func startHosting()
    func stopHosting()
    func startBrowsing()
    func stopBrowsing()
    func invitePeer(_ peerName: String)
    func acceptInvitation()
    func declineInvitation()
    func broadcast(data: Data, mode: P2PSendMode)
    func disconnect()
    
    // 🟢 สำหรับเคลียร์ Session ผีสิง (Ghost Session) ตอน Join พลาด
    func resetSessionForRetry()
    
    // 🟢 เพิ่มตัวนี้สำหรับเปลี่ยนชื่อ
    func updateUsername(_ name: String)
}
