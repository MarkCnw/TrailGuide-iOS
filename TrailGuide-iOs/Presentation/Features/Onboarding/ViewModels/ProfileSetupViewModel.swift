import SwiftUI
import PhotosUI
import SwiftData

@Observable
final class ProfileSetupViewModel {
    // MARK: - Properties
    var username: String = ""
    
    // สำหรับจัดการรูปภาพที่ผู้ใช้เลือกจาก Gallery
    var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            Task { await loadProfileImage() }
        }
    }
    
    // รูปภาพที่จะนำไปแสดงผลบน UI
    var profileImage: Image?
    
    // ข้อมูลดิบ (Data) ที่เตรียมส่งต่อให้ UseCase / Repository เพื่อบันทึกลง Database
    private var profileImageData: Data?
    
    // MARK: - Validation
    // เช็คว่าผู้ใช้กรอก Username หรือยัง (บังคับกรอก)
    var isFormValid: Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedUsername.isEmpty
    }
    
    // MARK: - Actions
    @MainActor
    private func loadProfileImage() async {
        guard let item = selectedPhotoItem else { return }
        
        // แปลงไฟล์รูปที่ได้จาก PhotosPicker ให้อยู่ในรูปของ Data
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                self.profileImageData = data
                self.profileImage = Image(uiImage: uiImage)
            }
        } catch {
            print("❌ Error loading image: \(error.localizedDescription)")
            // TODO: จัดการ Error (อาจจะส่ง Error เข้า State ให้ View แสดง Alert)
        }
    }
    
    func saveProfile(context: ModelContext) {
            guard isFormValid else { return }
            
            // 1. สร้างตัวแปรเตรียมรับ Path ของรูปภาพ
            var savedImagePath: String? = nil
            
            // 2. ถ้าผู้ใช้เลือกรูปมา ให้บันทึกไฟล์รูปลงในเครื่อง (Document Directory) ก่อน
            if let imageData = self.profileImageData {
                let fileName = UUID().uuidString + ".jpg" // ตั้งชื่อไฟล์แบบสุ่ม
                if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try imageData.write(to: fileURL) // สั่งเขียนไฟล์ลงเครื่อง
                        savedImagePath = fileURL.path // เก็บ 'ที่อยู่ไฟล์' เอาไว้
                    } catch {
                        print("❌ เซฟรูปภาพไม่สำเร็จ: \(error)")
                    }
                }
            }
            
            // 3. สร้างตัวจัดการฐานข้อมูล
            let repo = UserRepositoryImpl(modelContext: context)
            
            // 4. เอาชื่อ และ "ที่อยู่ไฟล์รูปภาพ" แพ็คใส่กล่อง (🟢 ตรงนี้แหละที่เราเปลี่ยนจาก nil เป็นตัวแปรที่มีรูปจริงๆ)
            let newProfile = UserProfileEntity(username: username, imagePath: savedImagePath)
            
            // 5. สั่งเซฟลงเครื่อง
            Task {
                do {
                    try await repo.saveUserProfile(profile: newProfile)
                    
                    // 6. เซฟสำเร็จแล้วค่อยสั่งสลับหน้า
                    await MainActor.run {
                        UserDefaults.standard.set(true, forKey: "hasProfile")
                    }
                } catch {
                    print("❌ เซฟข้อมูลไม่สำเร็จ: \(error)")
                }
            }
        }
}
