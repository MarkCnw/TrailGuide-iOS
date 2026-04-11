import SwiftUI
import SwiftData // 🟢 1. อย่าลืมอิมพอร์ต

@main
struct TrailGuideApp: App {
    @AppStorage("hasProfile") private var hasProfile: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasProfile {
                MainTabView()
            } else {
                ProfileSetupView()
            }
        }
        .modelContainer(for: UserProfileSchema.self) // 🟢 2. แปะคำสั่งนี้เพื่อเปิดใช้ฐานข้อมูล
    }
}
