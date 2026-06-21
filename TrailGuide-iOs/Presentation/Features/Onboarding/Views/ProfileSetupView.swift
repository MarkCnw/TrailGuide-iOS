import SwiftUI
import PhotosUI
import SwiftData

struct ProfileSetupView: View {
    @State private var viewModel = ProfileSetupViewModel()
    @Environment(\.modelContext) private var modelContext
    
    // 🟢 HIG: ใช้ FocusState เพื่อจัดการ Keyboard
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            // 🟢 HIG: ใช้ ScrollView เพื่อป้องกัน Keyboard บังปุ่มกดยืนยันด้านล่าง
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // --- 1. ส่วนหัว (Header) ---
                    VStack(spacing: 12) {
                        Text("สร้างโปรไฟล์")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // 🟢 HIG: เพิ่มคำอธิบายสั้นๆ ให้ผู้ใช้เข้าใจถึงประโยชน์ของการตั้งโปรไฟล์
                        Text("เพิ่มรูปภาพและชื่อของคุณ\nเพื่อให้เพื่อนร่วมทริปจดจำคุณได้ง่ายขึ้น")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // --- 2. ส่วนเลือกรูปโปรไฟล์ ---
                    profileImagePickerSection
                    
                    // --- 3. ส่วนกรอกชื่อผู้ใช้ ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ชื่อผู้ใช้")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        HStack {
                            TextField("ชื่อที่เพื่อนๆ จะเห็น...", text: $viewModel.username)
                                .focused($isTextFieldFocused)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.done) // 🟢 เปลี่ยนปุ่ม Return เป็น Done
                                .onSubmit { isTextFieldFocused = false } // กด Done แล้วซ่อนคีย์บอร์ด
                            
                            // 🟢 HIG: ปุ่ม Clear ข้อความแบบรวดเร็ว
                            if !viewModel.username.isEmpty {
                                Button(action: { viewModel.username = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.systemGray3))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground)) // สีขาวใน Light Mode, สีดำใน Dark Mode
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                    
                    // --- 4. ปุ่มยืนยัน ---
                    Button(action: {
                        isTextFieldFocused = false
                        viewModel.saveProfile(context: modelContext)
                    }) {
                        Text("เข้าสู่ระบบ TrailGuide")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    // 🟢 HIG: ใช้ Native Button Style (ปุ่มจะกลายเป็นสีเทาอัตโนมัติเมื่อ Disabled)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                    .disabled(!viewModel.isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                }
            }
            // 🟢 HIG: สีพื้นหลังสำหรับหน้ารับข้อมูล
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            // 🟢 แตะพื้นที่ว่างเพื่อซ่อน Keyboard
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    // MARK: - UI Components
    private var profileImagePickerSection: some View {
        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
            ZStack {
                if let image = viewModel.profileImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 4))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 130, height: 130)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                // Badge วงกลมเครื่องหมายบวก
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green) // คุมโทนสีให้เป็นสีเขียว TrailGuide
                    .background(Circle().fill(Color(.systemBackground)))
                    .offset(x: 45, y: 45)
            }
        }
        .padding(.vertical, 16)
        // 🟢 HIG: ให้ Feedback เวลาผู้ใช้นิ้วแตะที่รูปภาพ
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileSetupView()
}
