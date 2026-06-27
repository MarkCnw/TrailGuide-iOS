import Foundation
import CoreLocation
import Combine

struct GPSMetrics {
    var totalSamples: Int = 0
    var acceptedCount: Int = 0
    var rejectedAccuracyCount: Int = 0
    var rejectedStationaryCount: Int = 0
    var rejectedSpeedCount: Int = 0
    var rejectedDistanceCount: Int = 0
    var rejectedHeadingCount: Int = 0
    
    func summary() -> String {
        return """
        GPS Samples: \(totalSamples)
        Accepted: \(acceptedCount)
        Rejected Accuracy: \(rejectedAccuracyCount)
        Rejected Stationary: \(rejectedStationaryCount)
        Rejected Distance: \(rejectedDistanceCount)
        Rejected Speed: \(rejectedSpeedCount)
        Rejected Heading: \(rejectedHeadingCount)
        """
    }
}

protocol LocationRepositoryProtocol {
    // ใช้อ่านเส้นทาง Smoothed (เอาไปวาดเส้นบนแผนที่)
    var routePathPublisher: AnyPublisher<[CLLocationCoordinate2D], Never> { get }
    
    // ใช้อ่านเส้นทาง Raw (เอาไปบันทึกและ Backtrack)
    var rawRoutePathPublisher: AnyPublisher<[CLLocationCoordinate2D], Never> { get }
    
    // สถิติ GPS
    var metricsPublisher: AnyPublisher<GPSMetrics, Never> { get }
    
    // พิกัดปัจจุบันของผู้ใช้
    var currentLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }
    
    // เริ่ม/หยุด การบันทึกเส้นทาง
    func startRecordingRoute()
    func pauseRecordingRoute()
    func stopRecordingRoute()
    func clearRoute()
}
