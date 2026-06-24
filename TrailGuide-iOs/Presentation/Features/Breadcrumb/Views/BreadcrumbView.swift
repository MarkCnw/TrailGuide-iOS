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
            // 🚨 Banner แจ้งเตือนหลงทาง (แสดงด้านบน)
            // ==========================================
            VStack {
                if viewModel.isOffRoute {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("คุณกำลังออกนอกเส้นทาง")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
                Spacer()
            }
            
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
                            .foregroundColor(.primary)
                    }.padding(.leading, 17)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            viewModel.stopBacktracking()
                            viewModel.startTracking() // 🟢 เพิ่มบรรทัดนี้ เพื่อให้กลับเข้าโหมดบันทึกเส้นทางปกติ
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
                    let canBacktrack = viewModel.rawRoutePath.count >= BreadcrumbViewModel.BacktrackConstants.minimumBacktrackPoints
                    Button(action: {
                        if canBacktrack {
                            withAnimation {
                                viewModel.startBacktracking()
                            }
                        }
                    }) {
                        Label("ย้อนกลับ", systemImage: "arrow.uturn.backward")
                            .font(.headline)
                            .foregroundColor(canBacktrack ? .white : .white.opacity(0.5))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(canBacktrack ? Color.orange : Color.gray)
                            .clipShape(Capsule())
                    }
                    .disabled(!canBacktrack)
                    
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
                        
                        // 1. ปุ่มบันทึก (Default) - จะแสดงเป็นสีตาม Global Accent Color ของแอป
                        Button("บันทึก") {
                            viewModel.stopTracking()
                            viewModel.saveCurrentTrip()
                            viewModel.clearTracking()
                        }
                        
                        // 2. ปุ่มทิ้งเส้นทาง (Destructive) - จะกลายเป็นสีแดงให้อัตโนมัติ
                        Button("ทิ้งเส้นทาง", role: .destructive) {
                            viewModel.stopTracking()
                            viewModel.clearTracking()
                        }
                        
                        // 3. ปุ่มยกเลิก (Cancel) - จะแสดงเป็นสีปกติและตัวหนา (ถ้าเป็น iOS เวอร์ชั่นใหม่ๆ)
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
