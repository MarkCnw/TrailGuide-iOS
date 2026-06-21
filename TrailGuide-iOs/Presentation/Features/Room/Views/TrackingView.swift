import SwiftUI
import MultipeerConnectivity
import CoreLocation
import Combine

struct TrackingView: View {
    @ObservedObject var viewModel: RoomViewModel
    
    @State private var showExitConfirm = false
    @State private var showHostEndConfirm = false
    @State private var currentTime = Date()
    
    // สถานะสำหรับปุ่ม SOS แบบกดค้าง
    @State private var isPressingSOS = false
    @State private var sosProgress: CGFloat = 0.0
    @State private var sosTimer: Timer?
    @State private var showSOSTriggeredAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // 🟢 Reconnection Banner
                    if viewModel.isReconnecting {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("กำลังเชื่อมต่อใหม่...")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // --- 1. โซนเรดาร์ ---
                    radarSection
                        .frame(height: UIScreen.main.bounds.height * 0.45)
                        .background(Color(.systemGroupedBackground))
                    
                    // --- 2. โซนรายชื่อเพื่อน ---
                    List {
                        // 🟢 ดรอปคนแรกทิ้ง (เพราะคนแรกคือตัวเองเสมอ ตามที่เรียงไว้ใน allMembers)
                        let companions = Array(viewModel.allMembers.dropFirst())
                        Section(header: Text("เพื่อนร่วมทริป (\(companions.count))")) {
                            ForEach(companions, id: \.self) { peer in
                                memberTrackingRow(for: peer)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                // 🔴 ปุ่ม SOS Floating (อยู่ล่างกลาง) 🔴
                VStack {
                    Spacer()
                    sosFloatingButton
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("กำลังเดินทาง")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.amIHost {
                        Button(action: { showHostEndConfirm = true }) {
                            Text("สิ้นสุดทริป").fontWeight(.bold).foregroundColor(.red)
                        }
                    } else {
                        Button(action: { showExitConfirm = true }) {
                            Text("ออกจากการติดตาม")
                        }
                    }
                }
            }
            .confirmationDialog(
                "ต้องการสิ้นสุดทริปสำหรับทุกคนใช่หรือไม่?",
                isPresented: $showHostEndConfirm,
                titleVisibility: .visible
            ) {
                Button("สิ้นสุดทริป", role: .destructive) { viewModel.endAdventure() }
                Button("ยกเลิก", role: .cancel) {}
            } message: { Text("เมื่อสิ้นสุดทริป การติดตามพิกัดของทุกคนจะหยุดลงทันที") }
            .confirmationDialog(
                "คุณต้องการออกจากการติดตามหรือไม่?",
                isPresented: $showExitConfirm,
                titleVisibility: .visible
            ) {
                Button("ออกจากปาร์ตี้", role: .destructive) { viewModel.leaveRoom(source: "TrackingView - ออกจากปาร์ตี้") }
                Button("ยกเลิก", role: .cancel) {}
            } message: { Text("หากคุณออก คุณจะไม่ได้รับข้อมูลพิกัดเพื่อนๆ อีก") }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                self.currentTime = Date()
            }
            .alert(isPresented: $showSOSTriggeredAlert) {
                Alert(
                    title: Text("🚨 สัญญาณ SOS ส่งออกแล้ว"),
                    message: Text("เพื่อนร่วมทริปได้รับพิกัดฉุกเฉินของคุณแล้ว"),
                    dismissButton: .default(Text("ตกลง"))
                )
            }
            .alert(isPresented: $viewModel.showSOSReceivedAlert) {
                Alert(
                    title: Text("🚨 สัญญาณฉุกเฉิน!"),
                    message: Text("คุณ \(viewModel.latestSOSPeerName) ต้องการความช่วยเหลือด่วน!"),
                    dismissButton: .default(Text("รับทราบ"))
                )
            }
            .sheet(isPresented: $viewModel.showTripSummary) {
                TripSummaryView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.startTrackingLocation()
        }
    }

    // --- Component: เรดาร์จำลอง ---
    private var radarSection: some View {
        GeometryReader { geometry in
            let maxRadius = max(min(geometry.size.width, geometry.size.height) / 2 - 20, 0)
            
            // 🟢 ดึงข้อมูลของตัวเอง (คนแรกใน List เสมอ)
            let myPeerId = viewModel.allMembers.first
            let myHeading = myPeerId.flatMap { viewModel.trailMembers[$0]?.heading } ?? 0
            
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea(edges: .top)
                
                // --- เรดาร์รอบนอก ---
                ZStack {
                    Circle().stroke(Color.green.opacity(0.5), lineWidth: 1).frame(width: maxRadius * 0.5, height: maxRadius * 0.5)
                    Circle().stroke(Color.green.opacity(0.3), lineWidth: 1).frame(width: maxRadius * 1.0, height: maxRadius * 1.0)
                    Circle().stroke(Color.green.opacity(0.1), lineWidth: 1).frame(width: maxRadius * 1.5, height: maxRadius * 1.5)
                    
                    VStack {
                        Text("N").font(.caption).fontWeight(.bold).foregroundColor(.red)
                        Spacer()
                    }
                    .frame(height: maxRadius * 1.6)
                }
                .rotationEffect(.degrees(-myHeading))
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: myHeading)

                // --- จุดของผู้ใช้เอง (ศูนย์กลาง) ---
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: "location.north.line.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                        .shadow(color: .blue.opacity(0.5), radius: 5)
                }

                // --- วาดจุดเพื่อน ร่วมทริป บนเรดาร์ ---
                if let myId = myPeerId, let myLocCoord = viewModel.trailMembers[myId]?.location {
                    let myLoc = CLLocation(latitude: myLocCoord.latitude, longitude: myLocCoord.longitude)
                    
                    ForEach(Array(viewModel.allMembers.dropFirst()), id: \.self) { peer in
                        if let peerLocCoord = viewModel.trailMembers[peer]?.location {
                            let peerLoc = CLLocation(latitude: peerLocCoord.latitude, longitude: peerLocCoord.longitude)
                            let distance = myLoc.distance(from: peerLoc)
                            
                            let bearing = LocationCalculator.calculateBearing(
                                lat1: myLocCoord.latitude, lon1: myLocCoord.longitude,
                                lat2: peerLocCoord.latitude, lon2: peerLocCoord.longitude)
                            
                            let relativeAngle = bearing - myHeading
                            let maxDisplayDistance: Double = 150.0
                            let radiusRatio = min(distance / maxDisplayDistance, 1.0)
                            let actualRadius = maxRadius * 0.75 * radiusRatio
                            
                            let angleRad = (relativeAngle - 90) * .pi / 180
                            let xOffset = actualRadius * cos(angleRad)
                            let yOffset = actualRadius * sin(angleRad)
                            
                            let lastSeenDate = viewModel.trailMembers[peer]?.lastSeen
                            let isDisconnected = lastSeenDate.map { self.currentTime.timeIntervalSince($0) > 30 } ?? false
                            let isSOSActive = viewModel.sosActivePeers.contains(peer) // 🟢 ตรวจสอบสถานะ SOS
                            
                            ZStack {
                                // 🟢 ไฮไลต์สีแดงแบบกระพริบบนเรดาร์สำหรับคนที่กำลังขอความช่วยเหลือ
                                if isSOSActive {
                                    Circle()
                                        .fill(Color.red.opacity(0.5))
                                        .frame(width: 50, height: 50)
                                        .scaleEffect(1.3)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSOSActive)
                                }
                                
                                if let uiImage = viewModel.trailMembers[peer]?.profileImage {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(isSOSActive ? Color.red : Color.white, lineWidth: isSOSActive ? 3 : 2))
                                        .shadow(radius: 3)
                                        .grayscale(isDisconnected ? 0.99 : 0.0)
                                        .opacity(isDisconnected ? 0.6 : 1.0)
                                } else {
                                    Circle().fill(isDisconnected ? Color.gray : (isSOSActive ? Color.red : Color.orange)).frame(width: 36, height: 36)
                                        .shadow(radius: 3)
                                    Text(String(peer.displayName.prefix(1)).uppercased())
                                        .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                }
                                
                                if let peerHeading = viewModel.trailMembers[peer]?.heading, !isDisconnected {
                                    VStack {
                                        Image(systemName: "triangle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(Color.red)
                                            .padding(.bottom, 36)
                                    }
                                    .rotationEffect(.degrees(peerHeading - myHeading))
                                }
                            }
                            .offset(x: xOffset, y: yOffset)
                            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: relativeAngle)
                            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: actualRadius)
                        }
                    }
                }
            }
        }
    }

    private func getCoordText(peer: MCPeerID, isDisconnected: Bool, secondsSinceLastSeen: TimeInterval) -> String {
        let coordinate = viewModel.trailMembers[peer]?.location
        if isDisconnected {
            let minutes = Int(secondsSinceLastSeen / 60)
            if minutes > 0 {
                return "ขาดการติดต่อ (ดูล่าสุดเมื่อ \(minutes) นาทีที่แล้ว)"
            } else {
                return "ขาดการติดต่อ (ดูล่าสุดเมื่อ \(Int(secondsSinceLastSeen)) วิที่แล้ว)"
            }
        } else {
            return coordinate != nil ? String(format: "พิกัด: %.4f, %.4f", coordinate!.latitude, coordinate!.longitude) : "กำลังรอพิกัด GPS..."
        }
    }

    // --- Component: แถวแสดงผลสมาชิก ---
    @ViewBuilder
    private func memberTrackingRow(for peer: MCPeerID) -> some View {
        let isHost = viewModel.isHost(peer)
        let lastSeenDate = viewModel.trailMembers[peer]?.lastSeen
        let secondsSinceLastSeen = lastSeenDate != nil ? currentTime.timeIntervalSince(lastSeenDate!) : 0
        let isDisconnected = secondsSinceLastSeen > 30 || viewModel.trailMembers[peer]?.location == nil
        
        let distanceText = isDisconnected
            ? getCoordText(peer: peer, isDisconnected: true, secondsSinceLastSeen: secondsSinceLastSeen)
            : viewModel.distanceToPeer(peer)
        
        let coordText = isDisconnected
            ? ""
            : getCoordText(peer: peer, isDisconnected: false, secondsSinceLastSeen: secondsSinceLastSeen)
            
        let isSOSActive = viewModel.sosActivePeers.contains(peer) // 🟢 ตรวจสอบสถานะ SOS
        
        HStack(spacing: 12) {
            ZStack {
                if let uiImage = viewModel.trailMembers[peer]?.profileImage {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(isSOSActive ? Color.red : (isHost ? Color.orange : Color.green), lineWidth: isSOSActive ? 3 : 2))
                        .grayscale(isDisconnected ? 0.99 : 0.0)
                        .opacity(isDisconnected ? 0.6 : 1.0)
                } else {
                    Circle()
                        .fill(isDisconnected ? Color.gray.opacity(0.15) : (isSOSActive ? Color.red.opacity(0.15) : (isHost ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))))
                        .frame(width: 44, height: 44)
                    Text(String(peer.displayName.prefix(1)).uppercased())
                        .fontWeight(.bold)
                        .foregroundColor(isDisconnected ? .gray : (isSOSActive ? .red : (isHost ? .orange : .green)))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(peer.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(isDisconnected ? .secondary : (isSOSActive ? .red : .primary))
                    
                    if isSOSActive {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isDisconnected ? Color.gray : Color.blue)
                        .frame(width: 6, height: 6)
                    
                    Text(distanceText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isDisconnected ? .red : .primary)
                }
                
                if !isDisconnected {
                    Text(coordText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !isDisconnected, let pointerAngle = viewModel.bearingToPeer(peer) {
                VStack(spacing: 4) {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(pointerAngle))
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .animation(.easeInOut(duration: 0.3), value: pointerAngle)
                    Text(viewModel.distanceToPeer(peer))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 65)
            } else {
                Image(systemName: isDisconnected ? "wifi.slash" : "wifi")
                    .foregroundColor(isDisconnected ? .gray : .green)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
        .background(isSOSActive ? Color.red.opacity(0.05) : Color.clear)
    }
    
    // --- Component: ปุ่ม SOS (Long Press) ---
    private var sosFloatingButton: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground).opacity(0.8))
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            Circle()
                .trim(from: 0, to: sosProgress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)
            
            Circle()
                .fill(isPressingSOS ? Color.red.opacity(0.8) : Color.red)
                .frame(width: 64, height: 64)
                .shadow(color: .red.opacity(0.4), radius: 5)
            
            Text("SOS")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressingSOS { startSOSTimer() }
                }
                .onEnded { _ in
                    if sosProgress < 1.0 { cancelSOSTimer() }
                }
        )
    }
    
    private func startSOSTimer() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isPressingSOS = true
        sosProgress = 0.0
        
        sosTimer?.invalidate()
        sosTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            if self.sosProgress >= 1.0 {
                self.sosTimer?.invalidate()
                self.triggerSOS()
            } else {
                withAnimation(.linear(duration: 0.02)) {
                    self.sosProgress += (0.02 / 3.0)
                }
            }
        }
    }
    
    private func cancelSOSTimer() {
        isPressingSOS = false
        sosTimer?.invalidate()
        sosTimer = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            sosProgress = 0.0
        }
    }
    
    private func triggerSOS() {
        isPressingSOS = false
        withAnimation { sosProgress = 0.0 }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        viewModel.sendSOS()
        showSOSTriggeredAlert = true
    }
}

