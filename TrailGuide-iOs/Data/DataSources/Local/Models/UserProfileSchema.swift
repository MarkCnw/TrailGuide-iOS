import SwiftData

@Model
final class UserProfileSchema {
    var username: String
    var imagePath: String? // เก็บแค่ที่อยู่ไฟล์รูป ไม่เก็บก้อนรูปภาพลง DB
    
    init(username: String, imagePath: String? = nil) {
        self.username = username
        self.imagePath = imagePath
    }
}
