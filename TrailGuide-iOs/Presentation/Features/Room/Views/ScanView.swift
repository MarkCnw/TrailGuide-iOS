import SwiftUI
import MultipeerConnectivity



struct ScanView: View {
    @StateObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // ส่วนของเรดาร์จำลอง
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
                .padding(.top, 40)
                
                Text("กำลังค้นหาหัวหน้าทริป...")
                    .font(.headline)
                    .padding(.top, 20)
                
                // ลิสต์รายชื่อ Host ที่สแกนเจอ
                List {
                    Section(header: Text("กลุ่มที่พบใกล้ตัว")) {
                        if viewModel.sessionManager.availablePeers.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text(" ค้นหาอยู่...")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.sessionManager.availablePeers, id: \.self) { peer in
                                Button(action: {
                                    viewModel.join(peer: peer)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(peer.displayName)
                                                .fontWeight(.bold)
                                            Text("กดเพื่อขอเข้าร่วมกลุ่ม")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ค้นหากลุ่ม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ปิด") {
                        viewModel.stopBrowsing()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.startBrowsing() // 🟢 เริ่มสแกนทันทีที่เปิดหน้า
            }
            .onDisappear {
                viewModel.stopBrowsing() // 🔴 หยุดสแกนเมื่อปิดหน้า
            }
            // เมื่อเชื่อมต่อสำเร็จ ให้เด้งไปหน้า Lobby (ถ้าต้องการ) หรือจัดการสถานะต่อ
            .onChange(of: viewModel.sessionManager.connectedPeers) { oldValue, newValue in
                if !newValue.isEmpty {
                    // เชื่อมต่อติดแล้ว! (ในที่นี้เราอาจจะจัดการผ่าน State เพื่อเปลี่ยน View)
                }
            }
        }
    }
}
