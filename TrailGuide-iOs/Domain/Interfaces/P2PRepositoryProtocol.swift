import Foundation

protocol P2PRepositoryProtocol {
    func startHosting(roomName: String)
    func joinRoom()
    func sendLocation(lat: Double, lng: Double)
    func sendSOS()
    func disconnect()
}
