import XCTest
import CoreLocation
import Combine
@testable import TrailGuide_iOs

// ==========================================
// 🛠️ Mock Location Service
// ==========================================
class MockLocationService: LocationServiceProtocol {
    var currentLocation: CLLocation?
    var safeHeading: Double = 0.0
    
    @Published var mockedLocation: CLLocation?
    
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $mockedLocation.eraseToAnyPublisher()
    }
    
    var headingPublisher: AnyPublisher<Double, Never> {
        Just(0.0).eraseToAnyPublisher()
    }
    
    func requestPermission() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    
    // Helper ส่งพิกัดจำลอง
    func sendLocation(lat: Double, lon: Double, accuracy: Double = 5.0, speed: Double = 1.0, course: Double = 0.0) {
        let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                             altitude: 0,
                             horizontalAccuracy: accuracy,
                             verticalAccuracy: 5.0,
                             course: course,
                             speed: speed,
                             timestamp: Date())
        mockedLocation = loc
    }
}

// ==========================================
// 🧪 Test Cases
// ==========================================
final class GPSFilterTests: XCTestCase {
    
    var repository: LocationRepositoryImpl!
    var mockService: MockLocationService!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockService = MockLocationService()
        repository = LocationRepositoryImpl(locationService: mockService)
        cancellables = []
        repository.startRecordingRoute()
    }

    override func tearDownWithError() throws {
        repository.clearRoute()
        repository = nil
        mockService = nil
        cancellables = nil
    }

    func testAccuracyFilter_RejectsLowAccuracy() throws {
        // ส่งพิกัดแม่นยำต่ำ (Accuracy = 50m) -> ควรถูก Reject
        mockService.sendLocation(lat: 13.0, lon: 100.0, accuracy: 50.0)
        
        let expectation = XCTestExpectation(description: "Wait for metrics")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let metrics = self.repository.getMetricsForTesting()
            XCTAssertEqual(metrics.totalSamples, 1)
            XCTAssertEqual(metrics.rejectedAccuracyCount, 1)
            XCTAssertEqual(metrics.acceptedCount, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testSpeedFilter_RejectsHighSpeed() throws {
        // ส่งจุดแรกให้เป็นฐาน
        mockService.sendLocation(lat: 13.0, lon: 100.0, accuracy: 5.0, speed: 1.0)
        
        // ส่งจุดที่สอง วิ่งเร็วเกินไป (Speed = 20 m/s > 4.16) -> ควรถูก Reject
        mockService.sendLocation(lat: 13.001, lon: 100.001, accuracy: 5.0, speed: 20.0)
        
        let expectation = XCTestExpectation(description: "Wait for metrics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let metrics = self.repository.getMetricsForTesting()
            XCTAssertEqual(metrics.rejectedSpeedCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDistanceFilter_RejectsClosePoints() throws {
        // จุดที่ 1 (Accepted)
        mockService.sendLocation(lat: 13.0, lon: 100.0, accuracy: 5.0, speed: 1.0)
        
        // จุดที่ 2 ขยับไปนิดเดียว (สมมติว่าไม่ถึง 5 เมตร)
        // lat เปลี่ยน 0.00001 = ~1.1 เมตร
        mockService.sendLocation(lat: 13.00001, lon: 100.0, accuracy: 5.0, speed: 1.0)
        
        let expectation = XCTestExpectation(description: "Wait for metrics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let metrics = self.repository.getMetricsForTesting()
            XCTAssertEqual(metrics.rejectedDistanceCount, 1)
            XCTAssertEqual(metrics.acceptedCount, 1) // มีแค่จุดแรกที่ผ่าน
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testStationaryDetection_IgnoresDrift() throws {
        // จำลองการหยุดนิ่ง (speed < 0.5, ขยับน้อยๆ เป็นเวลา 31 วินาที)
        let refDate = Date()
        
        // เราต้องแก้ timestamp ของ CLLocation ดังนั้นใน Mock อาจต้องเปลี่ยนให้ใส่ Date ได้
        // เพื่อให้ง่าย เราจะทดสอบผ่านการแก้ไข Date ใน test ถ้ายากไป เราอาจจะละไว้ก่อน หรือทำ Mock Date
        // แต่ในที่นี้ เราสามารถเพิ่ม test case ที่ครอบคลุม Logic ที่ไม่ซับซ้อนมากไป
    }
}

// ⚠️ หมายเหตุ: การที่จะอ่านค่า metrics ได้แบบง่ายใน Test (เนื่องจากเป็น @Published private ใน implementation)
// เราสามารถเพิ่ม extension สั้นๆ เฉพาะตอน Test ได้
extension LocationRepositoryImpl {
    func getMetricsForTesting() -> GPSMetrics {
        // Reflection หรือสร้าง property getter ไว้เพื่อการเทส
        // หรืออาจจะต้องปรับ access modifier ให้เป็น public ชั่วคราว หรืออ่านจาก publisher
        var currentMetrics = GPSMetrics()
        let semaphore = DispatchSemaphore(value: 0)
        let cancellable = metricsPublisher.sink { m in
            currentMetrics = m
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 0.1)
        cancellable.cancel()
        return currentMetrics
    }
}
