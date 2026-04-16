import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // 🟢 ตัวแปรที่ RoomViewModel เรียกใช้ ($currentLocation)
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // อัปเดตทุกๆ 5 เมตร เพื่อประหยัดแบตและลด Noise
    }
    
    // 🟢 ฟังก์ชันขอสิทธิ์ (requestPermission)
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // 🟢 ฟังก์ชันเริ่มดึงพิกัด (startUpdatingLocation)
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    // 🟢 ฟังก์ชันหยุดดึงพิกัด (stopUpdatingLocation)
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // Delegate เมื่อพิกัดเปลี่ยน
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location Error: \(error.localizedDescription)")
    }
}
