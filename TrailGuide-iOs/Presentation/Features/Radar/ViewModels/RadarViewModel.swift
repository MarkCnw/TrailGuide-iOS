
import SwiftUI
import Observation

@Observable
final class RadarViewModel {
    var username: String = "กำลังโหลด..."
    var profileImage: UIImage? = nil
    var members: [Peer] = []
    
    // ประกาศเรียกใช้ UseCase
    private let getUserProfileUseCase: GetUserProfileUseCase
    
    init(getUserProfileUseCase: GetUserProfileUseCase) {
        self.getUserProfileUseCase = getUserProfileUseCase
    }
    
    @MainActor
    func loadUserData() async {
        do {
            // ไปดึงข้อมูลจาก Local Database
            if let profile = try await getUserProfileUseCase.execute() {
                self.username = profile.username
                
                // ถ้าระบบบอกว่ามีที่อยู่ไฟล์รูปภาพ ก็ไปหยิบรูปมาแสดง
                if let path = profile.imagePath {
                    self.profileImage = UIImage(contentsOfFile: path)
                }
            } else {
                // กรณี Database ว่างเปล่า
                self.username = "นักเดินทางลึกลับ"
            }
        } catch {
            print("❌ อ่าน Database ไม่สำเร็จ: \(error)")
        }
    }
}
