import SwiftUI
import MultipeerConnectivity

struct ScanView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var navigateToLobby = false
    @State private var isWaitingForHost = false

    var body: some View {
        NavigationStack {
            List {
                // --- ส่วนเรดาร์ ---
                Section {
                    radarHeaderView
                }
                .listRowBackground(Color.clear)

                // --- รายชื่อ Host ---
                if !isWaitingForHost {
                    Section(header: Text("กลุ่มที่พบใกล้ตัว")) {
                        if viewModel.sessionManager.availablePeers.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("ค้นหาอยู่...")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(viewModel.sessionManager.availablePeers, id: \.self) { peer in
                                PeerRowView(peer: peer) {
                                    viewModel.join(peer: peer)
                                    isWaitingForHost = true
                                }
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
                viewModel.startBrowsing()
            }
            .onDisappear {
                if !navigateToLobby {
                    viewModel.stopBrowsing()
                }
            }
            .onChange(of: viewModel.sessionManager.connectedPeers) { _, newValue in
                if !newValue.isEmpty {
                    navigateToLobby = true
                }
            }
            .navigationDestination(isPresented: $navigateToLobby) {
                MemberLobbyView(viewModel: viewModel)
            }
        }
    }

    // --- Subviews ---
    private var radarHeaderView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 1)
                    .frame(width: 160, height: 160)
                Circle()
                    .stroke(Color.green.opacity(0.25), lineWidth: 1)
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
                    .frame(width: 60, height: 60)
                Image(systemName: isWaitingForHost ? "clock.arrow.circlepath" : "location.magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            .padding(.top, 8)

            Text(isWaitingForHost ? "รอหัวหน้าทริปยืนยัน..." : "กำลังค้นหากลุ่มใกล้เคียง")
                .font(.headline)

            Text(isWaitingForHost ? "หัวหน้าทริปกำลังพิจารณาคำขอของคุณ" : "กลุ่มที่เปิดรับสมาชิกจะปรากฏด้านล่าง")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct PeerRowView: View {
    let peer: MCPeerID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                        .foregroundColor(.primary)
                    Text("กดเพื่อขอเข้าร่วม")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 4)
        }
    }
}
