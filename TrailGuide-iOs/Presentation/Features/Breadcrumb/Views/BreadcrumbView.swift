import SwiftUI
import MapKit

struct BreadcrumbView: View {
    @State private var viewModel: BreadcrumbViewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // 🟢 ตัวแปรสวิตช์สำหรับเปิด Pop-up
    @State private var isShowingAlert: Bool = false
    
    @Namespace private var mapScope
    
    init(viewModel: BreadcrumbViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // ==========================================
            // 🗺️ ส่วนที่ 1: แผนที่
            // ==========================================
            Map(position: $cameraPosition, bounds: MapCameraBounds(minimumDistance: 100, maximumDistance: 500)) {
                
                if !viewModel.routePath.isEmpty {
                    MapPolyline(coordinates: viewModel.routePath)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                }
                
                // 🔙 เส้นทางย้อนกลับ (ถ้ามี)
                if viewModel.isBacktracking {
                    let remainingPath = Array(viewModel.backtrackPath[viewModel.nextWaypointIndex...])
                    if !remainingPath.isEmpty {
                        MapPolyline(coordinates: remainingPath)
                            .stroke(.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round, dash: [10, 10]))
                    }
                    
                    // 🚩 จุดที่ต้องเดินไปถัดไป
                    if viewModel.nextWaypointIndex < viewModel.backtrackPath.count {
                        let nextPoint = viewModel.backtrackPath[viewModel.nextWaypointIndex]
                        Annotation("จุดถัดไป", coordinate: nextPoint) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .orange)
                        }
                    }
                }
                
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .safeAreaPadding(.top, 50)
            
            // ==========================================
            // 🎮 ส่วนที่ 2: แผงควบคุม
            // ==========================================
            HStack(spacing: 20) {
                
                if viewModel.isBacktracking {
                    // 🔙 โหมดย้อนกลับ
                    VStack(alignment: .leading, spacing: 4) {
                        Text("กำลังย้อนกลับทางเดิม")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("เหลือ \(String(format: "%.0f", viewModel.totalBacktrackDistance)) เมตร")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            viewModel.stopBacktracking()
                        }
                    }) {
                        Label("หยุดย้อนกลับ", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                } else if viewModel.isRecording == false {
                    
                    // 🌟 ปุ่มเริ่มเดิน
                    Button(action: {
                        viewModel.startTracking()
                    }) {
                        Label("เริ่มเดิน", systemImage: "figure.hiking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    
                } else {
                    
                    // 🌟 ปุ่มย้อนกลับ
                    Button(action: {
                        withAnimation {
                            viewModel.startBacktracking()
                        }
                    }) {
                        Label("ย้อนกลับ", systemImage: "arrow.uturn.backward")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.orange) // เปลี่ยนเป็นสีส้มให้ชัดเจน
                            .clipShape(Capsule())
                    }
                    
                    // 🛑 ปุ่มจบทริป (กดแล้วเรียก Pop-up)
                    Button(action: {
                        isShowingAlert = true
                    }) {
                        Label("จบทริป", systemImage: "stop.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    // ==========================================
                    // 🔔 Pop-up จบทริป (ผูกติดกับปุ่มจบทริป)
                    // ==========================================
                    .alert("จบทริป", isPresented: $isShowingAlert) {
                        
                        // ปุ่มบันทึก
                        Button("บันทึก") {
                            viewModel.stopTracking()
                            viewModel.saveCurrentTrip()
                            viewModel.clearTracking()
                        }
                        
                        // ปุ่มทิ้งเส้นทาง
                        Button("ทิ้งเส้นทาง", role: .destructive) {
                            viewModel.stopTracking()
                            viewModel.clearTracking()
                        }
                        
                        // ปุ่มยกเลิก
                        Button("ยกเลิก", role: .cancel) { }
                        
                    } message: {
                        Text("คุณต้องการบันทึกประวัติเส้นทางนี้หรือไม่?")
                    }
                    
                }
            } // ปิด HStack
            .padding()
            // 💡 ถ้าอยากได้กระจกฝ้าสีดำเข้มตรงแผงควบคุม ให้เปลี่ยน .regularMaterial เป็น .ultraThickMaterial แล้วเพิ่ม .environment(\.colorScheme, .dark) ครับ
            .background(.regularMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .padding(.bottom, 24)
            
        } // ปิด ZStack
        .ignoresSafeArea(.all, edges: .top)
    }
}
