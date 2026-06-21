import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    
    init(viewModel: HistoryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.trips.isEmpty {
                    ContentUnavailableView(
                        "ยังไม่มีประวัติเดินทาง",
                        systemImage: "map.fill",
                        description: Text("เมื่อคุณจบทริปและบันทึก\nประวัติจะแสดงที่นี่")
                    )
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.trips, id: \.id) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip, viewModel: viewModel)) {
                                TripRowView(trip: trip, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle()) // ให้ปุ่มไม่เปลี่ยนสีตอนกด
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ประวัติการเดินทาง")
            .background(Color(.systemGroupedBackground)) // สีพื้นหลังเทาอ่อนพรีเมียม
            .onAppear { viewModel.loadTrips() }
        }
    }
}

// ==========================================
// 📄 การ์ดทริป (Trip Card) - ดีไซน์ใหม่!
// ==========================================
struct TripRowView: View {
    let trip: TripHistory
    let viewModel: HistoryViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(viewModel.formattedDate(trip.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    InfoTag(text: viewModel.formattedDistance(trip.distance), icon: "figure.walk").foregroundStyle(.green) // เปลี่ยนสีทั้งไอคอนและตัวหนังสือพร้อมกัน
                    InfoTag(
                        text: viewModel.formattedDuration(trip.duration),
                        icon: "clock"
                    )
                    .foregroundStyle(
                        .blue
                    ) // เปลี่ยนสีทั้งไอคอนและตัวหนังสือพร้อมกัน
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground)) // สีขาว/เทาเข้มตามโหมด
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) // เงาบางๆ
    }
}

// Component เสริมให้โค้ดสะอาด
// ==========================================
// 📄 เปลี่ยนจาก InfoTag แบบมีกล่อง เป็นแบบข้อความปกติ
// ==========================================
struct InfoTag: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.bold())
       
        // ❌ ลบ .padding, .background และ .clipShape ออกทั้งหมดครับ!
    }
}
