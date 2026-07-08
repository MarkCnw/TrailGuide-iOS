<p align="center">
  <img width="200" alt="TrailGuide Logo" src="https://github.com/user-attachments/assets/d141d71f-eb0b-4de7-8a4c-b0db04ce7627" />
</p>

<h1 align="center">
  TrailGuide: ระบบนำทางย้อนกลับสำหรับนักเดินป่า
</h1>

<p align="center">
  <strong>แอปพลิเคชัน iOS แบบ Native สำหรับนักเดินป่า ที่ช่วยบันทึกเส้นทางและนำทางย้อนกลับอย่างชาญฉลาด แม้ไม่มีสัญญาณอินเทอร์เน็ต</strong>
</p>

<p align="center">
  ออกแบบภายใต้แนวคิด <strong>Offline-First</strong> และ <strong>Privacy-First</strong> โดยประมวลผลและจัดเก็บข้อมูลการเดินทางทั้งหมดภายในอุปกรณ์ (<strong>100% On-Device</strong>) โดยไม่พึ่งพาเซิร์ฟเวอร์หรือการเชื่อมต่ออินเทอร์เน็ต
</p>

<p align="center">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17.0+-black?logo=apple">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9+-orange?logo=swift">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-blue?logo=swift">
  <img alt="Architecture" src="https://img.shields.io/badge/Architecture-Clean_Architecture-4CAF50">
  <img alt="MVVM" src="https://img.shields.io/badge/Pattern-MVVM-purple">
  <img alt="MapKit" src="https://img.shields.io/badge/Map-MapKit-success">
  <img alt="SwiftData" src="https://img.shields.io/badge/Database-SwiftData-red">
</p>

---

# 📖 ภาพรวมโปรเจกต์

TrailGuide เป็นแอปพลิเคชัน iOS ที่พัฒนาด้วย **Swift** และ **SwiftUI** เพื่อเพิ่มความปลอดภัยให้กับนักเดินป่าที่เดินทางเพียงลำพัง หรือเดินในพื้นที่ที่ไม่มีสัญญาณโทรศัพท์

ระบบทำหน้าที่เสมือน **Digital Breadcrumb** โดยบันทึกตำแหน่ง GPS อย่างต่อเนื่อง พร้อมกรองสัญญาณรบกวนของ GPS เพื่อให้ได้เส้นทางที่แม่นยำที่สุด

เมื่อผู้ใช้ต้องการเดินกลับ ระบบจะสร้างเส้นทางย้อนกลับ (Backtrack Navigation) จากข้อมูลที่บันทึกไว้ พร้อมติดตามตำแหน่งของผู้ใช้แบบเรียลไทม์ หากผู้ใช้ออกจากเส้นทาง ระบบจะแจ้งเตือนทั้งข้อความบนหน้าจอและเสียงพูดผ่าน Text-to-Speech (TTS)

ข้อมูลการเดินทางทั้งหมด เช่น เส้นทาง ระยะทาง และประวัติการเดินทาง จะถูกจัดเก็บไว้ภายในเครื่องด้วย **SwiftData** ทำให้สามารถใช้งานได้แบบออฟไลน์ พร้อมรักษาความเป็นส่วนตัวของผู้ใช้อย่างสมบูรณ์

---

# ✨ จุดเด่นของระบบ

- 🗺️ บันทึกเส้นทางแบบ Real-time ด้วย MapKit และ CoreLocation
- 🎯 ระบบกรองสัญญาณ GPS หลายขั้นตอนเพื่อลดความคลาดเคลื่อน
- ↩️ สร้างเส้นทางย้อนกลับ (Backtrack Navigation) แบบอัตโนมัติ
- 🚨 ตรวจจับเมื่อผู้ใช้ออกจากเส้นทางแบบเรียลไทม์
- 🗣️ แจ้งเตือนด้วยเสียง (Text-to-Speech) และ Notification Banner
- 🔋 ปรับความแม่นยำของ GPS อัตโนมัติเพื่อประหยัดพลังงาน
- 🏛️ พัฒนาด้วย Clean Architecture และ MVVM

---

# 🚀 ตัวอย่างการทำงานของแอป

## 📍 Smart Route Tracking
ระหว่างการเดินป่า ระบบจะบันทึกตำแหน่ง GPS อย่างต่อเนื่อง พร้อมกรองสัญญาณรบกวนและลดความแกว่งของตำแหน่ง เพื่อสร้างเส้นทางที่มีความแม่นยำสูง

<p align="center">
  <img width="250" alt="Smart Route Tracking" src="https://github.com/user-attachments/assets/abd8ef9c-b05a-4efb-99ea-a11d7c0624d0" />
</p>

---

## ↩️ Backtrack Navigation
เมื่อผู้ใช้ต้องการเดินกลับ ระบบจะสร้างเส้นทางย้อนกลับจากข้อมูลที่บันทึกไว้ พร้อมลดจำนวนจุดที่ไม่จำเป็น (Path Simplification) และแสดงเส้นนำทางบนแผนที่เพื่อช่วยนำกลับสู่จุดเริ่มต้น

