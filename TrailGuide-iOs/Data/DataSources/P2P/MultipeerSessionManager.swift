import Foundation
import MultipeerConnectivity
import Combine

class MultipeerSessionManager: NSObject, ObservableObject {
    private let serviceType = "trailguide-p2p"
    
    // 🟢 เปลี่ยนจาก let เป็น private(set) var เพื่อให้เปลี่ยนชื่อได้
    private(set) var mcPeerId: MCPeerID
    private(set) var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    @Published var connectedMCPeers: [MCPeerID] = []
    
    @Published var availableMCPeers: [MCPeerID] = []
    @Published var lastConnectionErrorMC: MCPeerID? = nil
    
    // 🟢 Auto Reconnect state
    var knownPeerNames: Set<String> = []
    @Published var isReconnecting: Bool = false
    
    private var browseRetryTimer: Timer?
    private var isCurrentlyBrowsing: Bool = false
    private var isCurrentlyHosting: Bool = false
    
    var onDataReceived: ((Data, String) -> Void)?
    
    // 🟢 Mapping MCPeerID <-> String สำหรับการแปลงระหว่าง Domain และ Data layer
    private var peerIdMap: [String: MCPeerID] = [:]
    
    init(username: String) {
        if let data = UserDefaults.standard.data(forKey: "saved_peer_id"),
           let savedPeerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           savedPeerID.displayName == username {
            self.mcPeerId = savedPeerID
        } else {
            let newPeerID = MCPeerID(displayName: username)
            self.mcPeerId = newPeerID
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newPeerID, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "saved_peer_id")
            }
        }
        
        super.init()
        self.session = MCSession(peer: self.mcPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
    }
    
    // MARK: - Internal helper: MCPeerID <-> String
    private func mcPeer(for name: String) -> MCPeerID? {
        return peerIdMap[name]
    }
    
    private func registerPeer(_ peer: MCPeerID) {
        peerIdMap[peer.displayName] = peer
    }
    
    // MARK: - Actions
    func startHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        advertiser = MCNearbyServiceAdvertiser(peer: mcPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isCurrentlyHosting = true
    }
    
    func stopHosting() {
        isCurrentlyHosting = false
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
    
    func startBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        browseRetryTimer?.invalidate()
        browseRetryTimer = nil
        
        DispatchQueue.main.async {
            self.availableMCPeers.removeAll()
            self.lastConnectionErrorMC = nil
        }
        
        browser = MCNearbyServiceBrowser(peer: mcPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isCurrentlyBrowsing = true
        
        browseRetryTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isCurrentlyBrowsing else { return }
            if self.availableMCPeers.isEmpty && self.connectedMCPeers.isEmpty {
                self.browser?.stopBrowsingForPeers()
                self.browser?.startBrowsingForPeers()
            }
        }
    }
    
    func stopBrowsing() {
        isCurrentlyBrowsing = false
        browseRetryTimer?.invalidate()
        browseRetryTimer = nil
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    func invitePeer(_ peerName: String) {
        guard let mcPeer = mcPeer(for: peerName) else { return }
        browser?.invitePeer(mcPeer, to: session, withContext: nil, timeout: 15)
    }
    
    func acceptInvitation() {}
    func declineInvitation() {}
    
    func broadcast(data: Data, mode: P2PSendMode) {
        let mcMode: MCSessionSendDataMode = (mode == .reliable) ? .reliable : .unreliable
        guard !session.connectedPeers.isEmpty else { return }
        do { try session.send(data, toPeers: session.connectedPeers, with: mcMode) }
        catch { print("❌ ส่งข้อมูลไม่สำเร็จ: \(error.localizedDescription)") }
    }
    
    func disconnect() {
        stopHosting()
        stopBrowsing()
        
        // 🟢 ไม่ disconnect session ถ้ากำลัง reconnect
        if !isReconnecting {
            session.disconnect()
            knownPeerNames.removeAll()
        }
        
        DispatchQueue.main.async {
            self.connectedMCPeers.removeAll()
            self.availableMCPeers.removeAll()
            self.lastConnectionErrorMC = nil
        }
        
        if !isReconnecting {
            self.session = MCSession(peer: self.mcPeerId, securityIdentity: nil, encryptionPreference: .none)
            self.session.delegate = self
        }
    }
    
    // 🟢 ล้าง Session ทิ้งกรณีการเชื่อมต่อค้างหรือถูกปฏิเสธ เพื่อสร้างท่อใหม่ที่สะอาด
    func resetSessionForRetry() {
        session.disconnect()
        DispatchQueue.main.async {
            self.lastConnectionErrorMC = nil
            self.connectedMCPeers.removeAll()
        }
        self.session = MCSession(peer: self.mcPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
    }
    
    // 🟢 ฟังก์ชันอัปเดตชื่อผู้ใช้
    func updateUsername(_ newName: String) {
        disconnect()
        let newPeerID = MCPeerID(displayName: newName)
        self.mcPeerId = newPeerID
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: newPeerID, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "saved_peer_id")
        }
        self.session = MCSession(peer: self.mcPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
        objectWillChange.send()
    }
}

extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        registerPeer(peerID)
        DispatchQueue.main.async {
            self.connectedMCPeers = session.connectedPeers
            if state == .notConnected { self.lastConnectionErrorMC = peerID }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        registerPeer(peerID)
        onDataReceived?(data, peerID.displayName)
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        registerPeer(peerID)
        // 🟢 Auto-accept all peers (เข้าร่วมอัตโนมัติ 100%)
        invitationHandler(true, session)
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isCurrentlyHosting else { return }
            self.advertiser?.stopAdvertisingPeer()
            self.advertiser?.startAdvertisingPeer()
        }
    }
}

extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard peerID != self.mcPeerId else { return }
        registerPeer(peerID)
        DispatchQueue.main.async {
            if !self.availableMCPeers.contains(peerID) { self.availableMCPeers.append(peerID) }
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.availableMCPeers.removeAll(where: { $0 == peerID }) }
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isCurrentlyBrowsing else { return }
            self.browser?.stopBrowsingForPeers()
            self.browser?.startBrowsingForPeers()
        }
    }
}

// MARK: - P2PServiceProtocol Conformance (String-based API for Domain)
extension MultipeerSessionManager: P2PServiceProtocol {
    var myPeerName: String { mcPeerId.displayName }
    var connectedPeerNames: [String] { connectedMCPeers.map { $0.displayName } }
    var availablePeersPublisher: AnyPublisher<[String], Never> { $availableMCPeers.map { $0.map { $0.displayName } }.eraseToAnyPublisher() }
    var lastConnectionErrorPublisher: AnyPublisher<String?, Never> { $lastConnectionErrorMC.map { $0?.displayName }.eraseToAnyPublisher() }
    var connectedPeersPublisher: AnyPublisher<[String], Never> { $connectedMCPeers.map { $0.map { $0.displayName } }.eraseToAnyPublisher() }
    var isReconnectingPublisher: AnyPublisher<Bool, Never> { $isReconnecting.eraseToAnyPublisher() }
    var objectWillChangePublisher: AnyPublisher<Void, Never> { objectWillChange.map { _ in () }.eraseToAnyPublisher() }
}
