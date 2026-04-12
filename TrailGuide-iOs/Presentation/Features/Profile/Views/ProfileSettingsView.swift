import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @AppStorage("hasProfile") private var hasProfile: Bool = true
    
    // 🟢 เพิ่มตัวแปร AppStorage สำหรับจำค่าธีมที่ผู้ใช้เลือก (ค่าเริ่มต้นคือตามระบบเครื่อง)
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    @State private var userProfile: UserProfileEntity?
    @State private var showLogoutAlert: Bool = false
    @State private var showEditNameAlert: Bool = false
    @State private var newUsername: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var userRepository: UserRepositoryProtocol?
    
    var body: some View {
        List {
            // --- ส่วนที่ 1: Profile Header ---
            Section {
                VStack(spacing: 16) {
                    if let profile = userProfile {
                        // รูปภาพโปรไฟล์ พร้อมระบบเลือกรูป
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                profileImageView(profile: profile)
                                
                                // ไอคอนกล้อง
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 3))
                                    .shadow(radius: 2)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // ส่วนแสดงชื่อและปุ่มแก้ไข
                        Button(action: {
                            newUsername = profile.username
                            showEditNameAlert = true
                        }) {
                            HStack(spacing: 6) {
                                Text(profile.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    } else {
                        ProgressView().scaleEffect(1.2).padding()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear) // ทำให้พื้นหลังโปร่งใสตามหลักการออกแบบส่วนหัว
            
            // --- 🟢 ส่วนที่ 2: การแสดงผล (Dark / Light Mode) ---
            Section(header: Text("การแสดงผล")) {
                Picker("ธีมแอปพลิเคชัน", selection: $appTheme) {
                    Text("ตามระบบ").tag("system")
                    Text("สว่าง").tag("light")
                    Text("มืด").tag("dark")
                }
                .pickerStyle(.segmented) // ใช้ Segmented Control ตามแบบฉบับ Apple
                .padding(.vertical, 4)
            }
            
            // --- ส่วนที่ 3: ตั้งค่าระบบ ---
            Section(header: Text("การตั้งค่าบัญชี")) {
                Button(role: .destructive, action: { showLogoutAlert = true }) {
                    Label("ออกจากระบบและล้างข้อมูล", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("ตั้งค่า")
        .navigationBarTitleDisplayMode(.inline)
        
        // --- ระบบแจ้งเตือน (Alerts) ---
        .alert("เปลี่ยนชื่อนักเดินทาง", isPresented: $showEditNameAlert) {
            TextField("ชื่อใหม่", text: $newUsername)
            Button("ยกเลิก", role: .cancel) { }
            Button("บันทึก") { saveNewName() }
        }
        .alert("ออกจากระบบ", isPresented: $showLogoutAlert) {
            Button("ยกเลิก", role: .cancel) { }
            Button("ยืนยัน", role: .destructive) { logOut() }
        } message: {
            Text("ข้อมูลทั้งหมดจะถูกลบออกจากเครื่องนี้ถาวร")
        }
        
        .onChange(of: selectedPhotoItem) { _, newValue in
            handlePhotoSelection(newValue)
        }
        .task {
            await fetchProfile()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func profileImageView(profile: UserProfileEntity) -> some View {
        if let fileName = profile.imagePath,
           let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let uiImage = UIImage(contentsOfFile: documentDirectory.appendingPathComponent(fileName).path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 110, height: 110)
                .overlay(
                    Text(String(profile.username.prefix(1)).uppercased())
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.blue)
                )
        }
    }
    
    // MARK: - Logic & Functions
    
    private func fetchProfile() async {
        if let repo = userRepository {
            do {
                self.userProfile = try await repo.getUserProfile()
            } catch {
                print("❌ Error fetching profile: \(error)")
            }
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item, let profile = userProfile else { return }
        Task {
            await handleSelectedImage(item: item, currentProfile: profile)
        }
    }
    
    private func handleSelectedImage(item: PhotosPickerItem, currentProfile: UserProfileEntity) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let newFileName = UUID().uuidString + ".jpg"
                if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentDirectory.appendingPathComponent(newFileName)
                    try data.write(to: fileURL)
                    
                    let updatedProfile = UserProfileEntity(username: currentProfile.username, imagePath: newFileName)
                    if let repo = userRepository {
                        try await repo.saveUserProfile(profile: updatedProfile)
                        await MainActor.run {
                            self.userProfile = updatedProfile
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
                if let repo = userRepository {
                    try await repo.saveUserProfile(profile: updatedProfile)
                    await MainActor.run {
                        self.userProfile = updatedProfile
                    }
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