<p align="center">
  <img width="250" alt="Backtrack Navigation" src="https://github.com/user-attachments/assets/d6f6dda6-4b07-4324-a9bc-21110feed802" />
</p>

---

## 🚨 Off-Route Detection & Voice Alert
หากผู้ใช้ออกจากเส้นทางย้อนกลับเกินระยะที่กำหนด ระบบจะแสดงแถบแจ้งเตือนสีแดง พร้อมแจ้งเตือนด้วยเสียงผ่าน Text-to-Speech เพื่อให้กลับเข้าสู่เส้นทางที่ถูกต้อง

<p align="center">
  <img width="250" alt="Off-Route Detection" src="https://github.com/user-attachments/assets/ce730205-63dc-4d07-b946-1a1381a9a75b" />
</p>

---

## 🗺️ Trip History
เมื่อสิ้นสุดการเดินทาง ระบบจะบันทึกข้อมูลทั้งหมด เช่น ระยะทาง ระยะเวลา และเส้นทางการเดิน ลงในฐานข้อมูลภายในเครื่องด้วย SwiftData โดยอัตโนมัติ เพื่อให้สามารถย้อนดูประวัติการเดินทางได้ในภายหลัง

<p align="center">
  <img width="230" alt="Trip History 1" src="https://github.com/user-attachments/assets/9c98824e-d833-4add-8f7b-e0227a231368" />
  &nbsp; &nbsp;
  <img width="230" alt="Trip History 2" src="https://github.com/user-attachments/assets/76c0c3b2-308a-43d6-ae75-3c699a1771d6" />
  &nbsp; &nbsp;
  <img width="230" alt="Trip History 3" src="https://github.com/user-attachments/assets/59a2ab48-b881-487a-9c34-e8bc72d5270b" />
</p>

---

# 🌟 ฟีเจอร์หลัก

| ฟีเจอร์ | รายละเอียด |
|----------|-------------|
| 🗺️ Smart Route Tracking | บันทึกเส้นทางการเดินแบบเรียลไทม์ด้วย MapKit และ CoreLocation |
| ↩️ Backtrack Navigation | สร้างเส้นทางย้อนกลับจากข้อมูลที่บันทึกไว้โดยอัตโนมัติ |
| 🎯 GPS Noise Reduction | กรองสัญญาณ GPS หลายขั้นตอนเพื่อเพิ่มความแม่นยำ |
| ⚠️ Off-Route Detection | ตรวจจับเมื่อผู้ใช้ออกจากเส้นทาง พร้อมแจ้งเตือนทันที |
| 🗣️ Voice & Banner Alert | แจ้งเตือนด้วยเสียง (TTS) และ Notification Banner |
| 🔋 Battery Optimization | ปรับความแม่นยำของ GPS อัตโนมัติเพื่อลดการใช้พลังงาน |
| 💾 On-Device Storage | จัดเก็บข้อมูลทั้งหมดภายในเครื่องด้วย SwiftData |

---

# 🛠️ เทคโนโลยีที่ใช้

| หมวดหมู่ | เทคโนโลยี |
|----------|-----------|
| ภาษา | Swift |
| UI Framework | SwiftUI |
| Architecture | Clean Architecture + MVVM |
| Database | SwiftData |
| แผนที่ | MapKit |
| ตำแหน่ง | CoreLocation |
| เสียง | AVFoundation (AVSpeechSynthesizer) |
| Notifications | UserNotifications |
| Reactive Programming | Combine |

---

# 🏛️ สถาปัตยกรรมของระบบ

TrailGuide พัฒนาด้วย **Clean Architecture** ร่วมกับ **MVVM** เพื่อแยกส่วนของ Presentation, Domain และ Data Layer อย่างชัดเจน ทำให้ระบบดูแลรักษา ทดสอบ และต่อยอดได้ง่าย

## Architecture Diagram

```text
                 SwiftUI Views
                       │
                       ▼
             ViewModels (@Observable)
                       │
                       ▼
                 Domain Use Cases
      (เช่น SaveTripUseCase, LocationCalculator)
                       │
                       ▼
             Repository Interfaces
           ┌───────────┴───────────┐
           ▼                       ▼
   Location Repository     TripHistory Repository
           │                       │
           ▼                       ▼
 CoreLocation Manager        SwiftData Context
      (Data Source)             (Data Source)
```

---

# 📂 โครงสร้างโปรเจกต์

```text
TrailGuide
│
├── App                 # App Entry Point & DI Container
├── Core                # Utilities เช่น คลาสคำนวณพิกัด (LocationCalculator)
├── Data
│   ├── DataSources     # LocationManager, LocalNotificationService
│   ├── Models          # SwiftData Schema (TripHistoryModel, UserProfileSchema)
│   └── Repositories    # Implementation ของ Repository Interfaces
├── Domain
│   ├── Entities        # Business Models (TripHistory, UserProfileEntity)
│   ├── Interfaces      # Repository Protocols
│   └── UseCases        # SaveTripUseCase, GetAllTripsUseCase
└── Presentation
    ├── Common          # Custom Alert, Components ส่วนกลาง
    └── Features
        ├── Breadcrumb  # หน้าจอแผนที่ลากเส้นและนำทางย้อนกลับ (Solo Hike)
        └── History     # หน้าจอแสดงรายการประวัติทริปและหน้ารายละเอียด
```

