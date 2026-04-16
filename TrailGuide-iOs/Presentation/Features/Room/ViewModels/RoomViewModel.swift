import SwiftUI
import Combine
import MultipeerConnectivity
import CoreLocation
import ImageIO

class RoomViewModel: ObservableObject {
    @Published var sessionManager: MultipeerSessionManager
    @Published var isAdventureStarted: Bool = false
    @Published var memberLocations: [MCPeerID: CLLocationCoordinate2D] = [:]
    @Published var amIHost: Bool = false
    
    @Published var peerImages: [MCPeerID: UIImage] = [:]
    private var myProfileImage: UIImage?
    private var myProfileImageData: Data? // 🟢 1. เพิ่มตัวแปรเก็บ "รูปที่ย่อขนาดแล้ว" เพื่อลดภาระเครื่อง
    
    @Published var showHostEndedAlert: Bool = false
    @Published var locationManager = LocationManager()
    
    private var userRepository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        let name = UserDefaults.standard.string(forKey: "current_username") ?? "นักเดินทาง"
        
        let manager = MultipeerSessionManager(username: name)
        self.sessionManager = manager
        
        manager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        Task { await loadMyProfileImage() }
        
        // 🟢 1. หน่วงเวลา 2 วินาที (debounce) ป้องกันการสแปมส่งรูปเวลาเน็ตเวิร์คแกว่งติดๆดับๆ
                manager.$connectedPeers
                    .debounce(for: .seconds(2.0), scheduler: DispatchQueue.main)
                    .sink { [weak self] peers in
                        if !peers.isEmpty {
                            self?.shareProfileImage()
                        }
                    }
                    .store(in: &cancellables)
        
        // 🟢 2. แก้อาการ "ท่อตัน" ด้วยการใช้ .throttle() หน่วงเวลาส่ง GPS ให้ส่งแค่ "ทุกๆ 2 วินาที"
        locationManager.$currentLocation
            .compactMap { $0 }
            .throttle(for: .seconds(2.0), scheduler: DispatchQueue.main, latest: true) // 🌟 พระเอกอยู่ตรงนี้!
            .sink { [weak self] newLocation in
                self?.sendMyLocation(location: newLocation)
                if let myId = self?.sessionManager.myPeerId {
                    self?.memberLocations[myId] = newLocation.coordinate
                }
            }
            .store(in: &cancellables)
        
