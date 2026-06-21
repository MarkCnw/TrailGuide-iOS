import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // 🟢 ตัวแปรที่ RoomViewModel เรียกใช้ ($currentLocation)
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading? // เพิ่มการติดตามเข็มทิศ
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // อัปเดตทุกๆ 5 เมตร เพื่อประหยัดแบตและลด Noise
        manager.headingFilter = 1 // 🟢 เปลี่ยนให้ตอบสนองไวขึ้น (ทุกๆ 1 องศา) เพื่อให้เรดาร์หมุนได้สมูทไม่กระตุก
    }
    
    // 🟢 ฟังก์ชันขอสิทธิ์ (requestPermission)
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // 🟢 ฟังก์ชันเริ่มดึงพิกัด (startUpdatingLocation)
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    // 🟢 ฟังก์ชันหยุดดึงพิกัด (stopUpdatingLocation)
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    // 🟢 Heading ที่ปลอดภัย: ใช้ trueHeading ถ้ามี ถ้าไม่มีใช้ magneticHeading แทน
    // trueHeading จะคืน -1 เมื่อ GPS ยังไม่พร้อม ห้ามใช้โดยตรง!
    var safeHeading: Double {
        guard let heading = currentHeading else { return 0 }
        return heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    }
    
    // Delegate เมื่อพิกัดเปลี่ยน
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    // Delegate เมื่อเข็มทิศ (Heading) เปลี่ยน
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location Error: \(error.localizedDescription)")
    }
}
extension LocationManager: LocationServiceProtocol {
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $currentLocation.eraseToAnyPublisher()
    }
    
    var headingPublisher: AnyPublisher<Double, Never> {
        // ใช้ Map เพื่อแปลง $currentHeading เป็น safeHeading เพื่อส่งออกไป
        $currentHeading.map { _ in self.safeHeading }.eraseToAnyPublisher()
    }
}
