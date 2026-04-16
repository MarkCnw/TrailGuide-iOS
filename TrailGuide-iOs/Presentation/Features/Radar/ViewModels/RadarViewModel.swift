import SwiftUI
import Observation

@Observable
final class RadarViewModel {
    var username: String = "กำลังโหลด..."
    var profileImage: UIImage? = nil
    
    // 🟢 แก้ให้รับ UserRepository เพื่อให้ตรงกับที่ส่งมาจาก MainTabView
    let userRepository: UserRepositoryProtocol?
    
    init(userRepository: UserRepositoryProtocol?) {
        self.userRepository = userRepository
    }
    
    @MainActor
    func loadUserData() async {
        guard let repo = userRepository else { return }
        do {
            if let profile = try await repo.getUserProfile() {
                self.username = profile.username
                
                // 🟢 ประกอบ Path รูปภาพใหม่แบบเดียวกับหน้า Setting
                if let fileName = profile.imagePath,
                   let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentDirectory.appendingPathComponent(fileName)
                    self.profileImage = UIImage(contentsOfFile: fileURL.path)
                }
            } else {
                self.username = "นักเดินทางลึกลับ"
            }
        } catch {
            print("❌ อ่าน Database ไม่สำเร็จ: \(error)")
        }
    }
}
