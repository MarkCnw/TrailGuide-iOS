import Foundation
import SwiftData // 🟢 1. นำเข้า SwiftData

@Model
class TripHistoryModel { // 🟢 2. เอาคำว่า : Model ออก
    var id: Int?
    var name: String
    var date: Date
    var distance: Double
    var duration: Int
    var routePath: String
    
    init(
        id: Int? = nil,
        name: String,
        date: Date,
        distance: Double,
        duration: Int,
        routePath: String
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.routePath = routePath
    }
}
