import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @ObservedObject var viewModel: RoomViewModel
    @State private var showCancelConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.blue.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 36)).foregroundColor(.blue)
                                .symbolEffect(.variableColor.iterative, options: .repeating)
                        }
                        .padding(.top, 8)
                        
                        Text("กำลังรอเพื่อนนักเดินทาง").font(.headline)
                        Text("เพื่อนในระยะใกล้สามารถสแกนพบกลุ่มของคุณได้")
                            .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("สมาชิกในกลุ่ม (\(viewModel.allMembers.count))")) {
                    ForEach(viewModel.allMembers, id: \.self) { peer in
                        memberRow(for: peer)
                    }
                }

                Section {
                    Button(action: { viewModel.startAdventure() }) {
                        HStack {
                            Spacer()
                            Label("เริ่มออกเดินทาง", systemImage: "figure.walk")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(viewModel.connectedPeers.isEmpty ? Color.gray : Color.green))
                    .disabled(viewModel.connectedPeers.isEmpty)
                } footer: {
                    if viewModel.connectedPeers.isEmpty {
                        Text("ต้องมีสมาชิกอย่างน้อย 1 คนเพื่อเริ่มการเดินทาง")
                    }
                }
            }
            .navigationTitle("การเตรียมความพร้อม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิกกลุ่ม", role: .destructive) { showCancelConfirm = true }
                }
            }
            .confirmationDialog("คุณแน่ใจหรือไม่ที่จะยกเลิกกลุ่ม?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("ยกเลิกกลุ่ม (สมาชิกทั้งหมดจะหลุด)", role: .destructive) { viewModel.leaveRoom(source: "LobbyView - ยกเลิกกลุ่ม") }
                Button("ปิด", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private func memberRow(for peer: MCPeerID) -> some View {
        let isMe = peer == viewModel.allMembers.first
        let isHost = viewModel.isHost(peer)
        
        HStack(spacing: 12) {
            ZStack {
                // 🟢 แก้จุดนี้: ดึงรูปจาก TrailMember แทน Dictionary เก่า
                if let uiImage = viewModel.trailMembers[peer]?.profileImage {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 40, height: 40)
                        .clipShape(Circle()).overlay(Circle().stroke(isHost ? Color.orange : Color.green, lineWidth: 1.5))
                } else {
                    Circle().fill(isHost ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)).frame(width: 40, height: 40)
                    Text(String(peer.displayName.prefix(1)).uppercased())
                        .fontWeight(.bold).foregroundColor(isHost ? .orange : .green)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(peer.displayName).font(.headline)
                    if isMe { Text("(คุณ)").font(.caption2).foregroundColor(.secondary) }
                }
                Text(isHost ? "หัวหน้าทริป" : "สมาชิก").font(.caption).foregroundColor(isHost ? .orange : .secondary)
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
