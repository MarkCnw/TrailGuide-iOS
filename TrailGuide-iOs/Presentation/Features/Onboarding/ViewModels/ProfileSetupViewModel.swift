import SwiftUI
import PhotosUI
import SwiftData

@Observable
final class ProfileSetupViewModel {
    var username: String = ""
    
    var selectedPhotoItem: PhotosPickerItem? {
        didSet { Task { await loadProfileImage() } }
    }
    
    var profileImage: Image?
    private var profileImageData: Data?
    
    var isFormValid: Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedUsername.isEmpty
    }
    
    @MainActor
    private func loadProfileImage() async {
        guard let item = selectedPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                self.profileImageData = data
                self.profileImage = Image(uiImage: uiImage)
            }
        } catch {
            print("❌ Error loading image: \(error.localizedDescription)")
        }
    }
    
    // 🟢 ใส่ @MainActor เพื่อให้คุยกับ SwiftData ได้อย่างปลอดภัย
    @MainActor
    func saveProfile(context: ModelContext) {
        guard isFormValid else { return }
        
        var savedImageFileName: String? = nil
        
        // 🟢 แก้บัค 2: เซฟเฉพาะ "ชื่อไฟล์" ไม่ต้องเซฟ Path ยาวๆ
        if let imageData = self.profileImageData {
            let fileName = UUID().uuidString + ".jpg"
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent(fileName)
                do {
                    try imageData.write(to: fileURL)
                    savedImageFileName = fileName // เก็บแค่ชื่อไฟล์ 1234.jpg
                } catch {
                    print("❌ เซฟรูปภาพไม่สำเร็จ: \(error)")
                }
            }
        }
        
        let repo = UserRepositoryImpl(modelContext: context)
        let newProfile = UserProfileEntity(username: username, imagePath: savedImageFileName)
        
        Task {
            do {
                try await repo.saveUserProfile(profile: newProfile)
                UserDefaults.standard.set(true, forKey: "hasProfile")
                UserDefaults.standard.set(self.username, forKey: "username") // ✅ เพิ่มบรรทัดนี้
            } catch {
                print("❌ เซฟข้อมูลไม่สำเร็จ: \(error)")
            }
        }
    }
}
