import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // พื้นหลังจางๆ
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // ตัวกล่อง Alert
            VStack(spacing: 20) {
                Text(title).font(.headline)
                Text(message).font(.subheadline)
                
                VStack(spacing: 10) {
                    // ปุ่มบันทึก (สีเขียวของคุณ)
                    Button("บันทึก") {
                        onConfirm()
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green) // สีเขียวที่ต้องการ
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // ปุ่มทิ้งเส้นทาง (สีแดง)
                    Button("ทิ้งเส้นทาง") {
                        // เพิ่ม logic ทิ้งเส้นทางตรงนี้
                        isPresented = false
                    }
                    .foregroundColor(.red)
                    
                    // ปุ่มยกเลิก (สีเทา)
                    Button("ยกเลิก") {
                        isPresented = false
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .padding(40)
        }
    }
}
