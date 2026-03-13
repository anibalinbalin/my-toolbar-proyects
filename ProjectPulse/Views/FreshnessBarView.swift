import SwiftUI

struct FreshnessBarView: View {
    let freshness: Double
    let level: FreshnessLevel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 3)

                if freshness > 0 {
                    let (start, end) = level.barColors
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(LinearGradient(
                            colors: [start, end],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * freshness, height: 3)
                        .animation(.spring(duration: 0.4, bounce: 0.1), value: freshness)
                }
            }
        }
        .frame(height: 3)
    }
}
