import Foundation
import SwiftData

class DIContainer {
    
    // Singleton (ถ้าโปรเจคใช้แบบนี้)
    static let shared = DIContainer()
    
    private let modelContext: ModelContext
    
    // ==========================================
    // 1. Data Layer Services (Single Instance)
    // ==========================================
    lazy var locationService: LocationServiceProtocol = LocationManager()
    
    // ==========================================
    // 2. Repositories (ถูกซ่อนไว้ใน DIContainer เท่านั้น)
    // ==========================================
    lazy var userRepository: UserRepositoryProtocol = UserRepositoryImpl(modelContext: modelContext)
    lazy var tripRepository: TripHistoryRepositoryProtocol = TripHistoryRepositoryImpl(modelContext: modelContext)
    lazy var locationRepository: LocationRepositoryProtocol = LocationRepositoryImpl(locationService: locationService)
    lazy var notificationService: NotificationServiceProtocol = LocalNotificationService()
    
    // ==========================================
    // 3. Domain Use Cases
    // ==========================================
    lazy var getUserProfileUseCase: GetUserProfileUseCase = GetUserProfileUseCase(userRepository: userRepository)
    lazy var saveUserProfileUseCase: SaveUserProfileUseCase = SaveUserProfileUseCase(userRepository: userRepository)
    lazy var getAllTripsUseCase: GetAllTripsUseCase = GetAllTripsUseCase(tripRepository: tripRepository)
    lazy var saveTripUseCase: SaveTripUseCase = SaveTripUseCase(tripRepository: tripRepository)
    lazy var updateTripNameUseCase: UpdateTripNameUseCase = UpdateTripNameUseCase(tripRepository: tripRepository)
    lazy var deleteTripUseCase: DeleteTripUseCase = DeleteTripUseCase(tripRepository: tripRepository)
    
    init() {
        // Setup SwiftData Context
        let sharedModelContainer = try! ModelContainer(for: UserProfileSchema.self, TripHistoryModel.self)
        self.modelContext = ModelContext(sharedModelContainer)
    }
    
    // ==========================================
    // 4. Factory Methods — สร้าง ViewModels สำหรับ Presentation Layer
    // ==========================================
    
    func makeRoomViewModel() -> RoomViewModel {
        // 🚨 P2P Manager เราต้องสร้างใหม่ตาม Username ปัจจุบัน
        let name = UserDefaults.standard.string(forKey: "username") ?? "นักเดินทาง"
        let p2pService = MultipeerSessionManager(username: name)
        
        // สร้าง Use Case / Helpers
        let processImageUseCase = ProcessProfileImageUseCase()
        let sendSOSUseCase = SendSOSUseCase(p2pService: p2pService)
        
        // ประกอบร่าง!
        return RoomViewModel(
            p2pService: p2pService,
            locationService: locationService,
            getUserProfileUseCase: getUserProfileUseCase,
            processImageUseCase: processImageUseCase,
            sendSOSUseCase: sendSOSUseCase
        )
    }
    
    @MainActor
    func makeBreadcrumbViewModel() -> BreadcrumbViewModel {
        return BreadcrumbViewModel(
            locationRepository: locationRepository,
            saveTripUseCase: saveTripUseCase,
            notificationService: notificationService
        )
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            getAllTripsUseCase: getAllTripsUseCase,
            updateTripNameUseCase: updateTripNameUseCase,
            deleteTripUseCase: deleteTripUseCase
        )
    }
    
    func makeRadarViewModel() -> RadarViewModel {
        return RadarViewModel(getUserProfileUseCase: getUserProfileUseCase)
    }
    
    func makeProfileSetupViewModel() -> ProfileSetupViewModel {
        return ProfileSetupViewModel(saveUserProfileUseCase: saveUserProfileUseCase)
    }
    
    func makeProfileSettingsView() -> ProfileSettingsView {
        return ProfileSettingsView(
            getUserProfileUseCase: getUserProfileUseCase,
            saveUserProfileUseCase: saveUserProfileUseCase
        )
    }
    
}
