import Foundation

protocol TripHistoryRepositoryProtocol {
    // 1. ฟังก์ชันรับสมุดไดอารี่ (TripHistory) มาบันทึก
    func saveTrip(_ trip: TripHistory)
    
    // 2. ฟังก์ชันขอเบิกสมุดไดอารี่ "ทั้งหมด" ออกมาดู (คืนค่ากลับมาเป็น Array ของ TripHistory)
    func getAllTrips() -> [TripHistory]
    
    // 3. ฟังก์ชันเปลี่ยนชื่อทริป
    func updateTripName(id: Int, newName: String)
    
    // 4. ฟังก์ชันลบทริป
    func deleteTrip(id: Int)
}
