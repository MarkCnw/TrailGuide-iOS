import SwiftUI

struct RadarPageView: View {
    @EnvironmentObject private var roomViewModel: RoomViewModel
    @State private var viewModel: RadarViewModel
    
    @State private var showScanSheet: Bool = false
    
    init(userRepository: UserRepositoryProtocol?) {
        _viewModel = State(initialValue: RadarViewModel(userRepository: userRepository))
    }
    
    var body: some View {
        Group {
            if roomViewModel.isAdventureStarted {
                TrackingView(viewModel: roomViewModel)
            } else if roomViewModel.amIHost {
                LobbyView(viewModel: roomViewModel)
            } else if !roomViewModel.connectedPeers.isEmpty { // 🟢 แก้ไขบรรทัดนี้
                MemberLobbyView(viewModel: roomViewModel)
            } else {
                roleSelectionView
            }
        }
        .animation(.easeInOut, value: roomViewModel.amIHost)
        .animation(.easeInOut, value: roomViewModel.connectedPeers.isEmpty) // 🟢 แก้ไขบรรทัดนี้
        .animation(.easeInOut, value: roomViewModel.isAdventureStarted)
        .alert(
            "กลุ่มถูกยกเลิกแล้ว",
            isPresented: $roomViewModel.showHostEndedAlert // 🟢 ใช้งานได้แล้ว
        ) {
            Button("ตกลง", role: .cancel) { }
        } message: {
            Text("หัวหน้าทริปได้ทำการยกเลิกกลุ่ม หรือขาดการเชื่อมต่อ")
        }
    }
    
    // MARK: - UI Components
    private var roleSelectionView: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // --- 1. Header Section ---
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("เรดาร์ติดตามเพื่อน")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("เลือกบทบาทของคุณเพื่อเริ่มต้นการเดินทาง")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        miniProfileView
                    }
                    .padding(.top, 24)
                    
                    // --- 2. Cards Section ---
                    HStack(spacing: 16) {
                        roleCard(
                            title: "ตั้งกลุ่ม",
                            subtitle: "สร้างเรดาร์ให้ทีม",
                            icon: "antenna.radiowaves.left.and.right",
                            isPrimary: true,
                            action: { roomViewModel.startHosting() }
                        )
                        
                        roleCard(
                            title: "เข้าร่วม",
                            subtitle: "สแกนหาเพื่อน",
                            icon: "location.viewfinder",
                            isPrimary: false,
                            action: { showScanSheet = true }
                        )
                    }
                    
                    // --- 3. System Status & Quick Tips ---
                    VStack(alignment: .leading, spacing: 20) {
                        Text("ข้อแนะนำก่อนเดินทาง")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        infoBannerView
                        
                        VStack(spacing: 16) {
                            stepRow(icon: "1.circle.fill", text: "ให้หัวหน้าทริปกด 'ตั้งกลุ่ม' เพียง 1 คนเท่านั้น")
                            stepRow(icon: "2.circle.fill", text: "สมาชิกที่เหลือกด 'เข้าร่วม' และสแกนหาหัวหน้าทริป")
                            stepRow(icon: "3.circle.fill", text: "เมื่ออยู่ครบทุกคน หัวหน้าสามารถกดเริ่มเดินทางได้เลย")
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.loadUserData() }
            .sheet(isPresented: $showScanSheet) {
                ScanView(viewModel: roomViewModel)
            }
            .onChange(of: roomViewModel.connectedPeers) { _, peers in
                if !peers.isEmpty && showScanSheet {
                    showScanSheet = false
                }
            }
        }
    }
    
    private var infoBannerView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("เปิด Bluetooth และ Wi-Fi")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("ระบบติดตามแบบออฟไลน์จำเป็นต้องใช้สองสัญญาณนี้ควบคู่กันเพื่อให้เรดาร์ทำงานได้ไกลที่สุด (ไม่จำเป็นต้องมีอินเทอร์เน็ต)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func stepRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
    
    private var miniProfileView: some View {
        Group {
            if let uiImage = viewModel.profileImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(viewModel.username.prefix(1)).uppercased())
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    )
            }
        }
    }
    
    private func roleCard(title: String, subtitle: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? Color.white.opacity(0.2) : Color.green.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(isPrimary ? .white : .green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isPrimary ? .white : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(isPrimary ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: 190, alignment: .topLeading)
            .background(isPrimary ? Color.green : Color(.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .shadow(color: isPrimary ? Color.green.opacity(0.3) : Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(SquishyCardButtonStyle())
    }
}

struct SquishyCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}
