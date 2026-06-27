import Foundation
import CoreLocation
import Combine
import SwiftUI

@Observable
final class BreadcrumbViewModel {
    
    enum BacktrackConstants {
        static let waypointReachThreshold: CLLocationDistance = 2.0
        static let offRouteThreshold: CLLocationDistance = 5.0
        static let minimumBacktrackPoints: Int = 2
        static let waypointSpacing: CLLocationDistance = 1.0
        static let waypointBearingChangeThreshold: Double = 30.0
    }
    
    var isRecording: Bool = false
    var routePath: [CLLocationCoordinate2D] = []
    var rawRoutePath: [CLLocationCoordinate2D] = []
    var tripStartTime: Date?
    
    private let locationRepository: LocationRepositoryProtocol
    private let saveTripUseCase: SaveTripUseCase
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    /// ชื่อผู้ใช้สำหรับพูดออกเสียง (อ่านจาก UserDefaults)
    private var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "นักเดินทาง"
    }
    
    /// ป้องกันการส่ง Notification ซ้ำ — ส่งแค่ครั้งเดียวจนกว่าจะกลับเข้าเส้นทางแล้วออกอีกรอบ
    private var hasNotifiedOffRoute = false
    
    init(locationRepository: LocationRepositoryProtocol, saveTripUseCase: SaveTripUseCase, notificationService: NotificationServiceProtocol) {
        self.locationRepository = locationRepository
        self.saveTripUseCase = saveTripUseCase
        self.notificationService = notificationService
        startListeningToRoute()
    }
    
    private func startListeningToRoute() {
        locationRepository.routePathPublisher
            .sink { [weak self] newPath in self?.routePath = newPath }
            .store(in: &cancellables)
        
        locationRepository.rawRoutePathPublisher
            .sink { [weak self] newPath in self?.rawRoutePath = newPath }
            .store(in: &cancellables)
        
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
        tripStartTime = Date()
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
        tripStartTime = nil
    }
    
    // ==========================================
    // 🔙 Backtrack Features
    // ==========================================
    var isBacktracking: Bool = false
    var isOffRoute: Bool = false
    var backtrackPath: [CLLocationCoordinate2D] = []
    var nextWaypointIndex: Int = 0
    var distanceToNextWaypoint: Double = 0.0
    var totalBacktrackDistance: Double = 0.0
    
    func startBacktracking() {
        guard rawRoutePath.count >= BacktrackConstants.minimumBacktrackPoints else { return }
        locationRepository.pauseRecordingRoute()
        isRecording = false
        
        let reversedPath = Array(rawRoutePath.reversed())
        
        backtrackPath = LocationCalculator.simplifyPath(
            reversedPath,
            spacing: BacktrackConstants.waypointSpacing,
            bearingThreshold: BacktrackConstants.waypointBearingChangeThreshold
        )
        
        nextWaypointIndex = 0
        isBacktracking = true
        isOffRoute = false
        
        calculateBacktrackDistances(currentLocation: nil)
        
        
        
    }
    
    func stopBacktracking() {
        isBacktracking = false
        isOffRoute = false
        backtrackPath = []
        nextWaypointIndex = 0
        distanceToNextWaypoint = 0.0
        totalBacktrackDistance = 0.0
        
        
    }
    
    func updateBacktrackProgress(userLocation: CLLocationCoordinate2D) {
        guard isBacktracking, nextWaypointIndex < backtrackPath.count else { return }
        
        // ✅ FIX Bug #1: อัปเดตระยะทาง *ก่อน* ตรวจว่าถึง waypoint หรือยัง
        // เพื่อให้ตัวเลขระยะทางขยับอัปเดตตลอดเวลา ไม่ค้าง
        checkOffRoute(userLocation: userLocation)
        calculateBacktrackDistances(currentLocation: userLocation)
        
        let targetLocation = backtrackPath[nextWaypointIndex]
        let distance = LocationCalculator.calculateDistance(from: userLocation, to: targetLocation)
        
        if distance < BacktrackConstants.waypointReachThreshold {
            nextWaypointIndex += 1
            if nextWaypointIndex >= backtrackPath.count {
                // 🏁 ถึงจุดเริ่มต้นแล้ว — ส่ง Notification + พูดเสียง
                let message = "ยินดีด้วย! คุณเดินทางย้อนกลับมาถึงจุดเริ่มต้นอย่างปลอดภัยแล้ว"
                notificationService.sendNotification(title: "✅ ถึงจุดเริ่มต้นแล้ว!", body: message)
                notificationService.speak("\(username) \(message)")
                stopBacktracking()
                return
            }
        }
    }
    
    private func checkOffRoute(userLocation: CLLocationCoordinate2D) {
        guard backtrackPath.count > 1 else { return }
        var minDistance = Double.infinity
        
        let startIndex = max(0, nextWaypointIndex - 1)
        for i in startIndex..<(backtrackPath.count - 1) {
            let p1 = backtrackPath[i]
            let p2 = backtrackPath[i+1]
            let dist = LocationCalculator.crossTrackDistance(point: userLocation, start: p1, end: p2)
            if dist < minDistance {
                minDistance = dist
            }
        }
        
        
        isOffRoute = minDistance > BacktrackConstants.offRouteThreshold
        
        // ⚠️ ส่ง Notification + พูดเสียง เมื่อเพิ่งออกนอกเส้นทาง (ส่งแค่ครั้งเดียว ไม่ spam)
        if isOffRoute && !hasNotifiedOffRoute {
            hasNotifiedOffRoute = true
            let message = "ระวัง! คุณกำลังเดินเบี่ยงออกนอกเส้นทางที่บันทึกไว้ โปรดเปิดแผนที่เพื่อตรวจสอบ"
            notificationService.sendNotification(title: "⚠️ ออกนอกเส้นทาง!", body: message)
            notificationService.speak("\(username) \(message)")
        } else if !isOffRoute && hasNotifiedOffRoute {
            // กลับเข้าเส้นทางแล้ว — รีเซ็ต flag เพื่อให้สามารถแจ้งเตือนได้อีกถ้าออกนอกเส้นทางอีกรอบ
            hasNotifiedOffRoute = false
        }
    }
    
    private func calculateBacktrackDistances(currentLocation: CLLocationCoordinate2D?) {
        guard isBacktracking, nextWaypointIndex < backtrackPath.count else { return }
        
        var totalDist: Double = 0.0
        
        if let currentLoc = currentLocation {
            let targetLoc = backtrackPath[nextWaypointIndex]
            distanceToNextWaypoint = LocationCalculator.calculateDistance(from: currentLoc, to: targetLoc)
            totalDist += distanceToNextWaypoint
            
            if nextWaypointIndex + 1 < backtrackPath.count {
                for i in (nextWaypointIndex + 1)..<backtrackPath.count {
                    totalDist += LocationCalculator.calculateDistance(from: backtrackPath[i-1], to: backtrackPath[i])
                }
            }
        } else {
            distanceToNextWaypoint = 0.0
            for i in 1..<backtrackPath.count {
                totalDist += LocationCalculator.calculateDistance(from: backtrackPath[i-1], to: backtrackPath[i])
            }
        }
        
        totalBacktrackDistance = totalDist
    }
    
    func generateDefaultTripName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "ทริปวันที่ \(formatter.string(from: Date()))"
    }
    
    func saveCurrentTrip() {
        var totalDistance = 0.0
        if rawRoutePath.count > 1 {
            for i in 1..<rawRoutePath.count {
                totalDistance += LocationCalculator.calculateDistance(from: rawRoutePath[i-1], to: rawRoutePath[i])
            }
        }
        
        let duration = tripStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
        
        let newTrip = TripHistory(
            id: Int.random(in: 1...999999),
            name: generateDefaultTripName(),
            date: Date(),
            distance: totalDistance,
            duration: duration,
            routePath: self.rawRoutePath
        )
        saveTripUseCase.execute(newTrip)
        print("💾 บันทึกทริปสำเร็จ: \(newTrip.name)")
    }
}
