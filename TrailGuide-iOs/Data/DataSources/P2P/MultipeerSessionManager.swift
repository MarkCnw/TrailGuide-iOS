import Foundation
import MultipeerConnectivity
import Combine

class MultipeerSessionManager: NSObject, ObservableObject {
    private let serviceType = "trailguide-p2p"
    
    // 🟢 เปลี่ยนจาก let เป็น private(set) var เพื่อให้เปลี่ยนชื่อได้
    private(set) var myPeerId: MCPeerID
    private(set) var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    
    @Published var availablePeers: [MCPeerID] = []
    @Published var lastConnectionError: MCPeerID? = nil
    
    // 🟢 Auto Reconnect state
    var knownPeerNames: Set<String> = []
    @Published var isReconnecting: Bool = false
    
    private var browseRetryTimer: Timer?
    private var isCurrentlyBrowsing: Bool = false
    private var isCurrentlyHosting: Bool = false
    
    var onDataReceived: ((Data, MCPeerID) -> Void)?
    
    init(username: String) {
        if let data = UserDefaults.standard.data(forKey: "saved_peer_id"),
           let savedPeerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           savedPeerID.displayName == username {
            self.myPeerId = savedPeerID
        } else {
            let newPeerID = MCPeerID(displayName: username)
            self.myPeerId = newPeerID
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newPeerID, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "saved_peer_id")
            }
        }
        
        super.init()
        self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
    }
    
    // MARK: - Actions
    func startHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
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
            self.availablePeers.removeAll()
            self.lastConnectionError = nil
        }
        
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isCurrentlyBrowsing = true
        
        browseRetryTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isCurrentlyBrowsing else { return }
            if self.availablePeers.isEmpty && self.connectedPeers.isEmpty {
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
    
    func invitePeer(_ peer: MCPeerID) {
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 15) // 🟢 ลด timeout เหลือ 15 วินาที
    }
    
    func acceptInvitation() {}
    func declineInvitation() {}
    
    func broadcast(data: Data, mode: MCSessionSendDataMode = .reliable) {
        guard !session.connectedPeers.isEmpty else { return }
        do { try session.send(data, toPeers: session.connectedPeers, with: mode) }
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
            self.connectedPeers.removeAll()
            self.availablePeers.removeAll()
            self.lastConnectionError = nil
        }
        
        if !isReconnecting {
            self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
            self.session.delegate = self
        }
    }
    
    // 🟢 ล้าง Session ทิ้งกรณีการเชื่อมต่อค้างหรือถูกปฏิเสธ เพื่อสร้างท่อใหม่ที่สะอาด
    func resetSessionForRetry() {
        session.disconnect()
        DispatchQueue.main.async {
            self.lastConnectionError = nil
            self.connectedPeers.removeAll()
        }
        self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
    }
    
    // 🟢 ฟังก์ชันอัปเดตชื่อผู้ใช้
    func updateUsername(_ newName: String) {
        disconnect()
        let newPeerID = MCPeerID(displayName: newName)
        self.myPeerId = newPeerID
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: newPeerID, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "saved_peer_id")
        }
        self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self
        objectWillChange.send()
    }
}

extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            if state == .notConnected { self.lastConnectionError = peerID }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { onDataReceived?(data, peerID) }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
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
        guard peerID != self.myPeerId else { return }
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) { self.availablePeers.append(peerID) }
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.availablePeers.removeAll(where: { $0 == peerID }) }
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isCurrentlyBrowsing else { return }
            self.browser?.stopBrowsingForPeers()
            self.browser?.startBrowsingForPeers()
        }
    }
}

extension MultipeerSessionManager: P2PServiceProtocol {
    var availablePeersPublisher: AnyPublisher<[MCPeerID], Never> { $availablePeers.eraseToAnyPublisher() }
    var lastConnectionErrorPublisher: AnyPublisher<MCPeerID?, Never> { $lastConnectionError.eraseToAnyPublisher() }
    var connectedPeersPublisher: AnyPublisher<[MCPeerID], Never> { $connectedPeers.eraseToAnyPublisher() }
    var isReconnectingPublisher: AnyPublisher<Bool, Never> { $isReconnecting.eraseToAnyPublisher() }
    var objectWillChangePublisher: AnyPublisher<Void, Never> { objectWillChange.map { _ in () }.eraseToAnyPublisher() }
}
