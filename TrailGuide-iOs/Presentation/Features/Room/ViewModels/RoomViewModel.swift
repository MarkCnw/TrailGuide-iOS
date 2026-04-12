import Foundation
import MultipeerConnectivity
import Combine

class RoomViewModel: ObservableObject {
    var sessionManager: MultipeerSessionManager
    private var userRepository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        let savedName = UserDefaults.standard.string(forKey: "username")
        let deviceName = UIDevice.current.name
        let name = (savedName?.isEmpty == false) ? savedName! : deviceName
        self.sessionManager = MultipeerSessionManager(username: name)

        sessionManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func startHosting() { sessionManager.startHosting() }
    func stopHosting() { sessionManager.stopHosting() }
    func startBrowsing() { sessionManager.startBrowsing() }
    func stopBrowsing() { sessionManager.stopBrowsing() }
    func join(peer: MCPeerID) { sessionManager.invitePeer(peer) }
    func leaveRoom() { sessionManager.disconnect() }

    // ✅ HIG: Host กดรับ/ปฏิเสธ
    func acceptInvitation() { sessionManager.acceptInvitation() }
    func declineInvitation() { sessionManager.declineInvitation() }
}
