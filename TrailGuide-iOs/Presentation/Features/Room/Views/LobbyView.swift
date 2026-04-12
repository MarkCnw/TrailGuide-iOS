import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @StateObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // ส่วนหัวแสดงสถานะ
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    
                    Text("กำลังเปิดห้องพักคอย...")
                        .font(.headline)
                    
                    Text("รอเพื่อนนักเดินทางกดเข้าร่วมกลุ่มของคุณ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 30)
                
                // รายชื่อสมาชิกในกลุ่ม
                List {
                    Section(header: Text("สมาชิกในกลุ่ม (\(viewModel.sessionManager.connectedPeers.count))")) {
                        if viewModel.sessionManager.connectedPeers.isEmpty {
                            Text("ยังไม่มีใครเข้าร่วม...")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(viewModel.sessionManager.connectedPeers, id: \.self) { peer in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(peer.displayName)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("เชื่อมต่อแล้ว")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                
                // ปุ่มเริ่มเดินทาง
                Button(action: {
                    // TODO: นำทางไปหน้าแผนที่และการติดตามตัว
                    print("🚀 เริ่มการเดินทาง!")
                }) {
                    Text("เริ่มการเดินทาง")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.sessionManager.connectedPeers.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.sessionManager.connectedPeers.isEmpty)
                .padding()
            }
            .navigationTitle("ห้องพักคอย")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        viewModel.leaveRoom()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.startHosting() // 🟢 เริ่มปล่อยสัญญาณทันทีที่เปิดหน้านี้
            }
            .onDisappear {
                viewModel.stopHosting() // 🔴 หยุดปล่อยสัญญาณเมื่อปิดหน้า
            }
        }
    }
}
