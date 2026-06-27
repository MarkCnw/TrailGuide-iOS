import SwiftUI

struct ScanView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var joiningPeer: String? = nil
    @State private var rejectedPeer: String? = nil
    @State private var joinTimer: Timer? = nil

    var body: some View {
        NavigationStack {
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
                    Text("พบหัวหน้าทริป (\(viewModel.availablePeers.count))")
                        .font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                    
                    ScrollView {
                        ForEach(viewModel.availablePeers, id: \.self) { peer in
                            peerRow(for: peer)
                        }
                    }
                }
                Spacer()
            }
            // 🟢 1. เทสีพื้นหลังให้เต็มขอบจอ เพื่อให้สีกลืนกับแอปทั้งหมด
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("สแกนหาเพื่อน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        viewModel.stopBrowsing()
                        dismiss()
                    }
                }
            }
            .onAppear { viewModel.startBrowsing() }
            .onDisappear { 
                viewModel.stopBrowsing()
                if joiningPeer != nil {
                    // 🟢 ผู้ใช้กดยกเลิกขณะกำลังเชื่อมต่อ ล้าง session ทิ้งเพื่อป้องกัน ghost session
                    viewModel.resetSessionForRetry()
                }
                joinTimer?.invalidate()
            }
            .onChange(of: viewModel.connectedPeers) { _, newValue in
                // 🟢 2. เอาการเรียก MemberLobbyView ซ้อนออก เพราะเดี๋ยว RadarPageView สั่งปิด Sheet ให้เอง
                if !newValue.isEmpty {
                    joinTimer?.invalidate()
                    joiningPeer = nil
                    rejectedPeer = nil
                }
            }
            .onChange(of: viewModel.lastConnectionError) { _, errorPeer in
                if let peer = errorPeer, joiningPeer == peer {
                    handleRejection(for: peer)
                }
            }
        }
        // 🟢 3. สำหรับ iOS 16.4+ บังคับให้ตัว Sheet คุมโทนสีให้มิดชิด
        .presentationBackground(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Views
    private func peerRow(for peer: String) -> some View {
        Button(action: {
            viewModel.lastConnectionError = nil
            rejectedPeer = nil
            joiningPeer = peer
            
            viewModel.join(peer: peer)
            
            // 🟢 ตั้งเวลา 15 วินาที ถ้าไม่เชื่อมต่อให้แจ้ง "ล้มเหลว/หมดเวลา"
            joinTimer?.invalidate()
            joinTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
                if self.joiningPeer == peer && self.viewModel.connectedPeers.isEmpty {
                    self.handleRejection(for: peer)
                }
            }
        }) {
            HStack {
                Text(peer.cleanPeerName).font(.headline).foregroundColor(.primary)
                Spacer()
                
                if joiningPeer == peer {
                    ProgressView()
                } else if rejectedPeer == peer {
                    Text("ล้มเหลว") // 🟢 เปลี่ยนคำให้ครอบคลุมทั้ง ถูกปฏิเสธ / หมดเวลา
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                } else {
                    Text("เข้าร่วม")
                        .fontWeight(.bold).foregroundColor(.white)
                        .padding(.horizontal).padding(.vertical, 8)
                        .background(Color.green).cornerRadius(20)
                }
            }
            .padding()
            // 🟢 4. ปรับสีการ์ดให้สว่างขึ้นมานิดนึง จะได้ตัดกับสีพื้นหลังอย่างสวยงาม
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rejectedPeer == peer ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(joiningPeer != nil || rejectedPeer == peer)
        .padding(.horizontal).padding(.bottom, 8)
    }
    
    // MARK: - Logic
    private func handleRejection(for peer: String) {
        joinTimer?.invalidate()
        joiningPeer = nil
        rejectedPeer = peer
        viewModel.lastConnectionError = nil
        
        // 🟢 รีเซ็ต MCSession ทิ้งเพื่อป้องกัน Bug เข้าร่วมไม่ได้ในครั้งหน้า
        viewModel.resetSessionForRetry()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.rejectedPeer == peer {
                self.rejectedPeer = nil
            }
        }
    }
}
