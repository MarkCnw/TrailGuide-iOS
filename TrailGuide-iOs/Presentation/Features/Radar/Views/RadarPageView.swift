import SwiftUI

struct RadarPageView: View {
    @State private var viewModel: RadarViewModel
    
    // 🟢 ประกาศตัวแปรรับ RoomViewModel โดยยังไม่ใส่ค่าเริ่มต้นตรงนี้
    @StateObject private var roomViewModel: RoomViewModel
    
    // ตัวแปรควบคุมการเปิดหน้าจอ
    @State private var navigateToLobby: Bool = false
    @State private var showScanSheet: Bool = false
    @State private var showLobby = false
    @State private var showScan = false
    
    init(userRepository: UserRepositoryProtocol?) {
        _viewModel = State(initialValue: RadarViewModel(userRepository: userRepository))
        // 🟢 เอา userRepository ที่ได้รับมาตอนเปิดหน้า โยนเข้าไปสร้าง RoomViewModel
        _roomViewModel = StateObject(wrappedValue: RoomViewModel(userRepository: userRepository!))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 32) {
                    
                    // --- 1. Header (ชื่อและรูปโปรไฟล์ระนาบเดียวกัน) ---
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("เรดาร์ติดตามเพื่อน")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                            
                            Text("เลือกบทบาทของคุณเพื่อเริ่มต้น")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        miniProfileView
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // --- 2. Role Selection (แนวนอน 2 ปุ่มติดกัน) ---
                    HStack(spacing: 16) {
                        roleButton(
                            title: "ตั้งกลุ่ม\n(Host)",
                            subtitle: "สร้างวงเรดาร์ให้ทีม",
                            icon: "antenna.radiowaves.left.and.right",
                            isPrimary: true,
                            action: { navigateToLobby = true }
                        )
                        
                        roleButton(
                            title: "เข้าร่วม\n(Member)",
                            subtitle: "สแกนหาเพื่อนในทีม",
                            icon: "location.viewfinder",
                            isPrimary: false,
                            action: { showScanSheet = true }
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadUserData()
            }
            // --- 3. ระบบเชื่อมต่อหน้าจอ (Navigation & Sheet) ---
            .navigationDestination(isPresented: $navigateToLobby) {
                // 🟢 เปลี่ยนมาส่ง roomViewModel ให้หน้า LobbyView แทน
                LobbyView(viewModel: roomViewModel)
            }
            .sheet(isPresented: $showScanSheet) {
                // 🟢 เปลี่ยนมาส่ง roomViewModel ให้หน้า ScanView แทน
                ScanView(viewModel: roomViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var miniProfileView: some View {
        Group {
            if let uiImage = viewModel.profileImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.green.opacity(0.4), lineWidth: 1.5))
            } else {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 55, height: 55)
                    .overlay(
                        Text(String(viewModel.username.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.green)
                    )
            }
        }
    }
    
    private func roleButton(title: String, subtitle: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? Color.green : Color.green.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isPrimary ? .white : .green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: 180, alignment: .topLeading)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPrimary ? Color.green.opacity(0.4) : Color.green.opacity(0.15), lineWidth: 1.5)
            )
            .shadow(color: Color.green.opacity(isPrimary ? 0.15 : 0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
