import Foundation

class GetUserProfileUseCase {
    // ดึง Repository ผ่าน Protocol (Interface) ตามหลัก Dependency Inversion
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    // ฟังก์ชันหลักที่จะถูกเรียกใช้จาก ViewModel
    func execute() async throws -> UserProfileEntity? {
        // สั่งให้ Repository ไปดึงข้อมูลมา
        return try await userRepository.getUserProfile()
    }
}
