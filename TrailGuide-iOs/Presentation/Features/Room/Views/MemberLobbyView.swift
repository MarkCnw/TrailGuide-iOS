import SwiftUI
import MultipeerConnectivity

struct MemberLobbyView: View {
    @ObservedObject var viewModel: RoomViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.line.dotted.person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                                .symbolEffect(.pulse)
                        }
                        .padding(.top, 8)
                        
                        Text("เชื่อมต่อสำเร็จแล้ว")
                            .font(.headline)
                        Text("กรุณารอหัวหน้าทริปเริ่มต้นการเดินทาง\nโปรดอย่าปิดหน้านี้เพื่อรักษาการเชื่อมต่อ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("เพื่อนร่วมเดินทาง (\(viewModel.allMembers.count))")) {
                    ForEach(viewModel.allMembers, id: \.self) { peer in
                        memberRow(for: peer)
                    }
                }
            }
            .navigationTitle("รอการตอบรับ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ออกจากกลุ่ม", role: .destructive) {
                        viewModel.leaveRoom()
                    }
                }
            }
            // 🟢 ดักจับเมื่อ Host ปิดห้อง หรือหลุด
            .onChange(of: viewModel.sessionManager.connectedPeers) { _, newValue in
                if newValue.isEmpty {
                    viewModel.showHostEndedAlert = true
                    viewModel.leaveRoom()
                }
            }
        }
    }

    @ViewBuilder
    private func memberRow(for peer: MCPeerID) -> some View {
        let isMe = peer == viewModel.sessionManager.myPeerId
        let isHost = viewModel.isHost(peer)
        
        HStack(spacing: 12) {
            ZStack {
                if let uiImage = viewModel.peerImages[peer] {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(isHost ? Color.orange : Color.green, lineWidth: 1.5))
                } else {
                    Circle()
                        .fill(isHost ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Text(String(peer.displayName.prefix(1)).uppercased())
                        .fontWeight(.bold)
                        .foregroundColor(isHost ? .orange : .green)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(peer.displayName)
                        .font(.headline)
                    if isMe { Text("(คุณ)").font(.caption2).foregroundColor(.secondary) }
                }
                Text(isHost ? "หัวหน้าทริป" : "สมาชิก")
                    .font(.caption)
                    .foregroundColor(isHost ? .orange : .secondary)
            }
            
            Spacer()
            
            if isHost {
                Image(systemName: "crown.fill").foregroundColor(.orange).font(.caption)
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
