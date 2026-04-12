import Foundation
import MultipeerConnectivity
import Combine

class MultipeerSessionManager: NSObject, ObservableObject {
    
    // ==========================================
    // 🟢 เสาหลักที่ 1: การตั้งชื่อและระบุตัวตน (Identity & Session)
    // ==========================================
    private let serviceType = "trail-p2p" // รหัสประจำแอป (ห้ามเกิน 15 ตัวอักษร พิมพ์เล็กทั้งหมด)
    private let myPeerId: MCPeerID
    private(set) var session: MCSession
    
    // ตัวแปรสำหรับปล่อยและค้นหาสัญญาณ
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // ตัวแปรสำหรับส่งข้อมูลไปโชว์ที่หน้าจอ (UI) ทันทีที่มีการเปลี่ยนแปลง
    @Published var connectedPeers: [MCPeerID] = [] // รายชื่อเพื่อนที่เชื่อมต่อสำเร็จ (อยู่ใน Lobby)
    @Published var availablePeers: [MCPeerID] = [] // รายชื่อ Host ที่สแกนเจอ (เอาไว้โชว์ใน ScanView)
    
    init(username: String) {
        // 1. สร้างตัวตนจากชื่อผู้ใช้
        self.myPeerId = MCPeerID(displayName: username)
        
        // 2. สร้างห้องแชท (Session)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        // 3. ตั้งค่าให้คลาสนี้เป็นคนคอยรับฟังสถานะของห้องแชท
        self.session.delegate = self
    }
    
    // ==========================================
    // 🟢 เสาหลักที่ 2: โหมดหัวหน้าทริป (Host / Advertiser)
    // ==========================================
    func startHosting() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("📡 Host: กำลังปล่อยสัญญาณ...")
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        print("📡 Host: หยุดปล่อยสัญญาณ")
    }
    
    // ==========================================
    // 🟢 เสาหลักที่ 3: โหมดลูกทริป (Member / Browser)
    // ==========================================
    func startBrowsing() {
        availablePeers.removeAll() // ล้างรายชื่อเก่าก่อนสแกนใหม่
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("🔍 Member: กำลังค้นหาหัวหน้าทริปใกล้เคียง...")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        availablePeers.removeAll()
        print("🔍 Member: หยุดค้นหา")
    }
    
    // สั่งส่งคำเชิญไปหา Host ที่เลือก
    func invitePeer(_ peer: MCPeerID) {
        print("✉️ Member: กำลังส่งคำขอเข้าร่วมกลุ่มไปหา \(peer.displayName)")
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }
    
    // ตัดการเชื่อมต่อทั้งหมดและออกจากกลุ่ม
    func disconnect() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        connectedPeers.removeAll()
        availablePeers.removeAll()
    }
}

// ==========================================
// 🟢 เสาหลักที่ 2 (ภาคต่อ): ดักฟังคำขอฝั่ง Host
// ==========================================
extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📥 Host: ได้รับคำขอเข้าร่วมจาก \(peerID.displayName)")
        // กดยอมรับลูกทริปอัตโนมัติ (true) และดึงเข้ามาใน Session
        invitationHandler(true, self.session)
    }
}

// ==========================================
// 🟢 เสาหลักที่ 3 (ภาคต่อ): ดักฟังการสแกนเจอ Host
// ==========================================
extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🎯 Member: สแกนพบหัวหน้าทริปชื่อ \(peerID.displayName)")
        DispatchQueue.main.async {
            // ถ้ายืนยันว่ายังไม่มีชื่อนี้ในลิสต์ ให้เพิ่มเข้าไป
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
}

// ==========================================
// 🟢 เสาหลักที่ 4: นักสืบสถานะห้องแชท (Session Delegate)
// ==========================================
extension MultipeerSessionManager: MCSessionDelegate {
    
    // สังเกตสถานะการเชื่อมต่อ (ติด/กำลังเชื่อม/หลุด)
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Session: เชื่อมต่อกับ \(peerID.displayName) สำเร็จ!")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .notConnected:
                print("🔴 Session: หลุดการเชื่อมต่อกับ \(peerID.displayName)")
                self.connectedPeers.removeAll(where: { $0 == peerID })
            case .connecting:
                print("⏳ Session: กำลังเชื่อมต่อกับ \(peerID.displayName)...")
            @unknown default:
                break
            }
        }
    }
    
    // รับข้อมูล (Data) ที่ส่งหากันในกลุ่ม
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("💬 Session: ได้รับข้อมูลจาก \(peerID.displayName)")
        // TODO: เตรียมไว้สำหรับแปลง Data เป็นข้อความ SOS หรือ พิกัด GPS ในอนาคต
    }
    
    // --- ฟังก์ชันบังคับของ Protocol (ใส่ไว้ให้ระบบไม่ Error แต่แอปเรายังไม่ได้ใช้) ---
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
