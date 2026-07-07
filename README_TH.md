<p align="center">
  <img width="363" alt="TrailGuide Logo" src="https://github.com/user-attachments/assets/d141d71f-eb0b-4de7-8a4c-b0db04ce7627" />
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
  <img width="250" src="https://github.com/user-attachments/assets/36309ff7-da1d-4004-8399-ff1b9ece1046"/>
</p>

---

## ↩️ Backtrack Navigation

เมื่อผู้ใช้ต้องการเดินกลับ ระบบจะสร้างเส้นทางย้อนกลับจากข้อมูลที่บันทึกไว้ พร้อมลดจำนวนจุดที่ไม่จำเป็น (Path Simplification) และแสดงเส้นนำทางบนแผนที่เพื่อช่วยนำกลับสู่จุดเริ่มต้น

<p align="center">
  <img width="250" src="https://github.com/user-attachments/assets/050132d6-bd15-4a9b-ac8d-84349ca43c5a"/>
</p>

---

## 🚨 Off-Route Detection & Voice Alert

หากผู้ใช้ออกจากเส้นทางย้อนกลับเกินระยะที่กำหนด ระบบจะแสดงแถบแจ้งเตือนสีแดง พร้อมแจ้งเตือนด้วยเสียงผ่าน Text-to-Speech เพื่อให้กลับเข้าสู่เส้นทางที่ถูกต้อง

<p align="center">
  <img width="250" src="https://github.com/user-attachments/assets/886b1088-2032-4c3a-8b11-1b5c1932ea6e"/>
  &nbsp;&nbsp;&nbsp;
  <img width="250" src="https://github.com/user-attachments/assets/6980f168-bcc4-4d35-bd5a-9ab4b880ae56"/>
</p>

---

## 🗺️ Trip History

เมื่อสิ้นสุดการเดินทาง ระบบจะบันทึกข้อมูลทั้งหมด เช่น ระยะทาง ระยะเวลา และเส้นทางการเดิน ลงในฐานข้อมูลภายในเครื่องโดยอัตโนมัติ เพื่อให้สามารถย้อนดูประวัติการเดินทางได้ในภายหลัง

<p align="center">
  <img width="250" src="https://github.com/user-attachments/assets/1f43464f-eb90-44b1-8ee7-58ec75824c52"/>
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
├── App
├── Core
│   └── Utils
├── Data
│   ├── DataSources
│   ├── Models
│   └── Repositories
├── Domain
│   ├── Entities
│   ├── Interfaces
│   └── UseCases
└── Presentation
    ├── Common
    └── Features
        ├── Breadcrumb
        └── History
```

| โฟลเดอร์ | หน้าที่ |
|----------|---------|
| App | จุดเริ่มต้นของแอปพลิเคชัน |
| Core | Utility และฟังก์ชันที่ใช้ร่วมกัน |
| Data | Data Source, Model และ Repository |
| Domain | Business Logic, Entity และ Use Case |
| Presentation | UI และ ViewModel ของแต่ละฟีเจอร์ |

---

# 🔄 กระบวนการประมวลผล GPS

```text
📡 CoreLocation (Raw GPS)
      │
      ▼
🎯 Accuracy Filter
      │
      ▼
🛑 Stationary Detection
      │
      ▼
🚀 Speed Anomaly Detection
      │
      ▼
📏 Moving Average Smoothing
      │
      ▼
🗺️ MapKit Polyline Rendering
```

---

# ⚙️ ความท้าทายในการพัฒนา

| ความท้าทาย | วิธีแก้ไข | ผลลัพธ์ |
|------------|-----------|----------|
| สัญญาณ GPS แกว่งและไม่แม่นยำ | พัฒนา Pipeline สำหรับกรองสัญญาณหลายขั้นตอน พร้อมใช้ Moving Average Smoothing | เส้นทางที่แสดงบนแผนที่มีความเรียบและแม่นยำมากขึ้น |
| เส้นทางย้อนกลับมีจุดจำนวนมาก | ใช้ Path Simplification เพื่อลดจำนวน Waypoints | นำทางย้อนกลับได้ง่ายและอ่านแผนที่สะดวกขึ้น |
| การตรวจจับการออกนอกเส้นทาง | คำนวณ Cross-Track Distance จากเส้นทางเดิม | แจ้งเตือนผู้ใช้ได้อย่างแม่นยำเมื่อออกนอกเส้นทาง |
| การใช้พลังงานจาก GPS | ปรับระดับความแม่นยำของ CoreLocation ตามสถานะการใช้งาน | ลดการใช้แบตเตอรี่โดยไม่กระทบต่อประสิทธิภาพการนำทาง |

---

# 🚀 การติดตั้ง

```bash
git clone https://github.com/MarkCnw/TrailGuide-iOS.git
cd TrailGuide-iOS
open TrailGuide.xcodeproj
```
