import SwiftUI
import MultipeerConnectivity


struct ScanView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var joiningPeer: MCPeerID? = nil
    @State private var rejectedPeer: MCPeerID? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.sessionManager.connectedPeers.isEmpty {
                    VStack(spacing: 32) {
                        Spacer()
                        ZStack {
                            Circle().stroke(Color.green.opacity(0.3), lineWidth: 2).frame(width: 200, height: 200)
                            Image(systemName: "location.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .symbolEffect(.pulse.byLayer, options: .repeating)
                        }
                        
                        Text("กำลังค้นหาหัวหน้าทริป...").font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("พบหัวหน้าทริป (\(viewModel.sessionManager.availablePeers.count))")
                                .font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                            
                            ScrollView {
                                ForEach(viewModel.sessionManager.availablePeers, id: \.self) { peer in
                                    peerRow(for: peer)
                                }
                            }
                        }
                        Spacer()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("ยกเลิก") {
                                viewModel.stopBrowsing()
                                dismiss()
                            }
                        }
                    }
                } else {
                    MemberLobbyView(viewModel: viewModel)
                }
            }
            .onAppear { viewModel.startBrowsing() }
            .onDisappear { viewModel.stopBrowsing() }
            
            // 🟢 ดักจับเมื่อเชื่อมต่อสำเร็จ
            .onChange(of: viewModel.sessionManager.connectedPeers) { _, newValue in
                if !newValue.isEmpty {
                    joiningPeer = nil
                    rejectedPeer = nil
                }
            }
            
            // 🟢 ดักจับเมื่อถูกปฏิเสธ (เพื่อไม่ให้ UI ค้าง)
            .onChange(of: viewModel.sessionManager.lastConnectionError) { _, errorPeer in
                if let peer = errorPeer, joiningPeer == peer {
                    handleRejection(for: peer)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func peerRow(for peer: MCPeerID) -> some View {
        Button(action: {
            // 🟢 ล้างคราบสถานะเก่าทิ้งก่อนกด Join รอบใหม่เสมอ
            viewModel.sessionManager.lastConnectionError = nil
            rejectedPeer = nil
            joiningPeer = peer
            
            viewModel.join(peer: peer)
        }) {
            HStack {
                Text(peer.displayName).font(.headline).foregroundColor(.primary)
                Spacer()
                
                if joiningPeer == peer {
                    ProgressView()
                } else if rejectedPeer == peer {
                    // แจ้งเตือนเมื่อถูก Host ปฏิเสธ
                    Text("ถูกปฏิเสธ")
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                } else {
                    Text("เข้าร่วม")
                        .fontWeight(.bold).foregroundColor(.white)
                        .padding(.horizontal).padding(.vertical, 8)
                        .background(Color.green).cornerRadius(20)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rejectedPeer == peer ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(joiningPeer != nil || rejectedPeer == peer) // ป้องกันการกดย้ำๆ
        .padding(.horizontal).padding(.bottom, 8)
    }
    
    // MARK: - Logic
    private func handleRejection(for peer: MCPeerID) {
        joiningPeer = nil
        rejectedPeer = peer
        
        // ล้างค่า Error ทันทีเพื่อให้กดขอเข้าร่วมใหม่ได้
        viewModel.sessionManager.lastConnectionError = nil
        
        // ให้ป้าย "ถูกปฏิเสธ" หายไปเองใน 3 วินาที
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.rejectedPeer == peer {
                self.rejectedPeer = nil
            }
        }
    }
}
