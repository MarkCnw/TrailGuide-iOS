import Foundation

/// Protocol สำหรับการส่ง Local Notification
/// Domain Layer ใช้ Protocol นี้เพื่อไม่ต้องพึ่งพา UserNotifications framework โดยตรง
protocol NotificationServiceProtocol {
    /// ขอสิทธิ์การแจ้งเตือนจากผู้ใช้
    func requestPermission()
    /// ส่ง Notification ทันที
    func sendNotification(title: String, body: String)
    /// พูดข้อความออกเสียง (Text-to-Speech)
    func speak(_ text: String)
}
