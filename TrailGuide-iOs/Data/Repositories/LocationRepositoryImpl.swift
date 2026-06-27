import Foundation
import CoreLocation
import Combine
import OSLog

// ==========================================
// ⚙️ GPS Constants (Thresholds)
// ==========================================
enum GPSConstants {
    static let accuracyThreshold: CLLocationAccuracy = 20.0
    static let distanceThreshold: CLLocationDistance = 1.0
    static let maxHikingSpeed: CLLocationSpeed = 4.16 // ~15 km/h
    static let stationarySpeedThreshold: CLLocationSpeed = 0.5
    static let stationaryDistanceThreshold: CLLocationDistance = 0.5
    static let stationaryTimeThreshold: TimeInterval = 30.0
    static let movingAverageWindowSize: Int = 5
}

class LocationRepositoryImpl: LocationRepositoryProtocol {
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // 📝 Logger สำหรับระบบ GPS
    private let gpsLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.trailguide", category: "GPSFilter")
    
    // 📊 Data State
    @Published private var rawRoutePath: [CLLocationCoordinate2D] = []
    @Published private var smoothedRoutePath: [CLLocationCoordinate2D] = []
    @Published private var metrics = GPSMetrics()
    
    // 🔄 Pipeline State
    private var lastAcceptedLocation: CLLocation?
    private var recentLocations: [CLLocation] = [] // สำหรับ Moving Average
    
    // 🛑 Stationary State
    private var stationaryReferenceLocation: CLLocation?
    private var stationaryStartTime: Date?
    
    private var isRecording = false
    
    init(locationService: LocationServiceProtocol) {
        self.locationService = locationService
        setupBinding()
    }
    
    // ==========================================
    // 📡 Publishers (Protocol Implementation)
    // ==========================================
    var routePathPublisher: AnyPublisher<[CLLocationCoordinate2D], Never> {
        $smoothedRoutePath.eraseToAnyPublisher()
    }
    
    var rawRoutePathPublisher: AnyPublisher<[CLLocationCoordinate2D], Never> {
        $rawRoutePath.eraseToAnyPublisher()
    }
    
    var metricsPublisher: AnyPublisher<GPSMetrics, Never> {
        $metrics.eraseToAnyPublisher()
    }
    
    var currentLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> {
        locationService.locationPublisher
            .map { $0?.coordinate }
            .eraseToAnyPublisher()
    }
    
    private func setupBinding() {
        locationService.locationPublisher
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self, self.isRecording else { return }
                self.processLocation(location)
            }
            .store(in: &cancellables)
    }
    
    // ==========================================
    // 🚀 GPS Processing Pipeline
    // ==========================================
    private func processLocation(_ location: CLLocation) {
        metrics.totalSamples += 1
        
        // 1. Accuracy Filter
        guard location.horizontalAccuracy <= GPSConstants.accuracyThreshold else {
            metrics.rejectedAccuracyCount += 1
            gpsLogger.debug("Rejected: Accuracy = \(location.horizontalAccuracy)m")
            return
        }
        
        // 2. Stationary Detection
        if location.speed < GPSConstants.stationarySpeedThreshold {
            if let refLoc = stationaryReferenceLocation {
                let dist = location.distance(from: refLoc)
                if dist < GPSConstants.stationaryDistanceThreshold {
                    if let startTime = stationaryStartTime, Date().timeIntervalSince(startTime) > GPSConstants.stationaryTimeThreshold {
                        metrics.rejectedStationaryCount += 1
                        gpsLogger.info("Rejected: Stationary Mode (dist: \(dist)m, time: \(Date().timeIntervalSince(startTime))s)")
                        return
                    }
                } else {
                    resetStationary(with: location)
                }
            } else {
                resetStationary(with: location)
            }
        } else {
            resetStationary(with: nil)
        }
        
        // 3. Speed Check
        guard location.speed <= GPSConstants.maxHikingSpeed else {
            metrics.rejectedSpeedCount += 1
            gpsLogger.debug("Rejected: Speed = \(location.speed)m/s")
            return
        }
        
        // 4. Distance Filter
        if let lastAccepted = lastAcceptedLocation {
            let distance = location.distance(from: lastAccepted)
            guard distance >= GPSConstants.distanceThreshold else {
                metrics.rejectedDistanceCount += 1
                gpsLogger.debug("Rejected: Distance = \(distance)m")
                return
            }
            
            // 5. Heading Check (Anomaly Detection)
            // เช็คว่าทิศทางเปลี่ยนไปมากกว่า 90 องศาโดยที่ความเร็วน้อยมากหรือไม่
            if location.speed < 1.0, location.course >= 0, lastAccepted.course >= 0 {
                let courseDelta = abs(location.course - lastAccepted.course)
                let normalizedDelta = courseDelta > 180 ? 360 - courseDelta : courseDelta
                if normalizedDelta > 90 {
                    metrics.rejectedHeadingCount += 1
                    gpsLogger.debug("Rejected: Heading Anomaly (delta: \(normalizedDelta))")
                    return
                }
            }
        }
        
        // ผ่านการกรองทั้งหมด -> เก็บเข้า Raw Route
        lastAcceptedLocation = location
        rawRoutePath.append(location.coordinate)
        metrics.acceptedCount += 1
        
        // 6. Moving Average (สร้าง Smoothed Location)
        recentLocations.append(location)
        if recentLocations.count > GPSConstants.movingAverageWindowSize {
            recentLocations.removeFirst()
        }
        
        let smoothedCoordinate = calculateMovingAverage(for: recentLocations)
        smoothedRoutePath.append(smoothedCoordinate)
        
        gpsLogger.debug("Accepted: [Raw: \(self.rawRoutePath.count), Smoothed: \(self.smoothedRoutePath.count)]")
    }
    
    // ==========================================
    // 🧮 Helper Functions
    // ==========================================
    private func resetStationary(with location: CLLocation?) {
        stationaryReferenceLocation = location
        if location != nil {
            stationaryStartTime = Date()
        } else {
            stationaryStartTime = nil
        }
    }
    
    private func calculateMovingAverage(for locations: [CLLocation]) -> CLLocationCoordinate2D {
        guard !locations.isEmpty else { return CLLocationCoordinate2D() }
        var sumLat = 0.0
        var sumLon = 0.0
        for loc in locations {
            sumLat += loc.coordinate.latitude
            sumLon += loc.coordinate.longitude
        }
        let count = Double(locations.count)
        return CLLocationCoordinate2D(latitude: sumLat / count, longitude: sumLon / count)
    }
    
    // ==========================================
    // 🎮 Control Actions
    // ==========================================
    func startRecordingRoute() {
        isRecording = true
        locationService.startUpdatingLocation()
    }
    
    func pauseRecordingRoute() {
        isRecording = false
        // ไม่หยุด locationService เพื่อให้ GPS ยังอ่านค่า Location ต่อไป (สำหรับ Backtracking)
    }
    
    func stopRecordingRoute() {
        isRecording = false
        locationService.stopUpdatingLocation()
    }
    
    func clearRoute() {
        rawRoutePath.removeAll()
        smoothedRoutePath.removeAll()
        recentLocations.removeAll()
        lastAcceptedLocation = nil
        resetStationary(with: nil)
        metrics = GPSMetrics() // Reset metrics
    }
}
