import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @AppStorage("hasProfile") private var hasProfile: Bool = true
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    @EnvironmentObject private var roomViewModel: RoomViewModel
    
    @State private var userProfile: UserProfileEntity?
    @State private var showLogoutAlert: Bool = false
    @State private var showEditNameAlert: Bool = false
    
    @State private var newUsername: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // 🟢 ใช้ UseCases แทน Repository โดยตรง
    let getUserProfileUseCase: GetUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase
    
    var body: some View {
        NavigationStack {
            List {
                // --- ส่วนที่ 1: Profile Header (Hero Image) ---
                Section {
                    VStack {
                        if let profile = userProfile {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    profileImageView(profile: profile)
                                    
                                    // 🟢 HIG: ไอคอนกล้องแบบ Native iOS
                                    Image(systemName: "camera.circle.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .background(Circle().fill(Color(.systemBackground)).frame(width: 28, height: 28))
                                        .offset(x: 2, y: 2)
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 10)
                            
                            Text("แตะเพื่อเปลี่ยนรูปภาพ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                        } else {
                            ProgressView()
                                .frame(width: 110, height: 110)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear) // ทำให้กลืนไปกับพื้นหลัง
                }
                
                // --- ส่วนที่ 2: ข้อมูลส่วนตัว (Personal Info) ---
                if let profile = userProfile {
                    Section(header: Text("ข้อมูลส่วนตัว")) {
                        // 🟢 HIG: การแก้ไขชื่อ ควรเป็นบรรทัดแบบนี้ ผู้ใช้จะเข้าใจทันที
                        Button(action: {
                            newUsername = profile.username
                            showEditNameAlert = true
                        }) {
                            HStack {
                                Text("ชื่อผู้ใช้")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(profile.username)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(.systemGray3))
                            }
                        }
                    }
                }
                
                // --- ส่วนที่ 3: การแสดงผล (Appearance) ---
                Section(header: Text("การแสดงผล")) {
                    Picker("ธีมแอปพลิเคชัน", selection: $appTheme) {
                        Text("ตามระบบ").tag("system")
                        Text("สว่าง").tag("light")
                        Text("มืด").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                
                // --- ส่วนที่ 4: การตั้งค่าบัญชี (Account Actions) ---
                Section {
                    // 🟢 HIG: ปุ่มออกจากระบบควรอยู่ตรงกลาง และเป็นสีแดงชัดเจน
                    Button(action: { showLogoutAlert = true }) {
                        Text("ออกจากระบบและล้างข้อมูล")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("โปรไฟล์")
            .navigationBarTitleDisplayMode(.large) // 🟢 HIG: หน้าหลักควรใช้ Title ตัวใหญ่
            
            // --- ระบบแจ้งเตือน (Alerts) ---
            .alert("เปลี่ยนชื่อผู้ใช้", isPresented: $showEditNameAlert) {
                TextField("ชื่อใหม่", text: $newUsername)
                Button("ยกเลิก", role: .cancel) { }
                Button("บันทึก") { saveNewName() }
            } message: {
                Text("ชื่อนี้จะแสดงให้เพื่อนร่วมทริปเห็นบนเรดาร์")
            }
            .alert("ออกจากระบบ", isPresented: $showLogoutAlert) {
                Button("ยกเลิก", role: .cancel) { }
                Button("ยืนยัน", role: .destructive) { logOut() }
            } message: {
                Text("ข้อมูลทั้งหมดจะถูกลบออกจากเครื่องนี้ถาวร คุณแน่ใจหรือไม่?")
            }
            
            .onChange(of: selectedPhotoItem) { _, newValue in
                handlePhotoSelection(newValue)
            }
            .task {
                await fetchProfile()
            }
        }
    }
    
    // MARK: - Helper Views
        @ViewBuilder
        private func profileImageView(profile: UserProfileEntity) -> some View {
            if let fileName = profile.imagePath,
               let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let filePath = documentDirectory.appendingPathComponent(fileName).path
                
                // 🟢 เทคนิค .preparingThumbnail ย่อรูปก่อนนำมาวาดบนหน้าจอ (ป้องกัน RAM ระเบิด)
                if let uiImage = UIImage(contentsOfFile: filePath)?.preparingThumbnail(of: CGSize(width: 150, height: 150)) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                } else {
                    fallbackProfileIcon(profile: profile)
                }
            } else {
                fallbackProfileIcon(profile: profile)
            }
        }
        
        // 🟢 แยกส่วนตัวอักษรกรณีไม่มีรูปออกมา เพื่อความคลีนของโค้ด
        @ViewBuilder
        private func fallbackProfileIcon(profile: UserProfileEntity) -> some View {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 110, height: 110)
                .overlay(
                    Text(String(profile.username.prefix(1)).uppercased())
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.blue)
                )
        }
    
    // MARK: - Logic & Functions
    private func fetchProfile() async {
        do {
            if let profile = try await getUserProfileUseCase.execute() {
                await MainActor.run { self.userProfile = profile }
            } else {
                await MainActor.run { self.userProfile = UserProfileEntity(username: "นักเดินทาง", imagePath: nil) }
            }
        } catch {
            print("❌ Error fetching profile: \(error)")
            await MainActor.run { self.userProfile = UserProfileEntity(username: "นักเดินทาง", imagePath: nil) }
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item, let profile = userProfile else { return }
        Task { await handleSelectedImage(item: item, currentProfile: profile) }
    }
    
    private func handleSelectedImage(item: PhotosPickerItem, currentProfile: UserProfileEntity) async {
            do {
                // โหลดข้อมูลรูปภาพต้นฉบับจากเครื่อง
                if let data = try await item.loadTransferable(type: Data.self),
                   let originalImage = UIImage(data: data) {
                    
                    // 🟢 1. ย่อขนาด และ "ลบความโปร่งใส (Alpha)" ทิ้ง
                    let targetSize = CGSize(width: 300, height: 300) // ย่อเหลือความละเอียดแค่นี้พอ
                    let format = UIGraphicsImageRendererFormat()
                    format.opaque = true // 🌟 สำคัญมาก: บังคับให้ภาพทึบแสง (แก้ Warning Opaque Image)
                    format.scale = 1.0
                    
                    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
                    let resizedImage = renderer.image { ctx in
                        UIColor.white.set() // เติมพื้นหลังสีขาวทับส่วนที่โปร่งใสไปเลย
                        ctx.fill(CGRect(origin: .zero, size: targetSize))
                        originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
                    }
                    
                    // 🟢 2. บีบอัดเป็น JPEG ขนาดเล็ก (ไฟล์จะเหลือแค่ประมาณ 30-50 KB แทนที่จะเป็น 10 MB)
                    if let compressedData = resizedImage.jpegData(compressionQuality: 0.6) {
                        let newFileName = UUID().uuidString + ".jpg"
                        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileURL = documentDirectory.appendingPathComponent(newFileName)
                            
                            // 🟢 3. เซฟ "ไฟล์จิ๋ว" ลงเครื่องแทน
                            try compressedData.write(to: fileURL)
                            
                            let updatedProfile = UserProfileEntity(username: currentProfile.username, imagePath: newFileName)
                            try await saveUserProfileUseCase.execute(profile: updatedProfile)
                            await MainActor.run {
                                self.userProfile = updatedProfile
                                roomViewModel.updateProfileImage()
                            }
                        }
                    }
                }
            } catch {
                print("❌ Error processing image: \(error.localizedDescription)")
            }
        }
    
    private func saveNewName() {
            let trimmedName = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty, let currentProfile = userProfile else { return }
            
            let updatedProfile = UserProfileEntity(username: trimmedName, imagePath: currentProfile.imagePath)
            Task {
                do {
                    try await saveUserProfileUseCase.execute(profile: updatedProfile)
                    await MainActor.run {
                        self.userProfile = updatedProfile
                        
                        // 🟢 2. เรียกใช้ฟังก์ชันอัปเดตชื่อในระบบเรดาร์
                        roomViewModel.updateUsername(trimmedName)
                    }
                } catch {
                    print("❌ Error saving name: \(error.localizedDescription)")
                }
            }
        }
    
    private func logOut() {
        withAnimation {
            hasProfile = false
        }
    }
}
