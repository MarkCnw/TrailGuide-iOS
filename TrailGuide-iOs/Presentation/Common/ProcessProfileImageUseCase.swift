import Foundation
import UIKit
import ImageIO

/// ย้ายมาจาก Domain → Presentation เพราะใช้ UIKit/ImageIO ล้วนๆ
/// ไม่ใช่ Business Logic แต่เป็น UI utility สำหรับบีบอัดภาพโปรไฟล์
class ProcessProfileImageUseCase {
    // 🟢 ย้ายโค้ด CoreGraphics สุดรกมาซ่อนไว้ที่นี่ ViewModel จะได้สะอาด
    func execute(fileName: String) async -> (image: UIImage, compressedData: Data)? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 150
        ]
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        let thumbImage = UIImage(cgImage: cgImage)
        
        // ลบพื้นหลังโปร่งใส (Alpha) ทิ้ง
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: thumbImage.size, format: format)
        let safeOpaqueImage = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: thumbImage.size))
            thumbImage.draw(in: CGRect(origin: .zero, size: thumbImage.size))
        }
        
        guard let compressedData = safeOpaqueImage.jpegData(compressionQuality: 0.4) else { return nil }
        
        return (safeOpaqueImage, compressedData)
    }
}
