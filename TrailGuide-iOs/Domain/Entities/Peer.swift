import Foundation

struct Peer: Identifiable, Equatable {
    let id: String
    let name: String
    var latitude: Double?
    var longitude: Double?
    var heading: Double?
    var isActive: Bool
    var isHost: Bool
}
