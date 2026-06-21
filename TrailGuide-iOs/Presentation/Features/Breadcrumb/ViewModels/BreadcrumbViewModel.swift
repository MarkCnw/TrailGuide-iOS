import Foundation
import CoreLocation
import Combine
import SwiftUI

@Observable
final class BreadcrumbViewModel {
    
    var isRecording: Bool = false
    var routePath: [CLLocationCoordinate2D] = []
    var rawRoutePath: [CLLocationCoordinate2D] = [] // สำหรับ Save และ Backtrack
    
    // พนักงานที่เราใช้งาน
    private let locationRepository: LocationRepositoryProtocol
    private let tripRepository: TripHistoryRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // 🤝 รับอุปกรณ์เข้ามารวมกันใน init เดียว
    init(locationRepository: LocationRepositoryProtocol, tripRepository: TripHistoryRepositoryProtocol) {
        self.locationRepository = locationRepository
        self.tripRepository = tripRepository
        
        startListeningToRoute()
    }
    
    private func startListeningToRoute() {
        // ฟังการวาดเส้นทาง (Smoothed) สำหรับแสดงบนแผนที่
        locationRepository.routePathPublisher
            .sink { [weak self] newPath in
                self?.routePath = newPath
            }
            .store(in: &cancellables)
            
        // ฟังเส้นทางจริง (Raw) สำหรับการเซฟและย้อนกลับ
        locationRepository.rawRoutePathPublisher
            .sink { [weak self] newPath in
                self?.rawRoutePath = newPath
            }
            .store(in: &cancellables)
            
        // ฟังพิกัดปัจจุบันเพื่ออัพเดท Backtrack
        locationRepository.currentLocationPublisher
            .sink { [weak self] location in
                guard let self = self, let loc = location else { return }
                self.updateBacktrackProgress(userLocation: loc)
            }
            .store(in: &cancellables)
    }
    
    func startTracking() {
        locationRepository.startRecordingRoute()
        isRecording = true
        isBacktracking = false
    }
    
    func stopTracking() {
        locationRepository.stopRecordingRoute()
        isRecording = false
    }
    
    func clearTracking() {
        locationRepository.clearRoute()
        isRecording = false
        isBacktracking = false
        backtrackPath = []
    }
    
    // ==========================================
    // 🔙 Backtrack Features
    // ==========================================
    var isBacktracking: Bool = false
    var backtrackPath: [CLLocationCoordinate2D] = []
    var nextWaypointIndex: Int = 0
    var distanceToNextWaypoint: Double = 0.0
    var totalBacktrackDistance: Double = 0.0
    
    func startBacktracking() {
        guard !rawRoutePath.isEmpty else { return }
        // หยุดบันทึกเส้นทางปกติ
        stopTracking()
        
        // Reverse เส้นทาง (ใช้ Raw Route แทน Smoothed)
        backtrackPath = rawRoutePath.reversed()
        nextWaypointIndex = 0
        isBacktracking = true
        
        calculateBacktrackDistances(currentLocation: nil)
    }
    
    func stopBacktracking() {
        isBacktracking = false
        backtrackPath = []
        nextWaypointIndex = 0
        distanceToNextWaypoint = 0.0
        totalBacktrackDistance = 0.0
    }
    
    func updateBacktrackProgress(userLocation: CLLocationCoordinate2D) {
        guard isBacktracking, nextWaypointIndex < backtrackPath.count else { return }
        
        let targetLocation = backtrackPath[nextWaypointIndex]
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetLoc = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
        
        let distance = userLoc.distance(from: targetLoc)
        
        // ถ้าเข้าใกล้จุดหมายในระยะ 15 เมตร ให้ถือว่าผ่านจุดนี้แล้ว ไปจุดถัดไป
        if distance < 15.0 {
            nextWaypointIndex += 1
            if nextWaypointIndex >= backtrackPath.count {
                // ถึงจุดเริ่มต้นแล้ว (จบ backtrack)
                stopBacktracking()
                return
            }
        }
        
        calculateBacktrackDistances(currentLocation: userLocation)
    }
    
    private func calculateBacktrackDistances(currentLocation: CLLocationCoordinate2D?) {
        guard isBacktracking, nextWaypointIndex < backtrackPath.count else { return }
        
        var totalDist: Double = 0.0
        
        if let currentLoc = currentLocation {
            let userLoc = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            let nextLoc = backtrackPath[nextWaypointIndex]
            let nextCLLoc = CLLocation(latitude: nextLoc.latitude, longitude: nextLoc.longitude)
            distanceToNextWaypoint = userLoc.distance(from: nextCLLoc)
            totalDist += distanceToNextWaypoint
            
            // คำนวณระยะทางจาก nextWaypoint ไปจนจบ
            if nextWaypointIndex + 1 < backtrackPath.count {
                for i in (nextWaypointIndex + 1)..<backtrackPath.count {
                    let loc1 = CLLocation(latitude: backtrackPath[i-1].latitude, longitude: backtrackPath[i-1].longitude)
                    let loc2 = CLLocation(latitude: backtrackPath[i].latitude, longitude: backtrackPath[i].longitude)
                    totalDist += loc1.distance(from: loc2)
                }
            }
        } else {
            // ถ้ายังไม่มี current location ตอนเริ่ม
            distanceToNextWaypoint = 0.0
            for i in 1..<backtrackPath.count {
                let loc1 = CLLocation(latitude: backtrackPath[i-1].latitude, longitude: backtrackPath[i-1].longitude)
                let loc2 = CLLocation(latitude: backtrackPath[i].latitude, longitude: backtrackPath[i].longitude)
                totalDist += loc1.distance(from: loc2)
            }
        }
        
        totalBacktrackDistance = totalDist
    }
    
    func generateDefaultTripName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        return "ทริปวันที่ \(dateString)"
    }
    
    
    func saveCurrentTrip() {
        // สร้างสมุดไดอารี่เล่มใหม่
        let newTrip = TripHistory(
            id: Int.random(in: 1...999999), // 🟢 1. สุ่ม ID ใส่ไปก่อน
            name: generateDefaultTripName(),
            date: Date(),
            distance: 0.0,
            duration: 0.0, // 🟢 2. ให้เป็นทศนิยมเพื่อตรงกับประเภท Double
            routePath: self.rawRoutePath // 🟢 3. โยน Array เส้นทางจริงๆ ใส่ไปได้เลย (ใช้ Raw)
        )
        
        // สั่งพนักงานเซฟลงตู้
        tripRepository.saveTrip(newTrip)
        print("💾 บันทึกทริปสำเร็จ: \(newTrip.name)")
    }
}