        self.setupDataReceiver()
    }
    
    @MainActor
        private func loadMyProfileImage() async {
            do {
                if let profile = try await userRepository.getUserProfile(),
                   let fileName = profile.imagePath {
                    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
                    
                    Task.detached(priority: .background) {
                        // 1. ดึงภาพและย่อขนาดแบบประหยัด RAM
                        let options: [CFString: Any] = [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceShouldCacheImmediately: true,
                            kCGImageSourceThumbnailMaxPixelSize: 150
                        ]
                        
                        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
                              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                            return
                        }
                        
                        let thumbImage = UIImage(cgImage: cgImage)
                        
                        // 🟢 2. สำคัญที่สุด: วาดภาพใหม่เพื่อ "ลบพื้นหลังโปร่งใส (Alpha)" ทิ้ง
                        // ป้องกัน Error 'AlphaPremulLast' และ IOSurface Memory Leak
                        let format = UIGraphicsImageRendererFormat()
                        format.opaque = true // บังคับทึบแสง 100%
                        format.scale = 1.0
                        
                        let renderer = UIGraphicsImageRenderer(size: thumbImage.size, format: format)
                        let safeOpaqueImage = renderer.image { ctx in
                            UIColor.white.set() // เติมพื้นหลังสีขาวแทนที่ส่วนที่โปร่งใส
                            ctx.fill(CGRect(origin: .zero, size: thumbImage.size))
                            thumbImage.draw(in: CGRect(origin: .zero, size: thumbImage.size))
                        }
                        
                        // 3. บีบอัดเป็น JPEG (คราวนี้จะไม่มี Warning แล้วเพราะภาพทึบแสงแล้ว)
                        let compressedData = safeOpaqueImage.jpegData(compressionQuality: 0.4)
                        
                        await MainActor.run {
                            self.myProfileImage = safeOpaqueImage
                            self.peerImages[self.sessionManager.myPeerId] = safeOpaqueImage
                            self.myProfileImageData = compressedData
                        }
                    }
                }
            } catch {
                print("❌ โหลดรูปตัวเองไม่สำเร็จ: \(error)")
            }
        }
    
    private func shareProfileImage() {
            guard let compressedData = myProfileImageData else { return }
            let senderName = self.sessionManager.myPeerId.displayName
            
            // 🟢 2. โยนทุกอย่างไปทำใน Background Thread เพื่อไม่ให้หน้าจอค้าง (แก้ Gesture timed out)
            Task.detached(priority: .background) {
                let payload = P2PPayload(
                    type: .profileImage,
                    senderName: senderName,
                    lat: nil,
                    lng: nil,
                    imageData: compressedData
                )
                
                if let data = try? JSONEncoder().encode(payload) {
                    // กลับมาสั่งส่งข้อมูลบน Main Thread แวบเดียว
                    await MainActor.run {
                        self.sessionManager.broadcast(data: data, mode: .reliable)
                    }
                }
            }
        }
    
    var allMembers: [MCPeerID] {
        var members = sessionManager.connectedPeers
        if !members.contains(sessionManager.myPeerId) {
            members.append(sessionManager.myPeerId)
        }
        return members.sorted { $0.displayName < $1.displayName }
    }
    
    func isHost(_ peer: MCPeerID) -> Bool {
        if amIHost { return peer == sessionManager.myPeerId }
        return peer == sessionManager.connectedPeers.first && peer != sessionManager.myPeerId
    }
    
    func distanceToPeer(_ peer: MCPeerID) -> String {
        guard let myLocation = locationManager.currentLocation,
              let peerCoordinate = memberLocations[peer] else {
            return "กำลังค้นหาสัญญาณ..."
        }
        
        let peerLocation = CLLocation(latitude: peerCoordinate.latitude, longitude: peerCoordinate.longitude)
        let distanceInMeters = myLocation.distance(from: peerLocation)
        
        if distanceInMeters < 5 {
            return "อยู่ใกล้คุณมาก"
        } else if distanceInMeters > 1000 {
            let km = distanceInMeters / 1000
            return String(format: "ระยะ ~%.1f กม.", km)
        } else {
            return String(format: "ระยะ ~%.0f เมตร", distanceInMeters)
        }
    }
    
    private func setupDataReceiver() {
        sessionManager.onDataReceived = { [weak self] data, peer in
            guard let payload = try? JSONDecoder().decode(P2PPayload.self, from: data) else { return }
            
            DispatchQueue.main.async {
                switch payload.type {
                case .startAdventure:
                    self?.isAdventureStarted = true
                case .locationUpdate:
                    if let lat = payload.lat, let lng = payload.lng {
                        self?.memberLocations[peer] = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    }
                case .profileImage:
                    if let imageData = payload.imageData, let image = UIImage(data: imageData) {
                        self?.peerImages[peer] = image
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    func startAdventure() {
        let payload = P2PPayload(type: .startAdventure, senderName: sessionManager.myPeerId.displayName, lat: nil, lng: nil, imageData: nil)
        if let data = try? JSONEncoder().encode(payload) {
            sessionManager.broadcast(data: data)
            self.isAdventureStarted = true
        }
    }
    
    func sendMyLocation(location: CLLocation) {
        let payload = P2PPayload(type: .locationUpdate, senderName: sessionManager.myPeerId.displayName, lat: location.coordinate.latitude, lng: location.coordinate.longitude, imageData: nil)
        
        if let data = try? JSONEncoder().encode(payload) {
            // โหมดนี้สำคัญมาก ต้องเป็น .unreliable เพื่อป้องกันรถติด
            sessionManager.broadcast(data: data, mode: .unreliable)
        }
    }
    
    func startTrackingLocation() {
        locationManager.requestPermission()
        locationManager.startUpdatingLocation()
    }
    
    func stopTrackingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func startBrowsing() { amIHost = false; sessionManager.startBrowsing() }
    func stopBrowsing() { sessionManager.stopBrowsing() }
    func join(peer: MCPeerID) { sessionManager.invitePeer(peer) }
    
    func startHosting() { amIHost = true; sessionManager.startHosting() }
    func stopHosting() { sessionManager.stopHosting() }
    func acceptInvitation() { sessionManager.acceptInvitation() }
    func declineInvitation() { sessionManager.declineInvitation() }
    
    func leaveRoom() {
        sessionManager.disconnect()
        stopTrackingLocation()
        DispatchQueue.main.async {
            self.amIHost = false
            self.isAdventureStarted = false
            self.peerImages.removeAll()
            self.memberLocations.removeAll()
            Task { await self.loadMyProfileImage() }
        }
    }
    
    func updateUsername(_ newName: String) {
        UserDefaults.standard.set(newName, forKey: "username")
        leaveRoom()
        
        let newManager = MultipeerSessionManager(username: newName)
        self.sessionManager = newManager
        
        newManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        newManager.$connectedPeers
            .receive(on: RunLoop.main)
            .sink { [weak self] peers in
                if !peers.isEmpty {
                    self?.shareProfileImage()
                }
            }
            .store(in: &cancellables)
            
        self.setupDataReceiver()
    }
    
    func updateProfileImage() {
        Task {
            await loadMyProfileImage()
            DispatchQueue.main.async {
                self.shareProfileImage()
            }
        }
    }
}
