import Foundation
import SwiftData
import CoreLocation // 🟢 นำเข้า CoreLocation เพื่อใช้พิกัดแผนที่

class TripHistoryRepositoryImpl: TripHistoryRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveTrip(_ trip: TripHistory) {
        // 📝 1. แปลงเส้นทาง Array ให้เป็น String แบบ JSON
        var routeString = "[]"
        let codableRoute = trip.routePath.map { ["lat": $0.latitude, "lng": $0.longitude] }
        if let jsonData = try? JSONSerialization.data(withJSONObject: codableRoute),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            routeString = jsonString
        }
        
        // 📝 2. ลอกข้อมูลใส่ตาราง SwiftData
        let modelToSave = TripHistoryModel(
            id: trip.id,
            name: trip.name,
            date: trip.date,
            distance: trip.distance,
            duration: Int(trip.duration), // แปลง Double กลับเป็น Int ให้ตรงกับ Model
            routePath: routeString
        )
        
        // 📥 3. สั่งเซฟลงฐานข้อมูล
        modelContext.insert(modelToSave)
        try? modelContext.save()
    }
    
    func getAllTrips() -> [TripHistory] {
        // 🔍 1. ค้นหาข้อมูลจากตาราง
        let descriptor = FetchDescriptor<TripHistoryModel>()
        let fetchedModels = (try? modelContext.fetch(descriptor)) ?? []
        
        // 📦 2. แปลงกลับมาเป็น TripHistory ของหน้าจอ
        return fetchedModels.map { model in
            
            // แปลง String JSON กลับมาเป็น Array พิกัด
            var path: [CLLocationCoordinate2D] = []
            if let jsonData = model.routePath.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Double]] {
                path = jsonArray.compactMap { dict in
                    if let lat = dict["lat"], let lng = dict["lng"] {
                        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    }
                    return nil
                }
            }
            
            return TripHistory(
                id: model.id ?? Int.random(in: 1...99999),
                name: model.name,
                date: model.date,
                distance: model.distance,
                duration: Double(model.duration),
                routePath: path
            )
        }
    }
    
    func updateTripName(id: Int, newName: String) {
        // 🔍 1. ค้นหาทริปที่ต้องการจาก ID
        let descriptor = FetchDescriptor<TripHistoryModel>()
        guard let fetchedModels = try? modelContext.fetch(descriptor),
              let model = fetchedModels.first(where: { $0.id == id }) else {
            return
        }
        
        // ✏️ 2. เปลี่ยนชื่อแล้วเซฟ
        model.name = newName
        try? modelContext.save()
    }
    
    func deleteTrip(id: Int) {
        // 🔍 1. ค้นหาทริปที่ต้องการจาก ID
        let descriptor = FetchDescriptor<TripHistoryModel>()
        guard let fetchedModels = try? modelContext.fetch(descriptor),
              let model = fetchedModels.first(where: { $0.id == id }) else {
            return
        }
        
        // 🗑️ 2. ลบออกจากฐานข้อมูล
        modelContext.delete(model)
        try? modelContext.save()
    }
}
