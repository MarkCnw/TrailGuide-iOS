import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Tab 1: เรดาร์
            NavigationStack {
                RadarPageView(userRepository: UserRepositoryImpl(modelContext: modelContext))
            }
            // 🟢 แก้บัค 1: ลบ tabItem ที่ซ้ำซ้อนออก เหลือแค่อันเดียว
            .tabItem {
                Label("เรดาร์", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(0)
            
            // Tab 2: ประวัติการเดินทาง
            NavigationStack {
                HistoryView()
                    .navigationTitle("ประวัติเดินป่า")
            }
            .tabItem {
                Label("ประวัติ", systemImage: "map.fill")
            }
            .tag(1)
            
            // Tab 3: ตั้งค่า/โปรไฟล์
                        NavigationStack {
                            // 🟢 แก้ไข: ส่ง userRepository เข้าไปด้วย
                            ProfileSettingsView(userRepository: UserRepositoryImpl(modelContext: modelContext))
                                .navigationTitle("โปรไฟล์")
                        }
                        .tabItem {
                            Label("โปรไฟล์", systemImage: "person.crop.circle")
                        }
                        .tag(2)
        }
        .accentColor(.blue)
    }
}
