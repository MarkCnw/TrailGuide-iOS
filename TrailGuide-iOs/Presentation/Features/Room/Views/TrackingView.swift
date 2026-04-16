import SwiftUI
import MultipeerConnectivity

struct TrackingView: View {
    @ObservedObject var viewModel: RoomViewModel
    
    @State private var showExitConfirm = false
    @State private var showSOSConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- 1. โซนเรดาร์ ---
                radarSection
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .background(Color(.systemGroupedBackground))
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: { showSOSConfirm = true }) {
                            Image(systemName: "sos.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                
                // --- 2. โซนรายชื่อเพื่อน ---
                List {
                    Section(header: Text("สถานะสมาชิก (\(viewModel.allMembers.count))")) {
                        ForEach(viewModel.allMembers, id: \.self) { peer in
                            memberTrackingRow(for: peer)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("กำลังเดินทาง")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showExitConfirm = true }) {
                        Text(viewModel.amIHost ? "ยุติทริป" : "ออก")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog(
                viewModel.amIHost ? "ยุติการเดินทางและปิดกลุ่ม?" : "คุณต้องการออกจากทริปนี้หรือไม่?",
                isPresented: $showExitConfirm,
                titleVisibility: .visible
            ) {
                Button(viewModel.amIHost ? "ยุติการเดินทาง (ทุกคนจะหลุด)" : "ออกจากทริป", role: .destructive) {
                    viewModel.leaveRoom()
                }
                Button("ยกเลิก", role: .cancel) {}
            }
            .confirmationDialog(
                "ส่งสัญญาณขอความช่วยเหลือ (SOS) ไปยังทุกคนในกลุ่ม?",
                isPresented: $showSOSConfirm,
                titleVisibility: .visible
            ) {
                Button("ส่ง SOS", role: .destructive) {
                    // TODO: ระบบส่ง SOS ในอนาคต
                    print("🚨 ส่ง SOS!")
                }
                Button("ยกเลิก", role: .cancel) {}
            }
        }
        // 🟢 เปิด GPS ทันทีที่หน้า Tracking เด้งขึ้นมา
        .onAppear {
            viewModel.startTrackingLocation()
        }
    }

    // --- Component: เรดาร์จำลอง ---
    private var radarSection: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(edges: .top)
            
            Circle().stroke(Color.green.opacity(0.4), lineWidth: 1)
                .frame(width: 100, height: 100)
            Circle().stroke(Color.green.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)
            Circle().stroke(Color.green.opacity(0.1), lineWidth: 1)
                .frame(width: 300, height: 300)
            
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 150, lineCap: .round))
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
            
            VStack {
                Image(systemName: "location.north.line.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 40))
                    .shadow(color: .green.opacity(0.5), radius: 10)
            }
        }
    }

    // --- Component: แถวแสดงผลสมาชิก ---
    @ViewBuilder
    private func memberTrackingRow(for peer: MCPeerID) -> some View {
        let isMe = peer == viewModel.sessionManager.myPeerId
        let isHost = viewModel.isHost(peer)
        
        // 🟢 ดึงระยะห่าง "ของจริง" จาก GPS
        let distanceText = isMe ? "ออนไลน์" : viewModel.distanceToPeer(peer)
        
        // 🟢 เช็คว่าสัญญาณขาดหายหรือไม่ (ไม่มีพิกัดเพื่อน)
        let isLostSignal = !isMe && viewModel.memberLocations[peer] == nil
        
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

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(peer.displayName).fontWeight(.medium)
                    if isMe { Text("(คุณ)").font(.caption2).foregroundColor(.secondary) }
                }
                
                HStack {
                    Circle()
                        // 🟢 เปลี่ยนสีตามสถานะ: เขียว(ปกติ), ดำ/เทา(หาสัญญาณไม่เจอ)
                        .fill(isMe ? Color.green : (isLostSignal ? Color.gray : Color.green))
                        .frame(width: 8, height: 8)
                    
                    Text(distanceText)
                        .font(.caption)
                        .foregroundColor(isLostSignal ? .secondary : .primary)
                }
            }
            
            Spacer()
            
            // 🟢 ไอคอนความแรงสัญญาณ
            Image(systemName: isMe ? "wifi" : (isLostSignal ? "wifi.slash" : "wifi"))
                .foregroundColor(isMe ? .green : (isLostSignal ? .gray : .green))
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
