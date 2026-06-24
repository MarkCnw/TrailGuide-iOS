import Foundation

class UpdateTripNameUseCase {
    private let tripRepository: TripHistoryRepositoryProtocol
    
    init(tripRepository: TripHistoryRepositoryProtocol) {
        self.tripRepository = tripRepository
    }
    
    func execute(id: Int, newName: String) {
        tripRepository.updateTripName(id: id, newName: newName)
    }
}
