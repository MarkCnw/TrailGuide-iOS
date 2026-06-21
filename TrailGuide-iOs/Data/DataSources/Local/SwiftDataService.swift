import Foundation

class SwiftDataService {
    // ฟังก์ชันสำหรับเตรียมพื้นที่จัดเก็บข้อมูล
    static func setupStorage() {
        let fileManager = FileManager.default
        // ค้นหาตำแหน่ง Application Support Directory
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            // ถ้ายังไม่มีโฟลเดอร์นี้ ให้สร้างขึ้นมา
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                do {
                    try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
                    print("✅ Created Application Support directory")
                } catch {
                    print("❌ Failed to create directory: \(error)")
                }
            }
        }
    }
}
