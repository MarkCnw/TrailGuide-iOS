import Foundation
import CoreLocation

@Observable
final class HistoryViewModel {
    
    // 📋 รายการทริปทั้งหมด
    var trips: [TripHistory] = []
    
    // พนักงานฐานข้อมูล
    private let tripRepository: TripHistoryRepositoryProtocol
    
    // 🤝 รับ Repository เข้ามาผ่าน init (Dependency Injection)
    init(tripRepository: TripHistoryRepositoryProtocol) {
        self.tripRepository = tripRepository
        loadTrips()
    }
    
    // 📥 โหลดทริปทั้งหมดจากฐานข้อมูล (เรียงจากใหม่ → เก่า)
    func loadTrips() {
        trips = tripRepository.getAllTrips()
            .sorted { $0.date > $1.date }
    }
    
    // ✏️ เปลี่ยนชื่อทริป
    func updateTripName(id: Int, newName: String) {
        tripRepository.updateTripName(id: id, newName: newName)
        loadTrips() // โหลดใหม่เพื่ออัพเดทหน้าจอ
    }
    
    // 🗑️ ลบทริป
    func deleteTrip(id: Int) {
        tripRepository.deleteTrip(id: id)
        loadTrips() // โหลดใหม่เพื่ออัพเดทหน้าจอ
    }
    
    // 🕐 แปลง duration (วินาที) เป็นข้อความอ่านง่าย
    func formattedDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours) ชม. \(minutes) นาที"
        } else if minutes > 0 {
            return "\(minutes) นาที"
        } else {
            return "น้อยกว่า 1 นาที"
        }
    }
    
    // 📏 แปลง distance (เมตร) เป็นข้อความอ่านง่าย
    func formattedDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f กม.", distance / 1000)
        } else {
            return String(format: "%.0f ม.", distance)
        }
    }
    
    // 📅 แปลง Date เป็นข้อความวันที่ภาษาไทย
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
