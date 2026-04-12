import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // --- ส่วนสถานะ ---
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                                .symbolEffect(.variableColor.iterative, options: .repeating)
                        }
                        .padding(.top, 8)

                        Text("รอเพื่อนนักเดินทาง")
                            .font(.headline)

                        Text("แชร์ชื่อกลุ่มให้เพื่อนสแกนหาคุณ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                // --- สมาชิกในกลุ่ม ---
                Section {
                    if viewModel.sessionManager.connectedPeers.isEmpty {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("รอสมาชิกเข้าร่วม...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(viewModel.sessionManager.connectedPeers, id: \.self) { peer in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text(String(peer.displayName.prefix(1)).uppercased())
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(peer.displayName)
                                        .fontWeight(.medium)
                                    Text("เชื่อมต่อแล้ว")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("สมาชิก (\(viewModel.sessionManager.connectedPeers.count))")
                }

                // --- ปุ่มเริ่มเดินทาง ---
                Section {
                    Button(action: {
                        print("🚀 เริ่มการเดินทาง!")
                    }) {
                        HStack {
                            Spacer()
                            Label("เริ่มการเดินทาง", systemImage: "figure.walk")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.sessionManager.connectedPeers.isEmpty ? Color.gray : Color.blue)
                    )
                    .disabled(viewModel.sessionManager.connectedPeers.isEmpty)
                }
            }
            .navigationTitle("ห้องพักคอย")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก", role: .destructive) {
                        viewModel.leaveRoom()
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.startHosting()
            }
            .onDisappear {
                viewModel.stopHosting()
            }
            // ✅ HIG: Alert รับ/ปฏิเสธเมื่อมีคนขอเข้าร่วม
            .alert(
                "\(viewModel.sessionManager.pendingInvitation?.peer.displayName ?? "") ขอเข้าร่วมกลุ่ม",
                isPresented: Binding(
                    get: { viewModel.sessionManager.pendingInvitation != nil },
                    set: { if !$0 { viewModel.declineInvitation() } }
                )
            ) {
                Button("ยอมรับ", action: { viewModel.acceptInvitation() })
                Button("ปฏิเสธ", role: .cancel, action: { viewModel.declineInvitation() })
            } message: {
                Text("ต้องการให้เข้าร่วมทริปของคุณหรือไม่?")
            }
        }
    }
}
