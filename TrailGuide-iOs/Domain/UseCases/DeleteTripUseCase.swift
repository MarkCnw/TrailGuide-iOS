import Foundation

class DeleteTripUseCase {
    private let tripRepository: TripHistoryRepositoryProtocol
    
    init(tripRepository: TripHistoryRepositoryProtocol) {
        self.tripRepository = tripRepository
    }
    
    func execute(id: Int) {
        tripRepository.deleteTrip(id: id)
    }
}
