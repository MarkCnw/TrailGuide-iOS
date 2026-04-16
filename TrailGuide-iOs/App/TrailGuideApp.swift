import SwiftUI
import SwiftData

@main
struct TrailGuideApp: App {
    @AppStorage("hasProfile") private var hasProfile: Bool = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    // 🟢 1. สร้างตัวแปรสำหรับเก็บ "กล่องฐานข้อมูลหลัก" ของแอป
    let sharedModelContainer: ModelContainer
    
    init() {
        SwiftDataService.setupStorage()
        
        // 🟢 2. เปิดใช้งานกล่องฐานข้อมูล (SwiftData) ตั้งแต่ตอนแอปเริ่มรัน
        do {
            sharedModelContainer = try ModelContainer(for: UserProfileSchema.self)
        } catch {
            fatalError("ไม่สามารถสร้างฐานข้อมูลได้: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasProfile {
                    // 🟢 3. สร้าง UserRepository และ "ส่งเข้าไป" ให้ MainTabView
                    let context = ModelContext(sharedModelContainer)
                    let repo = UserRepositoryImpl(modelContext: context)
                    
                    MainTabView(userRepository: repo) // 👈 ตอนนี้เราไม่ส่งมือเปล่าแล้ว!
                } else {
                    ProfileSetupView()
                }
            }
            .preferredColorScheme(appTheme == "light" ? .light : (appTheme == "dark" ? .dark : nil))
        }
        // 🟢 4. ประกาศให้ทั้งแอปใช้กล่องฐานข้อมูลตัวเดียวกัน
        .modelContainer(sharedModelContainer)
    }
}
