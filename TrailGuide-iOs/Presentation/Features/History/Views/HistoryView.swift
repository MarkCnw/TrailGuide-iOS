import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("ประวัติการเดินป่า")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("เส้นทางที่คุณเคยสำรวจจะมาแสดงที่นี่")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HistoryView()
}
