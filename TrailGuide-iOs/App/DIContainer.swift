// 📁 App/DIContainer.swift
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
    
    init() {
        // Setup SwiftData Context
        let sharedModelContainer = try! ModelContainer(for: UserProfileSchema.self)
        self.modelContext = ModelContext(sharedModelContainer)
    }
    
 
    // 3. ฟังก์ชันสร้าง RoomViewModel
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
    
}
