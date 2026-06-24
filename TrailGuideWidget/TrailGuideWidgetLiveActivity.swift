import ActivityKit
import WidgetKit
import SwiftUI



// 2. สร้างหน้าตา UI
struct TrailGuideWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrailAttributes.self) { context in
            // 🟢 หน้าตาตอนแสดงบน Lock Screen (หน้าจอล็อค)
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text("กำลังเดินย้อนกลับ")
                        .font(.headline)
                        .foregroundColor(.orange)
                    // ในส่วน VStack ของ TrailGuideWidgetLiveActivity.swift
                        Text("เหลือระยะทาง: \(context.state.distanceRemaining)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.black) // ✨ เพิ่มบังคับสีขาวตรงนี้
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(
                Color.white.opacity(0.6)
            ) // พื้นหลังสีดำโปร่งแสง
            
        } dynamicIsland: { context in
            // 🟢 หน้าตาตอนแสดงบน Dynamic Island (สำหรับ iPhone 14 Pro ขึ้นไป)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.distanceRemaining)
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("เดินย้อนกลับ")
                }
            } compactLeading: {
                Image(systemName: "arrow.uturn.backward").foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.distanceRemaining).foregroundColor(.orange)
            } minimal: {
                Image(systemName: "arrow.uturn.backward").foregroundColor(.orange)
            }
        }
    }
}
