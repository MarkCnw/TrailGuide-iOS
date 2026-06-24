import Foundation
import UserNotifications
import AVFoundation

/// Implementation ของ NotificationServiceProtocol ที่ใช้ UserNotifications framework ของ Apple
/// และ AVSpeechSynthesizer สำหรับ Text-to-Speech
final class LocalNotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        // 🟢 ตั้งตัวเองเป็น Delegate เพื่อให้ Notification เด้งได้แม้แอปเปิดอยู่ (Foreground)
        notificationCenter.delegate = self
        
        // 🟢 ตั้งค่า Audio Session ตั้งแต่ตอนเริ่มต้น เพื่อให้ TTS พร้อมใช้งานทันที
        configureAudioSession()
    }
    
    // ==========================================
    // 🔔 UNUserNotificationCenterDelegate
    // ==========================================
    
    /// ✅ FIX Bug #2: บอก iOS ว่า "ให้แสดง Notification เด้งขึ้นมาทั้งเสียงและ Banner แม้แอปจะเปิดอยู่"
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // ==========================================
    // 🔑 Permission
    // ==========================================
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")
            }
        }
    }
    
    // ==========================================
    // 📩 Send Notification
    // ==========================================
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    // ==========================================
    // 🗣️ Text-to-Speech
    // ==========================================
    
    func speak(_ text: String) {
        // หยุดเสียงที่กำลังพูดอยู่ก่อน (ถ้ามี) เพื่อไม่ให้ซ้อนกัน
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // ✅ FIX Bug #3: ตั้ง Audio Session ใหม่ทุกครั้งก่อนพูด เพื่อให้แน่ใจว่า session active
        configureAudioSession()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "th-TH") // 🇹🇭 เสียงภาษาไทย
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        // 🟢 เพิ่ม delay เล็กน้อยก่อนพูด เพื่อให้ Audio Session พร้อมจริงๆ
        utterance.preUtteranceDelay = 0.3
        
        synthesizer.speak(utterance)
    }
    
    // ==========================================
    // 🔧 Private Helpers
    // ==========================================
    
    private func configureAudioSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .voicePrompt, options: .duckOthers)
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("⚠️ AVAudioSession error: \(error.localizedDescription)")
            }
        }
    }
}
