import Foundation
import MultipeerConnectivity
import Combine

class MultipeerSessionManager: NSObject, ObservableObject {

    private let serviceType = "trail-p2p"
    private let myPeerId: MCPeerID
    private(set) var session: MCSession

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published var connectedPeers: [MCPeerID] = []
    @Published var availablePeers: [MCPeerID] = []

    // ✅ HIG: Host ต้องรับ/ปฏิเสธเอง
    @Published var pendingInvitation: (peer: MCPeerID, handler: (Bool, MCSession?) -> Void)? = nil

    init(username: String) {
        self.myPeerId = MCPeerID(displayName: username)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
        print("🆔 สร้าง PeerID: \(username)")
    }

    func startHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("📡 Host [\(myPeerId.displayName)]: กำลังปล่อยสัญญาณ...")
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        print("📡 Host: หยุดปล่อยสัญญาณ")
    }

    func startBrowsing() {
        browser?.stopBrowsingForPeers()
        availablePeers.removeAll()
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("🔍 Member [\(myPeerId.displayName)]: กำลังค้นหา...")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        availablePeers.removeAll()
        print("🔍 Member: หยุดค้นหา")
    }

    func invitePeer(_ peer: MCPeerID) {
        print("✉️ Member: ส่งคำเชิญไปหา \(peer.displayName)")
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }

    // ✅ Host กดยอมรับ
    func acceptInvitation() {
        pendingInvitation?.handler(true, session)
        pendingInvitation = nil
    }

    // ✅ Host กดปฏิเสธ
    func declineInvitation() {
        pendingInvitation?.handler(false, nil)
        pendingInvitation = nil
    }

    func disconnect() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        connectedPeers.removeAll()
        availablePeers.removeAll()
    }
}

extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📥 Host: ได้รับคำขอจาก \(peerID.displayName)")
        // ✅ เก็บ invitation ไว้รอ Host กดเอง แทนที่จะ auto-accept
        DispatchQueue.main.async {
            self.pendingInvitation = (peer: peerID, handler: invitationHandler)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Host: ปล่อยสัญญาณไม่ได้ — \(error.localizedDescription)")
    }
}

extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        print("🎯 Member: พบ \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ Member: สัญญาณของ \(peerID.displayName) หายไป")
        DispatchQueue.main.async {
            self.availablePeers.removeAll(where: { $0 == peerID })
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Member: สแกนไม่ได้ — \(error.localizedDescription)")
    }
}

extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ เชื่อมต่อกับ \(peerID.displayName) สำเร็จ!")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .notConnected:
                print("🔴 หลุดการเชื่อมต่อกับ \(peerID.displayName)")
                self.connectedPeers.removeAll(where: { $0 == peerID })
            case .connecting:
                print("⏳ กำลังเชื่อมต่อกับ \(peerID.displayName)...")
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
