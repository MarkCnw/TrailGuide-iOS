import SwiftUI
import Observation

@Observable
final class RadarViewModel {
    var username: String = "กำลังโหลด..."
    var profileImage: UIImage? = nil
    
    // 🟢 ใช้ UseCase แทน Repository โดยตรง
    private let getUserProfileUseCase: GetUserProfileUseCase
    
    init(getUserProfileUseCase: GetUserProfileUseCase) {
        self.getUserProfileUseCase = getUserProfileUseCase
    }
    
    @MainActor
    func loadUserData() async {
        do {
            if let profile = try await getUserProfileUseCase.execute() {
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
