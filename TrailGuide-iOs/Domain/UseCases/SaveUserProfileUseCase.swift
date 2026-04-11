import Foundation

class SaveUserProfileUseCase {
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func execute(profile: UserProfileEntity) async throws {
        // สั่งให้ Repository บันทึกข้อมูลลง SwiftData
        try await userRepository.saveUserProfile(profile: profile)
    }
}
