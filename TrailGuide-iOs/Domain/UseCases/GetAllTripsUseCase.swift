import Foundation

class GetAllTripsUseCase {
    private let tripRepository: TripHistoryRepositoryProtocol
    
    init(tripRepository: TripHistoryRepositoryProtocol) {
        self.tripRepository = tripRepository
    }
    
    func execute() -> [TripHistory] {
        return tripRepository.getAllTrips()
    }
}
