import Foundation
import MultipeerConnectivity
import Combine

class MultipeerSessionManager: NSObject, ObservableObject {
    // 🚨 สำคัญ: ชื่อนี้ต้องตรงกับในไฟล์ Info.plist (ห้ามเกิน 15 ตัวอักษร)
    private let serviceType = "trailguide-p2p"
    
    let myPeerId: MCPeerID
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var pendingInvitation: (peer: MCPeerID, invitationHandler: (Bool, MCSession?) -> Void)?
    
    // 🟢 ตัวแปรสำหรับหน้า ScanView
    @Published var availablePeers: [MCPeerID] = []
    @Published var lastConnectionError: MCPeerID? = nil
    
    var onDataReceived: ((Data, MCPeerID) -> Void)?
    
    init(username: String) {
        // 🟢 ระบบปราบผี: บันทึกและดึง PeerID เดิมมาใช้ เพื่อป้องกันชื่อเบิ้ล
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
        self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
    }
    
    // MARK: - Actions
    func startHosting() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        // 🟢 ล้างข้อมูลเก่าทิ้งทุกครั้งที่เริ่มสแกนใหม่ เพื่อป้องกัน UI ค้าง
        DispatchQueue.main.async {
            self.availablePeers.removeAll()
            self.lastConnectionError = nil
        }
        
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
    }
    
    func invitePeer(_ peer: MCPeerID) {
        // 🟢 Timeout 30 วินาที ให้ Host มีเวลากดรับ
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }
    
    func acceptInvitation() {
        pendingInvitation?.invitationHandler(true, session)
        pendingInvitation = nil
    }
    
    func declineInvitation() {
        pendingInvitation?.invitationHandler(false, nil)
        pendingInvitation = nil
    }
    
    // 🟢 อัปเดตฟังก์ชัน broadcast ให้รองรับพารามิเตอร์ mode (ค่าเริ่มต้นคือ .reliable)
        func broadcast(data: Data, mode: MCSessionSendDataMode = .reliable) {
            guard !session.connectedPeers.isEmpty else { return }
            do {
                // 🌟 เปลี่ยนจาก .reliable ตรงๆ เป็นตัวแปร mode
                try session.send(data, toPeers: session.connectedPeers, with: mode)
            } catch {
                print("❌ ส่งข้อมูลไม่สำเร็จ: \(error.localizedDescription)")
            }
        }
    
    func disconnect() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        DispatchQueue.main.async {
            self.connectedPeers.removeAll()
            self.availablePeers.removeAll()
            self.lastConnectionError = nil
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            
            // 🟢 ดักจับ Error ถ้าระบบตอบกลับมาว่า .notConnected แปลว่าถูกปฏิเสธ หรือหลุด
            if state == .notConnected {
                self.lastConnectionError = peerID
            }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onDataReceived?(data, peerID)
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser Delegate
extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.pendingInvitation = (peerID, invitationHandler)
        }
    }
}

// MARK: - Browser Delegate
extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // 🟢 กรองชื่อตัวเองออก
        if peerID.displayName != self.myPeerId.displayName {
            DispatchQueue.main.async {
                if !self.availablePeers.contains(peerID) {
                    self.availablePeers.append(peerID)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // 🟢 ลบรายชื่อเมื่อหลุดระยะสแกน
        DispatchQueue.main.async {
            self.availablePeers.removeAll(where: { $0 == peerID })
        }
    }
}
