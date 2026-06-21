import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: TripHistory
    @State var viewModel: HistoryViewModel
    
    // 🟢 สวิตช์สำหรับ Pop-up เปลี่ยนชื่อ
    @State private var isShowingRenameAlert = false
    @State private var newTripName = ""
    
    // 🟢 ตำแหน่งกล้องแผนที่ (คำนวณจากเส้นทาง)
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // ==========================================
                // 🗺️ ส่วนที่ 1: แผนที่แสดงเส้นทาง
                // ==========================================
                Map(position: $cameraPosition) {
                    if !trip.routePath.isEmpty {
                        MapPolyline(coordinates: trip.routePath)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        
                        // 📍 จุดเริ่มต้น
                        if let first = trip.routePath.first {
                            Annotation("เริ่ม", coordinate: first) {
                                Image(systemName: "flag.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        // 🏁 จุดสิ้นสุด
                        if let last = trip.routePath.last, trip.routePath.count > 1 {
                            Annotation("จบ", coordinate: last) {
                                Image(systemName: "flag.checkered.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)
                
                // ==========================================
                // 📊 ส่วนที่ 2: ข้อมูลทริป
                // ==========================================
                VStack(spacing: 16) {
                    
                    // 📅 วันที่
                    DetailInfoRow(
                        icon: "calendar",
                        title: "วันที่",
                        value: viewModel.formattedDate(trip.date)
                    )
                    
                    Divider()
                    
                    // 📏 ระยะทาง
                    DetailInfoRow(
                        icon: "figure.walk",
                        title: "ระยะทาง",
                        value: viewModel.formattedDistance(trip.distance)
                    )
                    
                    Divider()
                    
                    // 🕐 ระยะเวลา
                    DetailInfoRow(
                        icon: "clock",
                        title: "ระยะเวลา",
                        value: viewModel.formattedDuration(trip.duration)
                    )
                    
                    Divider()
                    
                    // 📍 จำนวนจุดพิกัด
                    DetailInfoRow(
                        icon: "mappin.and.ellipse",
                        title: "จุดพิกัด",
                        value: "\(trip.routePath.count) จุด"
                    )
                    
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 12)
                
                // ==========================================
                // ✏️ ส่วนที่ 3: ปุ่มเปลี่ยนชื่อ
                // ==========================================
                Button {
                    newTripName = trip.name
                    isShowingRenameAlert = true
                } label: {
                    Label("เปลี่ยนชื่อทริป", systemImage: "pencil")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
                
            }
        }
        // 🏷️ HIG: Inline Title สำหรับหน้ารายละเอียด
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        // 🔔 Alert พร้อม TextField สำหรับเปลี่ยนชื่อ (HIG: Alert with Text Field)
        .alert("เปลี่ยนชื่อทริป", isPresented: $isShowingRenameAlert) {
            TextField("ชื่อทริป", text: $newTripName)
            
            Button("บันทึก") {
                if !newTripName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.updateTripName(id: trip.id, newName: newTripName)
                }
            }
            
            Button("ยกเลิก", role: .cancel) { }
        } message: {
            Text("กรุณาใส่ชื่อใหม่สำหรับทริปนี้")
        }
    }
}

// ==========================================
// 📄 แถวแสดงข้อมูลรายละเอียด (ไอคอน + หัวข้อ + ค่า)
// ==========================================
struct DetailInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}
