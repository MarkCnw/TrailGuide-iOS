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
               let originalImage = UIImage(data: data) {
                
                // 🟢 1. ย่อขนาดและลบความโปร่งใส (Alpha) ตั้งแต่ตอนเลือกรูปครั้งแรกสุด!
                let targetSize = CGSize(width: 300, height: 300)
                let format = UIGraphicsImageRendererFormat()
                format.opaque = true // บังคับให้พื้นหลังทึบแสง (สีขาว)
                format.scale = 1.0
                
                let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
                let resizedImage = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(CGRect(origin: .zero, size: targetSize))
                    originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                
                // 🟢 2. บีบอัดให้เหลือแค่ไฟล์จิ๋ว (ประมาณ 30-50 KB)
                if let compressedData = resizedImage.jpegData(compressionQuality: 0.6) {
                    self.profileImageData = compressedData
                    self.profileImage = Image(uiImage: resizedImage)
                }
            }
        } catch {
            print("❌ Error loading image: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func saveProfile(context: ModelContext) {
        guard isFormValid else { return }
        
        var savedImageFileName: String? = nil
        
        // 🟢 3. เซฟ "ไฟล์จิ๋ว" ลงเครื่อง (ไม่มีไฟล์ 10MB อีกต่อไป)
        if let imageData = self.profileImageData {
            let fileName = UUID().uuidString + ".jpg"
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent(fileName)
                do {
                    try imageData.write(to: fileURL)
                    savedImageFileName = fileName
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
                UserDefaults.standard.set(self.username, forKey: "current_username")
            } catch {
                print("❌ เซฟข้อมูลไม่สำเร็จ: \(error)")
            }
        }
    }
}
