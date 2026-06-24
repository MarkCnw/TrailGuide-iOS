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
            sharedModelContainer = try ModelContainer(for: UserProfileSchema.self, TripHistoryModel.self)
        } catch {
            fatalError("ไม่สามารถสร้างฐานข้อมูลได้: \(error)")
        }
        
        // 🔔 ขอสิทธิ์การแจ้งเตือน Local Notification ตอนเปิดแอป
        DIContainer.shared.notificationService.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasProfile {
                    // 🟢 MainTabView ไม่ต้องรับ Repository อีกต่อไปแล้ว
                    MainTabView()
                } else {
                    // 🟢 สร้าง ProfileSetupView ผ่าน DIContainer
                    ProfileSetupView(viewModel: DIContainer.shared.makeProfileSetupViewModel())
                }
            }
            .preferredColorScheme(appTheme == "light" ? .light : (appTheme == "dark" ? .dark : nil))
        }
        // 🟢 4. ประกาศให้ทั้งแอปใช้กล่องฐานข้อมูลตัวเดียวกัน
        .modelContainer(sharedModelContainer)
    }
}
