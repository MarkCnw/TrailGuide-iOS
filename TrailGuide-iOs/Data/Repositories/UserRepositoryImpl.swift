import Foundation
import SwiftData

// 🟢 แก้บัค 3: ใส่ @MainActor เพื่อบังคับให้ Context ทำงานบน Main Thread เสมอ ป้องกันแอปแครช
@MainActor
class UserRepositoryImpl: UserRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getUserProfile() async throws -> UserProfileEntity? {
        let descriptor = FetchDescriptor<UserProfileSchema>()
        let schemas = try modelContext.fetch(descriptor)
        
        guard let currentUser = schemas.first else {
            return nil
        }
        
        return UserProfileEntity(
            username: currentUser.username,
            imagePath: currentUser.imagePath
        )
    }
    
    func saveUserProfile(profile: UserProfileEntity) async throws {
        let descriptor = FetchDescriptor<UserProfileSchema>()
        let existingProfiles = try modelContext.fetch(descriptor)
        
        for existing in existingProfiles {
            modelContext.delete(existing)
        }
        
        let newSchema = UserProfileSchema(
            username: profile.username,
            imagePath: profile.imagePath
        )
        
        modelContext.insert(newSchema)
        try modelContext.save()
    }
}
