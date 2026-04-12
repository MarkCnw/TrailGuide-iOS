import Foundation
import SwiftData // 👈 เพิ่มบรรทัดนี้

// ตัวอย่างการสร้าง
let sharedModelContainer = try! ModelContainer(for: UserProfileSchema.self)
let modelContext = ModelContext(sharedModelContainer)

// นำไปฉีด (Inject) ใส่ Repository
let userRepository = UserRepositoryImpl(modelContext: modelContext)
// ใน DIContainer.swift (ตัวอย่างการสร้าง)
func makeRadarViewModel() -> RadarViewModel {
    // 1. สร้าง Repository
    let repo = UserRepositoryImpl(modelContext: modelContext)
    
    // 2. สร้าง Use Case แล้วฉีด Repository เข้าไป
    let useCase = GetUserProfileUseCase(userRepository: repo)
    
    // 3. สร้าง ViewModel แล้วฉีด Use Case เข้าไป
    return RadarViewModel(userRepository: userRepository)
}