// MARK: - Post-Trip Summary View
struct TripSummaryView: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "flag.checkered.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.4), radius: 20, y: 10)
            
            Text("การเดินทางสำเร็จลุล่วง!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let start = viewModel.tripStartTime {
                let duration = Date().timeIntervalSince(start)
                let hours = Int(duration) / 3600
                let minutes = (Int(duration) % 3600) / 60
                let seconds = Int(duration) % 60
                
                VStack(spacing: 12) {
                    Text("ยินดีด้วย! คุณเดินป่าร่วมกันเป็นเวลา")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline) {
                        if hours > 0 {
                            Text("\(hours)").font(.system(size: 40, weight: .black))
                            Text("ชม.").font(.headline)
                        }
                        if minutes > 0 || hours > 0 {
                            Text("\(minutes)").font(.system(size: 40, weight: .black))
                            Text("นาที").font(.headline)
                        }
                        Text("\(seconds)").font(.system(size: 40, weight: .black))
                        Text("วินาที").font(.headline)
                    }
                    .foregroundColor(.primary)
                    
                    Text("สมาชิกร่วมทริปทุกคนปลอดภัย")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
                viewModel.leaveRoom(source: "TripSummaryView - กลับหน้าหลัก")
            }) {
                Text("กลับสู่หน้าหลัก")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .frame(height: 54)
                    .background(Color.green)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}
