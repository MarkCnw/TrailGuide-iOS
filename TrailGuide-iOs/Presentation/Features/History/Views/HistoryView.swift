import SwiftUI
import Charts // 🟢 นำเข้า Charts Framework ของ Apple (ต้องใช้ iOS 16+)

// Model สำหรับประวัติ (เหมือนเดิม)
struct TripHistory: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let distanceKm: Double
    let durationString: String
    let role: String
    let membersCount: Int
}

// 🟢 Model สำหรับวาดกราฟวงกลม
struct RoleStat: Identifiable {
    let id = UUID()
    let role: String
    let count: Int
    let color: Color
}

struct HistoryView: View {
    @State private var mockTrips: [TripHistory] = [
        TripHistory(title: "เดินป่าเขาใหญ่", date: Date().addingTimeInterval(-86400 * 2), distanceKm: 5.4, durationString: "2 ชม. 15 นาที", role: "Host", membersCount: 4),
        TripHistory(title: "สำรวจเส้นทางน้ำตก", date: Date().addingTimeInterval(-86400 * 15), distanceKm: 3.2, durationString: "1 ชม. 30 นาที", role: "Member", membersCount: 2),
        TripHistory(title: "ปีนเขาภูกระดึง", date: Date().addingTimeInterval(-86400 * 25), distanceKm: 8.5, durationString: "4 ชม. 10 นาที", role: "Member", membersCount: 5),
        TripHistory(title: "ทริปหลงป่า (เทสต์)", date: Date().addingTimeInterval(-86400 * 30), distanceKm: 1.5, durationString: "45 นาที", role: "Member", membersCount: 3)
    ]
    
    // 🟢 คำนวณสถิติเพื่อเอาไปวาดกราฟ
    var roleStats: [RoleStat] {
        let hostCount = mockTrips.filter { $0.role == "Host" }.count
        let memberCount = mockTrips.filter { $0.role == "Member" }.count
        return [
            RoleStat(role: "หัวหน้าทริป", count: hostCount, color: .orange),
            RoleStat(role: "สมาชิก", count: memberCount, color: .green)
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if mockTrips.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 🟢 1. วาง Dashboard กราฟไว้ด้านบนสุด
                            summaryDashboardView
                            
                            // 🟢 2. รายการประวัติ
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ประวัติทริปทั้งหมด")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 4)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(mockTrips) { trip in
                                        TripCardView(trip: trip)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("ประวัติการเดินทาง")
        }
    }
    
    // MARK: - Components
    
    // 🟢 Component: หน้าปัดสรุปสถิติพร้อมกราฟวงกลม
        private var summaryDashboardView: some View {
            VStack(spacing: 24) {
                
                // --- 1. ส่วนกราฟวงกลมใหญ่ (ด้านบน) ---
                ZStack {
                    Chart(roleStats) { stat in
                        SectorMark(
                            angle: .value("Count", stat.count),
                            innerRadius: .ratio(0.75), // 🟢 เจาะรูให้กว้างขึ้นเป็น 75% เพื่อให้มีที่วางรูป
                            angularInset: 2.0
                        )
                        .foregroundStyle(stat.color)
                        .cornerRadius(6)
                    }
                    .frame(height: 240) // 🟢 ขยายความสูงกราฟให้ใหญ่เบิ้ม (เปลี่ยนตัวเลขได้ตามชอบ)
                    
                    // 🟢 2. ใส่รูปภาพตรงกลางรูโดนัท
                    // TODO: เปลี่ยน "your_image_name" เป็นชื่อรูปของคุณที่มีใน Assets
                    Image("4")// อันนี้คือรูปจำลอง
                        .resizable()
                        .scaledToFill()
                        
                        .frame(width: 160, height: 160) // 🟢 ขนาดรูปต้องเล็กกว่ากราฟนิดหน่อย
                        .clipShape(Circle())
                        // เพิ่มขอบสีขาวให้รูปดูนูนขึ้นมา ทับกราฟเนียนๆ
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 4))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
                
                Divider()
                
                // --- 3. ส่วนสถิติและคำอธิบาย (ด้านล่าง) ---
                HStack(alignment: .center) {
                    // สรุประยะทางรวม
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ระยะทางสะสม")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            let totalDistance = mockTrips.reduce(0) { $0 + $1.distanceKm }
                            Text(String(format: "%.1f", totalDistance))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("กม.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // อธิบายสีกราฟวงกลม (Legend)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(roleStats) { stat in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stat.color)
                                    .frame(width: 10, height: 10)
                                Text(stat.role)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(stat.count)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shoeprints.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("ยังไม่มีประวัติการเดินทาง")
                .font(.title2).fontWeight(.bold)
            Text("เริ่มต้นทริปแรกของคุณ\nด้วยการสร้างกลุ่มหรือเข้าร่วมกับเพื่อน")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// 🟢 Component: การ์ดแสดงประวัติแต่ละทริป (เหมือนที่คุณมีอยู่แล้ว)
struct TripCardView: View {
    let trip: TripHistory
    
    var body: some View {
        // ... (ใส่โค้ด TripCardView เดิมที่คุณมีลงตรงนี้ได้เลยครับ เพื่อให้โค้ดสมบูรณ์)
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title).font(.headline).fontWeight(.bold)
                    Text(trip.date, style: .date).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text(trip.role == "Host" ? "หัวหน้าทริป" : "สมาชิก")
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(trip.role == "Host" ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(trip.role == "Host" ? .orange : .green)
                    .clipShape(Capsule())
            }
            Divider()
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ระยะทาง").font(.caption).foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", trip.distanceKm)).font(.title2).fontWeight(.heavy).foregroundColor(.green)
                        Text("กม.").font(.caption).fontWeight(.medium).foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("ระยะเวลา").font(.caption).foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(trip.durationString).font(.headline).fontWeight(.bold)
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
