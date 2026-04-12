import SwiftUI
import MultipeerConnectivity

struct MemberLobbyView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 8)

                    Text("เข้าร่วมสำเร็จแล้ว!")
                        .font(.headline)
                    Text("รอหัวหน้าทริปเริ่มการเดินทาง")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("สมาชิกในกลุ่ม") {
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
                        Text(peer.displayName)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("ห้องพักคอย")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("ออกจากกลุ่ม", role: .destructive) {
                    viewModel.leaveRoom()
                    dismiss()
                }
            }
        }
        // ถ้าถูกเตะออกจากกลุ่ม ให้กลับไปหน้าหลัก
        .onChange(of: viewModel.sessionManager.connectedPeers) { _, newValue in
            if newValue.isEmpty {
                viewModel.leaveRoom()
                dismiss()
            }
        }
    }
}