| โฟลเดอร์ | หน้าที่ |
|----------|---------|
| App | จุดเริ่มต้นและศูนย์รวมการทำ Dependency Injection ของแอปพลิเคชัน |
| Core | Utility ส่วนกลางและฟังก์ชันทางคณิตศาสตร์ที่ใช้ร่วมกันทั้งหมด |
| Data | ส่วนจัดการข้อมูลหลัก ประกอบด้วย Data Source, Model และ Repository |
| Domain | ชั้นเก็บ Business Logic หลักรวมถึง Entity และ Use Case ของระบบ |
| Presentation | ส่วนติดต่อผู้ใช้ ประกอบด้วย UI Views และ ViewModel ของแต่ละฟีเจอร์ |

---

# 🔄 กระบวนการประมวลผล GPS (GPS Pipeline)

ระบบมีการวาง Pipeline ใน `LocationRepositoryImpl` เพื่อกรองข้อมูลพิกัดดิบ (Raw GPS) จากฮาร์ดแวร์ก่อนส่งไปแสดงผล เพื่อป้องกันปัญหาสัญญาณกระโดดหรือคลาดเคลื่อนกลางป่าทึบ:

```text
📡 CoreLocation (ดึงพิกัด GPS ดิบจากฮาร์ดแวร์)
      │
      ▼
🎯 Accuracy Filter (เตะพิกัดทิ้งทันทีหากค่าความคลาดเคลื่อนแนวนอน > 35 เมตร)
      │
      ▼
🛑 Stationary Detection (ตรวจสอบความเร็วหาก < 0.5 m/s เกิน 30 วินาที จะหยุดบันทึกเพื่อกันจุดซ้อนทับ)
      │
      ▼
🚀 Speed Anomaly Detection (เตะจุดทิ้งหากความเร็วเดินป่าเกิน 15 km/h เพื่อกันพิกัดดีด)
      │
      ▼
📏 Distance Filter (บันทึกพิกัดถัดไปต่อเมื่อมีการขยับตัวห่างจากจุดเดิมไม่ต่ำกว่า 10 เมตร)
      │
      ▼
📈 Moving Average Smoothing (นำพิกัดล่าสุด 2 จุดมาหาค่าเฉลี่ยเคลื่อนที่เพื่อเกลี่ยเส้นให้เรียบ)
      │
      ▼
🗺️ MapKit Polyline Rendering (วาดเส้นทางที่ผ่านการกรองลงบนแผนที่แบบเนียนตา)
```

---

# ⚙️ ความท้าทายในการพัฒนา

| ความท้าทาย | วิธีแก้ไข | ผลลัพธ์ |
|------------|-----------|----------|
| **สัญญาณ GPS แกว่งและไม่แม่นยำ** | พัฒนา Pipeline สำหรับกรองสัญญาณหลายขั้นตอน พร้อมใช้ Moving Average Smoothing | เส้นทางที่แสดงบนแผนจะมีความเรียบและแม่นยำมากขึ้น ไม่เป็นเส้นซิกแซกกระโดดไปมา |
| **เส้นทางย้อนกลับมีจุดยิบย่อยจำนวนมาก** | ใช้ลอจิก `LocationCalculator.simplifyPath` กรองจุดเลี้ยวที่มุมเปลี่ยนไม่เกิน 30° | ช่วยลดจำนวนจุดที่ไม่จำเป็นลง ทำให้การนำทางย้อนกลับอ่านง่ายและประมวลผลเร็วขึ้น |
| **การตรวจจับการออกนอกเส้นทาง** | คำนวณหาค่าระยะห่างแบบตั้งฉาก (Cross-Track Distance) ระหว่างตำแหน่งผู้ใช้กับเส้นทางหลัก | แจ้งเตือนผู้ใช้ได้อย่างแม่นยำทันทีเมื่อเดินห่างออกจากพิกัดเดิมเกิน 5 เมตร |
| **การใช้พลังงานจาก GPS บนเขาระยะยาว** | ปรับระดับความแม่นยำของ CoreLocation ตามสถานะการใช้งาน (Battery Saving เมื่อเดินปกติ / High Accuracy เมื่อนำทางย้อนกลับ) | ลดการใช้แบตเตอรี่ในเวลาปกติ และให้ความแม่นยำสูงสุดเมื่อเปิดระบบนำทางย้อนกลับ |

---

# 🚀 การติดตั้ง

```bash
git clone [https://github.com/MarkCnw/TrailGuide-iOS.git](https://github.com/MarkCnw/TrailGuide-iOS.git)
cd TrailGuide-iOS
open TrailGuide.xcodeproj
```
