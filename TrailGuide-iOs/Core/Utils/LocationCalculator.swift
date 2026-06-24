import Foundation
import CoreLocation

enum LocationCalculator {
    
    // 🧮 1. คำนวณระยะทาง (แบบใช้ CLLocationCoordinate2D)
    static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2)
    }
    
    // 🧮 2. คำนวณทิศทาง (องศา)
    static func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180.0
        let lon1 = from.longitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let lon2 = to.longitude * .pi / 180.0
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180.0 / .pi
        return (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
    
    // 🧮 3. หาระยะตั้งฉาก (Cross-Track Distance) เพื่อเช็คว่าหลงทางไหม
    static func crossTrackDistance(point: CLLocationCoordinate2D, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Double {
        let latToMeters = 111111.0
        let lonToMeters = cos(point.latitude * .pi / 180.0) * 111111.0
        
        let px = (point.longitude - start.longitude) * lonToMeters
        let py = (point.latitude - start.latitude) * latToMeters
        let ex = (end.longitude - start.longitude) * lonToMeters
        let ey = (end.latitude - start.latitude) * latToMeters
        
        let e2 = ex*ex + ey*ey
        if e2 == 0.0 { return sqrt(px*px + py*py) }
        
        let t = max(0.0, min(1.0, (px*ex + py*ey) / e2))
        let projX = t * ex
        let projY = t * ey
        
        let dx = px - projX
        let dy = py - projY
        return sqrt(dx*dx + dy*dy)
    }
    
    // 🧮 4. ลดทอนจุด (Waypoint Simplification) เอาลูปยาวๆ มาซ่อนไว้ที่นี่
    static func simplifyPath(_ path: [CLLocationCoordinate2D], spacing: Double, bearingThreshold: Double) -> [CLLocationCoordinate2D] {
        guard !path.isEmpty else { return [] }
        
        var simplifiedPath: [CLLocationCoordinate2D] = []
        let first = path[0]
        simplifiedPath.append(first)
        
        var lastAdded = first
        var lastBearing: Double?
        
        for i in 1..<(path.count - 1) {
            let current = path[i]
            let distance = calculateDistance(from: lastAdded, to: current)
            let bearing = calculateBearing(from: lastAdded, to: current)
            var bearingChangedEnough = false
            
            if let lastB = lastBearing {
                let diff = abs(bearing - lastB)
                let normalizedDiff = diff > 180 ? 360 - diff : diff
                if normalizedDiff > bearingThreshold {
                    bearingChangedEnough = true
                }
            }
            
            if distance >= spacing || bearingChangedEnough {
                simplifiedPath.append(current)
                lastAdded = current
                lastBearing = bearing
            }
        }
        
        if let last = path.last {
            if simplifiedPath.last?.latitude != last.latitude || simplifiedPath.last?.longitude != last.longitude {
                simplifiedPath.append(last)
            }
        }
        
        return simplifiedPath
    }
}
