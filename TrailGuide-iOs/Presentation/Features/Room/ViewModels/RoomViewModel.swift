import SwiftUI
import Combine
import MultipeerConnectivity
import CoreLocation

class RoomViewModel: ObservableObject {
    private var p2pService: P2PServiceProtocol
    private var locationService: LocationServiceProtocol
    private var userRepository: UserRepositoryProtocol
    private let processImageUseCase: ProcessProfileImageUseCase
    private let sendSOSUseCase: SendSOSUseCase
    
    @Published var availablePeers: [MCPeerID] = []
    @Published var lastConnectionError: MCPeerID? = nil
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isAdventureStarted: Bool = false
    @Published var amIHost: Bool = false
    @Published var showTripSummary: Bool = false
    @Published var tripStartTime: Date?
    // 🟢 ตัวแปรสำหรับฟีเจอร์ SOS ใหม่
    @Published var sosIncomingFrom: String?
    @Published var sosActivePeers: Set<MCPeerID> = []
    @Published var showSOSReceivedAlert: Bool = false
    @Published var latestSOSPeerName: String = ""
    
    @Published var showHostEndedAlert: Bool = false
    @Published var trailMembers: [MCPeerID: TrailMember] = [:]
    @Published var isReconnecting: Bool = false // 🟢 UI feedback for auto-reconnect
    
    private var myProfileImageData: Data?
    private var cancellables = Set<AnyCancellable>()
    
    init(p2pService: P2PServiceProtocol, locationService: LocationServiceProtocol, userRepository: UserRepositoryProtocol, processImageUseCase: ProcessProfileImageUseCase, sendSOSUseCase: SendSOSUseCase) {
        self.p2pService = p2pService
        self.locationService = locationService
        self.userRepository = userRepository
        self.processImageUseCase = processImageUseCase
        self.sendSOSUseCase = sendSOSUseCase
        setupBindings()
        setupDataReceiver()
        Task { await loadMyProfileImage() }
    }
    
    private func setupBindings() {
        p2pService.availablePeersPublisher.receive(on: DispatchQueue.main).sink { [weak self] peers in 
            self?.availablePeers = peers 
            
            // 🟢 Auto-invite on rediscovery
            if self?.isAdventureStarted == true && self?.p2pService.isReconnecting == true {
                for peer in peers {
                    if self?.p2pService.knownPeerNames.contains(peer.displayName) == true {
                        self?.p2pService.invitePeer(peer)
                    }
                }
            }
        }.store(in: &cancellables)
        
        p2pService.lastConnectionErrorPublisher.receive(on: DispatchQueue.main).sink { [weak self] error in self?.lastConnectionError = error }.store(in: &cancellables)
        
        p2pService.connectedPeersPublisher.receive(on: DispatchQueue.main).sink { [weak self] peers in 
            self?.connectedPeers = peers 
            self?.handleConnectionChange(peers: peers)
        }.store(in: &cancellables)
        
        p2pService.isReconnectingPublisher.receive(on: DispatchQueue.main).sink { [weak self] reconnecting in 
            self?.isReconnecting = reconnecting 
        }.store(in: &cancellables)
        
        p2pService.objectWillChangePublisher.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        
        p2pService.connectedPeersPublisher
            .debounce(for: .seconds(2.0), scheduler: DispatchQueue.main)
            .sink { [weak self] peers in if !peers.isEmpty { self?.shareProfileImage() } }
            .store(in: &cancellables)
        
        locationService.locationPublisher
            .compactMap { $0 }
            .throttle(for: .seconds(2.0), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] newLocation in
                guard let self = self else { return }
                self.sendMyLocation(location: newLocation, heading: self.locationService.safeHeading)
                self.updateMember(id: self.p2pService.myPeerId, location: newLocation.coordinate, heading: self.locationService.safeHeading)
            }
            .store(in: &cancellables)
        
