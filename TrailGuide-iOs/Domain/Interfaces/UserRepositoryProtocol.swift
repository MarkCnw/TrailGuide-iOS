import Foundation

// สัญญาที่บอกว่า Repository ต้องทำอะไรได้บ้าง
protocol UserRepositoryProtocol {
    func getUserProfile() async throws -> UserProfileEntity?
    func saveUserProfile(profile: UserProfileEntity) async throws
}
