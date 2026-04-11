import Foundation
import SwiftData

// กำหนดให้ Class นี้ทำงานตามสัญญาที่ให้ไว้ใน UserRepositoryProtocol
class UserRepositoryImpl: UserRepositoryProtocol {
    
    // พระเอกของ SwiftData ที่ใช้จัดการฐานข้อมูล
    private let modelContext: ModelContext
    
    // รับ ModelContext เข้ามาผ่าน Dependency Injection
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ดึงข้อมูลผู้ใช้
    func getUserProfile() async throws -> UserProfileEntity? {
        // 1. สร้างคำสั่งค้นหา (Query) ดึงข้อมูล UserProfileSchema ทั้งหมด
        let descriptor = FetchDescriptor<UserProfileSchema>()
        
        // 2. สั่งดึงข้อมูลจากฐานข้อมูล
        let schemas = try modelContext.fetch(descriptor)
        
        // 3. เนื่องจากแอปเรามีผู้ใช้คนเดียวบนเครื่อง ให้ดึงตัวแรกมาใช้งาน (ถ้าไม่มีให้ return nil)
        guard let currentUser = schemas.first else {
            return nil
        }
        
        // 4. 🔄 MAPPING: แปลง Data Model ให้กลายเป็น Domain Entity (ห้ามส่ง Schema กลับไปเด็ดขาด)
        return UserProfileEntity(
            username: currentUser.username,
            imagePath: currentUser.imagePath
        )
    }
    
    // MARK: - บันทึกข้อมูลผู้ใช้
    func saveUserProfile(profile: UserProfileEntity) async throws {
        // 1. ค้นหาข้อมูลผู้ใช้เก่าที่อาจจะเคยมีอยู่
        let descriptor = FetchDescriptor<UserProfileSchema>()
        let existingProfiles = try modelContext.fetch(descriptor)
        
        // 2. เคลียร์ข้อมูลเก่าทิ้ง (เพื่อให้มีโปรไฟล์เดียวเสมอ)
        for existing in existingProfiles {
            modelContext.delete(existing)
        }
        
        // 3. 🔄 MAPPING: แปลง Domain Entity ที่รับมา ให้กลายเป็น Data Model
        let newSchema = UserProfileSchema(
            username: profile.username,
            imagePath: profile.imagePath
        )
        
        // 4. สั่งเพิ่มข้อมูลใหม่ลง Context และกด Save
        modelContext.insert(newSchema)
        try modelContext.save()
    }
}
