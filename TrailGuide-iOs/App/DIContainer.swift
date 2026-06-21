import Foundation
import SwiftData

class DIContainer {
    
    // Singleton (ถ้าโปรเจคใช้แบบนี้)
    static let shared = DIContainer()
    
    private let modelContext: ModelContext
    
    // 1. สร้าง Service หลักเก็บไว้เป็น Single Instance (เพื่อให้ใช้แชร์กันได้)
    lazy var locationService: LocationServiceProtocol = LocationManager()
    
    // 2. UserRepository
    lazy var userRepository: UserRepositoryProtocol = UserRepositoryImpl(modelContext: modelContext)
    lazy var tripRepository: TripHistoryRepositoryProtocol = TripHistoryRepositoryImpl(modelContext: modelContext)
    
    // 🟢 3. สร้าง LocationRepository (เลขานุการจดพิกัด)
    // โยน locationService (นักสำรวจ) เข้าไปให้เขาทำงานด้วย
    lazy var locationRepository: LocationRepositoryProtocol = LocationRepositoryImpl(locationService: locationService)
    
    init() {
        // Setup SwiftData Context
        // 🟢 เพิ่ม TripHistoryModel.self เข้าไปใน ModelContainer
        let sharedModelContainer = try! ModelContainer(for: UserProfileSchema.self, TripHistoryModel.self)
        self.modelContext = ModelContext(sharedModelContainer)
    }
    
    // 4. ฟังก์ชันสร้าง RoomViewModel
    func makeRoomViewModel() -> RoomViewModel {
        // 🚨 P2P Manager เราต้องสร้างใหม่ตาม Username ปัจจุบัน
        let name = UserDefaults.standard.string(forKey: "username") ?? "นักเดินทาง"
        let p2pService = MultipeerSessionManager(username: name)
        
        // สร้าง Use Case
        let processImageUseCase = ProcessProfileImageUseCase()
        let sendSOSUseCase = SendSOSUseCase(p2pService: p2pService)
        
        // ประกอบร่าง!
        return RoomViewModel(
            p2pService: p2pService,
            locationService: locationService,
            userRepository: userRepository,
            processImageUseCase: processImageUseCase,
            sendSOSUseCase: sendSOSUseCase
        )
    }
    
    // ==========================================
    // 🟢 5. เพิ่มฟังก์ชันสร้าง BreadcrumbViewModel สำหรับหน้าจอแผนที่!
    // ==========================================
    @MainActor
    func makeBreadcrumbViewModel() -> BreadcrumbViewModel {
        // โยนเลขานุการ (LocationRepository) และพนักงานฐานข้อมูล (tripRepository) ไปให้ผู้ช่วยจิตรกร
        return BreadcrumbViewModel(locationRepository: locationRepository, tripRepository: tripRepository)
    }
    
    // ==========================================
    // 🟢 6. เพิ่มฟังก์ชันสร้าง HistoryViewModel สำหรับหน้าจอประวัติ!
    // ==========================================
    func makeHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(tripRepository: tripRepository)
    }
    
}
