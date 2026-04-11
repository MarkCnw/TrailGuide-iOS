import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext // 🟢 2. ดึงฐานข้อมูลของแอปมา
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Tab 1: เรดาร์ (หน้าหลักที่คุณทำไว้)
            NavigationStack {
                            // 🟢 3. ประกอบร่าง Repository แล้วส่งให้หน้า Radar
                            RadarPageView(userRepository: UserRepositoryImpl(modelContext: modelContext))
                        }
                        .tabItem { Label("เรดาร์", systemImage: "antenna.radiowaves.left.and.right") }
                        .tag(0)
            .tabItem {
                Label("เรดาร์", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(0)
            
            // Tab 2: ประวัติการเดินทาง
            NavigationStack {
                HistoryView() // หน้าประวัติ (รอคุณสร้าง)
                    .navigationTitle("ประวัติเดินป่า")
            }
            .tabItem {
                Label("ประวัติ", systemImage: "map.fill")
            }
            .tag(1)
            
            // Tab 3: ตั้งค่า/โปรไฟล์
            NavigationStack {
                ProfileSettingsView() // หน้าตั้งค่า
                    .navigationTitle("โปรไฟล์")
            }
            .tabItem {
                Label("โปรไฟล์", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
        .accentColor(.blue) // สีของไอคอนที่เลือก
    }
}
