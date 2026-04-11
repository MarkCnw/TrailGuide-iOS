import SwiftUI
import PhotosUI
import SwiftData

struct ProfileSetupView: View {
    // ผูก ViewModel เข้ากับ View
    @State private var viewModel = ProfileSetupViewModel()
    @Environment(\.modelContext) private var modelContext // 🟢 1. เพิ่มบรรทัดนี้
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                // 1. ส่วนหัว (Header)
                Text("สร้างโปรไฟล์นักเดินทาง")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // 2. ส่วนเลือกรูปโปรไฟล์ (ไม่บังคับ)
                profileImagePickerSection
                
                // 3. ส่วนกรอกชื่อผู้ใช้ (บังคับ)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ชื่อผู้ใช้ (Username) *")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("กรอกชื่อที่เพื่อนๆ จะเห็น...", text: $viewModel.username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 4. ปุ่มยืนยัน
                Button(action: {
                    viewModel.saveProfile(context: modelContext) // 🟢 2. ส่ง context ไปให้เซฟ
                }) {
                    Text("เข้าสู่ระบบ TrailGuide")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFormValid ? Color.blue : Color.gray.opacity(0.5))
                        .cornerRadius(16)
                }
                .disabled(!viewModel.isFormValid) // ปุ่มจะกดไม่ได้ถ้ายังไม่กรอกชื่อ
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - UI Components
    
    // แยกโค้ดส่วนเลือกรูปภาพออกมาให้ดูสะอาดตา
    private var profileImagePickerSection: some View {
        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
            ZStack {
                // ถ้ามีรูปแล้ว ให้แสดงรูป
                if let image = viewModel.profileImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                } else {
                    // ถ้ายังไม่มีรูป ให้แสดง Placeholder
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                
                // ไอคอนเครื่องหมายบวก (Badge)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white))
                    .offset(x: 40, y: 40)
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Preview
#Preview {
    ProfileSetupView()
}
