import Foundation

class SaveTripUseCase {
    private let tripRepository: TripHistoryRepositoryProtocol
    
    init(tripRepository: TripHistoryRepositoryProtocol) {
        self.tripRepository = tripRepository
    }
    
    func execute(_ trip: TripHistory) {
        tripRepository.saveTrip(trip)
    }
}
