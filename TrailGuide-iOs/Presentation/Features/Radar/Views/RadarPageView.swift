import SwiftUI

struct RadarPageView: View {
    
    @State private var userProfile: UserProfileEntity?
    var userRepository: UserRepositoryProtocol?
    
    var body: some View {
        ZStack {
            // สีพื้นหลังตามระบบ
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                
                // 🟢 เพิ่มหัวข้อ "เรดาร์หาเพื่อน" บนสุด ชิดซ้าย
                HStack {
                                    Text("เรดาร์หาเพื่อนนน")
                                        .font(.largeTitle) // ทำให้ตัวหนังสือใหญ่เหมือนหน้าหลักของแอป iOS
                                        .fontWeight(.heavy)
                                        .foregroundColor(.primary)
                                    
                                    Spacer() // ดันข้อความไปชิดซ้าย
                                }
                                .padding(.top, 20)
                                .padding(.horizontal, 24)
                // ==========================================
                // 🟢 1. ส่วนบน: โชว์รูปและชื่อมุมซ้ายบน
                // ==========================================
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
                            Text("สวัสดีนักเดินทาง")
                                .font(.subheadline)
                                .foregroundColor(.secondary) // สีเทาอ่อนๆ ให้ดูสบายตา
                            
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
                    
                    Spacer() // 🟢 ดันทุกอย่างให้ไปชิดซ้ายสุด
                }
                .padding(.top, 5)
                .padding(.horizontal, 24)
                
                Spacer() // 🟢 ดันก้อนรูปและชื่อขึ้นไปติดขอบบนสุด
                
                // ==========================================
                // 🟢 2. ส่วนล่าง: ปุ่มเลือกบทบาท Host / Member
                // ==========================================
                VStack(spacing: 20) {
                    Text("เลือกบทบาทการเดินทางของคุณ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        // ปุ่ม Host
                        Button(action: {
                            print("👉 เลือกเป็น Host")
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 32))
                                Text("ตั้งกลุ่ม (Host)")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                        
                        // ปุ่ม Member
                        Button(action: {
                            print("👉 เลือกเป็น Member")
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 32))
                                Text("เข้าร่วม (Member)")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
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
}
