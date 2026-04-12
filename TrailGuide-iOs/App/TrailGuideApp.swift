import SwiftUI
import SwiftData // 🟢 1. อิมพอร์ตถูกต้องแล้ว

@main
struct TrailGuideApp: App {
    @AppStorage("hasProfile") private var hasProfile: Bool = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            // 🟢 เอา Group มาครอบ View ภายในไว้
            Group {
                if hasProfile {
                    MainTabView()
                } else {
                    ProfileSetupView()
                }
            }
            // 🟢 ย้ายคำสั่งมาแปะติดกับ Group แทน
            .preferredColorScheme(appTheme == "light" ? .light : (appTheme == "dark" ? .dark : nil))
            .modelContainer(for: UserProfileSchema.self)
        }
    }
}
