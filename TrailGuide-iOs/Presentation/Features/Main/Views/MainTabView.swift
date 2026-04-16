import SwiftUI
import SwiftData

struct MainTabView: View {
    @StateObject private var roomViewModel: RoomViewModel
    @State private var selectedTab = 0
    private var userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        _roomViewModel = StateObject(wrappedValue: RoomViewModel(userRepository: userRepository))
        
        // 🟢 1. การตั้งค่า UI ของ TabBar (สีพื้นหลัง และ สีไอคอนที่ไม่ได้เลือก)
        let appearance = UITabBarAppearance()
        
        // ทำให้พื้นหลังทึบ (ไม่โปร่งแสงจนกลืนกับแผนที่)
        appearance.configureWithOpaqueBackground()
        
        // 🎨 เปลี่ยนสีพื้นหลังของ TabBar ตรงนี้ (ตัวอย่าง: ใช้สีพื้นหลังระบบ)
        appearance.backgroundColor = UIColor.systemBackground
        
        // 🎨 เปลี่ยนสีไอคอนและข้อความที่ "ไม่ได้ถูกเลือก" (Unselected)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        // นำการตั้งค่าไปบังคับใช้กับ TabBar ทั้งหมดของแอป
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RadarPageView(userRepository: userRepository)
                .tabItem {
                    Label("เรดาร์", systemImage: "safari.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("ประวัติ", systemImage: "clock")
                }
                .tag(1)
            
            ProfileSettingsView(userRepository: userRepository)
                .tabItem {
                    Label("โปรไฟล์", systemImage: "person")
                }
                .tag(2)
        }
        .environmentObject(roomViewModel)
        
        // 🟢 2. เปลี่ยนสีของไอคอนและข้อความที่ "กำลังเลือกอยู่" (Selected/Active Tab)
        .tint(.green) // 🎨 ลองเปลี่ยนเป็น .blue, .orange หรือ Color("CustomColor") ได้เลยครับ
    }
}
