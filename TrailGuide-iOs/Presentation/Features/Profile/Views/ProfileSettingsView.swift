import SwiftUI

struct ProfileSettingsView: View {
    // 🟢 1. ดึงค่ามาจาก AppStorage เพื่อใช้สำหรับปุ่ม Logout
    @AppStorage("hasProfile") private var hasProfile: Bool = true
    
    // ตัวแปรสำหรับเก็บข้อมูลที่จะดึงมาจากฐานข้อมูล
    @State private var userProfile: UserProfileEntity?
    var userRepository: UserRepositoryProtocol?
    
    var body: some View {
        List {
            // ==========================================
            // 🟢 ส่วนที่ 1: แสดงข้อมูลโปรไฟล์
            // ==========================================
            Section {
                HStack(spacing: 16) {
                    if let profile = userProfile {
                        
                        // --- ส่วนรูปภาพ ---
                        if let imagePath = profile.imagePath,
                           let uiImage = UIImage(contentsOfFile: imagePath) {
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            
                        } else {
                            // ถ้าไม่มีรูปโชว์ตัวอักษรย่อ
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                                .overlay(
                                    Text(String(profile.username.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.blue)
                                )
                        }
                        
                        // --- ส่วนข้อความ ---
                        VStack(alignment: .leading, spacing: 4) {
                            Text("สวัสดีนักเดินทางง")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(profile.username)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                    } else {
                        // โชว์ตอนรอโหลดข้อมูล
                        Text("Loading...")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            } // 🟢 ปิด Section แรกตรงนี้
            
            // ==========================================
            // 🟢 ส่วนที่ 2: ตั้งค่าระบบ (ปุ่มออก)
            // ==========================================
            Section(header: Text("ตั้งค่าระบบ")) {
                Button(role: .destructive, action: {
                    logOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("ล้างข้อมูลและออกจากระบบ")
                    }
                }
            }
        }
        // 🟢 2. สั่งให้ดึงข้อมูลจาก Database เมื่อเปิดหน้านี้
        .task {
            if let repo = userRepository {
                do {
                    self.userProfile = try await repo.getUserProfile()
                } catch {
                    print("❌ Error fetching profile: \(error)")
                }
            }
        }
    }
    
    // 🟢 3. ฟังก์ชันต้องอยู่นอก body เสมอ
    private func logOut() {
        withAnimation {
            hasProfile = false // เปลี่ยนค่าปุ๊บ แอปจะเด้งกลับไปหน้า Onboarding ทันที
        }
    }
}