        // 🟢 อัปเดตเข็มทิศให้ UI ของตัวเองทันทีแบบเรียลไทม์ (เพื่อให้เรดาร์หมุนสมูท)
        locationService.headingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                guard let self = self else { return }
                self.updateMember(id: self.p2pService.myPeerId, location: nil, heading: heading)
            }
            .store(in: &cancellables)
            
        // 🟢 ส่งข้อมูลเข็มทิศให้เพื่อนผ่าน P2P เฉพาะทุกๆ 1 วินาทีเพื่อประหยัดแบนด์วิธ
        locationService.headingPublisher
            .throttle(for: .seconds(1.0), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] heading in
                guard let self = self, let location = self.locationService.currentLocation else { return }
                self.sendMyLocation(location: location, heading: heading)
            }
            .store(in: &cancellables)
    }
    
    // 🟢 Reconnection handler
    private func handleConnectionChange(peers: [MCPeerID]) {
        guard isAdventureStarted else { return }
        
        if peers.isEmpty {
            // Signal dropped, trigger reconnection
            p2pService.isReconnecting = true
            if amIHost {
                p2pService.startHosting()
            } else {
                p2pService.startBrowsing()
            }
        } else if p2pService.isReconnecting {
            // Reconnected successfully
            p2pService.isReconnecting = false
            if !amIHost {
                p2pService.stopBrowsing()
            }
            shareProfileImage()
        }
    }
    
    @MainActor private func shareProfileImage() {
        guard let compressedData = myProfileImageData else { return }
        let payload = P2PPayload(type: .profileImage, senderName: p2pService.myPeerId.displayName, lat: nil, lng: nil, heading: nil, imageData: compressedData)
        if let data = try? JSONEncoder().encode(payload) {
            Task.detached(priority: .background) { await MainActor.run { self.p2pService.broadcast(data: data, mode: .reliable) } }
        }
    }
    
    func sendMyLocation(location: CLLocation, heading: Double?) {
        let payload = P2PPayload(type: .locationUpdate, senderName: p2pService.myPeerId.displayName, lat: location.coordinate.latitude, lng: location.coordinate.longitude, heading: heading, imageData: nil)
        if let data = try? JSONEncoder().encode(payload) { p2pService.broadcast(data: data, mode: .unreliable) }
    }
    
    private func updateMember(id: MCPeerID, location: CLLocationCoordinate2D? = nil, heading: Double? = nil, image: UIImage? = nil) {
        if trailMembers[id] == nil { trailMembers[id] = TrailMember(id: id) }
        if let loc = location { trailMembers[id]?.location = loc; trailMembers[id]?.lastSeen = Date() }
        if let h = heading { trailMembers[id]?.heading = h }
        if let img = image { trailMembers[id]?.profileImage = img }
    }
    
    @MainActor private func loadMyProfileImage() async {
        guard let profile = try? await userRepository.getUserProfile(), let fileName = profile.imagePath else { return }
        if let result = await processImageUseCase.execute(fileName: fileName) {
            self.updateMember(id: self.p2pService.myPeerId, image: result.image)
            self.myProfileImageData = result.compressedData
        }
    }
    
    func sendSOS() { sendSOSUseCase.execute(senderName: p2pService.myPeerId.displayName) }
    func startTrackingLocation() { locationService.requestPermission(); DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.locationService.startUpdatingLocation() } }
    func stopTrackingLocation() { locationService.stopUpdatingLocation() }
    func startBrowsing() { amIHost = false; p2pService.startBrowsing() }
    func stopBrowsing() { p2pService.stopBrowsing() }
    func startHosting() { amIHost = true; p2pService.startHosting() }
    func stopHosting() { p2pService.stopHosting() }
    func join(peer: MCPeerID) { p2pService.invitePeer(peer) }
    func acceptInvitation() { p2pService.acceptInvitation() }
    func declineInvitation() { p2pService.declineInvitation() }
    func resetSessionForRetry() { p2pService.resetSessionForRetry() }
    
    // 🟢 เพิ่มฟังก์ชันที่หายไปกลับมาให้ครบ
    func leaveRoom(source: String = "Unknown") {
        p2pService.disconnect()
        stopTrackingLocation()
        DispatchQueue.main.async {
            self.amIHost = false
            self.isAdventureStarted = false
            self.showTripSummary = false
            self.tripStartTime = nil
            self.trailMembers.removeAll()
            Task { await self.loadMyProfileImage() }
        }
    }
    
    func startAdventure() {
        // 🟢 Store peer names for reconnection
        var knownNames = Set(connectedPeers.map { $0.displayName })
        knownNames.insert(p2pService.myPeerId.displayName)
        p2pService.knownPeerNames = knownNames
        
        let payload = P2PPayload(type: .startAdventure, senderName: p2pService.myPeerId.displayName, lat: nil, lng: nil, heading: nil, imageData: nil)
        if let data = try? JSONEncoder().encode(payload) {
            p2pService.broadcast(data: data, mode: .reliable)
            let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.success)
            self.isAdventureStarted = true; self.tripStartTime = Date()
        }
    }
    
    func endAdventure() {
        let payload = P2PPayload(type: .endAdventure, senderName: p2pService.myPeerId.displayName, lat: nil, lng: nil, heading: nil, imageData: nil)
        if let data = try? JSONEncoder().encode(payload) { p2pService.broadcast(data: data, mode: .reliable) }
        let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.success)
        self.showTripSummary = true
    }
    
    private func setupDataReceiver() {
        p2pService.onDataReceived = { [weak self] data, peer in
            guard let payload = try? JSONDecoder().decode(P2PPayload.self, from: data) else { return }
            DispatchQueue.main.async {
                switch payload.type {
                case .startAdventure:
                    let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.success)
                    self?.isAdventureStarted = true; self?.tripStartTime = Date()
                    // 🟢 Snapshot known peers for members too
                    if let connected = self?.connectedPeers, let myId = self?.p2pService.myPeerId.displayName {
                        var names = Set(connected.map { $0.displayName })
                        names.insert(myId)
                        names.insert(peer.displayName) // The host
                        self?.p2pService.knownPeerNames = names
                    }
                case .endAdventure:
                    let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.success)
                    self?.showTripSummary = true
                case .locationUpdate:
                    let coord = (payload.lat != nil && payload.lng != nil) ? CLLocationCoordinate2D(latitude: payload.lat!, longitude: payload.lng!) : nil
                    self?.updateMember(id: peer, location: coord, heading: payload.heading)
                case .profileImage:
                    if let imgData = payload.imageData, let image = UIImage(data: imgData) { self?.updateMember(id: peer, image: image) }
                case .sos:
                    let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.error)
                    self?.sosIncomingFrom = payload.senderName
                    self?.latestSOSPeerName = payload.senderName
                    self?.sosActivePeers.insert(peer)
                    self?.showSOSReceivedAlert = true
                    
                    // 🟢 Auto clear after 60 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                        self?.sosActivePeers.remove(peer)
                    }
                }
            }
        }
    }
    
    func updateProfileImage() { Task { await loadMyProfileImage(); DispatchQueue.main.async { self.shareProfileImage() } } }
    func updateUsername(_ newName: String) {
        UserDefaults.standard.set(newName, forKey: "username")
        leaveRoom()
        p2pService.updateUsername(newName) // 🟢 เรียกใช้จาก Protocol
        self.setupDataReceiver()
    }
    
    // MARK: - View Helpers
    var allMembers: [MCPeerID] {
        var members = p2pService.connectedPeers
        if !members.contains(p2pService.myPeerId) { members.append(p2pService.myPeerId) }
        return members.sorted { p1, p2 in
            if p1 == p2pService.myPeerId { return true }
            if p2 == p2pService.myPeerId { return false }
            guard let myLoc = locationService.currentLocation else { return p1.displayName < p2.displayName }
            let dist1 = trailMembers[p1]?.location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: myLoc) } ?? Double.infinity
            let dist2 = trailMembers[p2]?.location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: myLoc) } ?? Double.infinity
            return dist1 < dist2
        }
    }
    
    func distanceToPeer(_ peer: MCPeerID) -> String {
        guard let myLoc = locationService.currentLocation, let peerCoord = trailMembers[peer]?.location else { return "กำลังค้นหาสัญญาณ..." }
        let distance = myLoc.distance(from: CLLocation(latitude: peerCoord.latitude, longitude: peerCoord.longitude))
        if distance < 5 { return "อยู่ใกล้คุณมาก" }
        if distance > 1000 { return String(format: "ระยะ ~%.1f กม.", distance / 1000) }
        return String(format: "ระยะ ~%.0f เมตร", distance)
    }
    
    func isHost(_ peer: MCPeerID) -> Bool {
        if amIHost { return peer == p2pService.myPeerId }
        return peer == p2pService.connectedPeers.first && peer != p2pService.myPeerId
    }
    
    func bearingToPeer(_ peer: MCPeerID) -> Double? {
        guard let myLoc = locationService.currentLocation, let peerCoord = trailMembers[peer]?.location else { return nil }
        let bearing = LocationCalculator.calculateBearing(lat1: myLoc.coordinate.latitude, lon1: myLoc.coordinate.longitude, lat2: peerCoord.latitude, lon2: peerCoord.longitude)
        return bearing - locationService.safeHeading
    }
    
}
