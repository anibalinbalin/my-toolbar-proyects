import SwiftUI
import Foundation

struct Project: Identifiable, Comparable {
    var id: String { path }
    let name: String
    let path: String
    let lastCommitDate: Date?
    let branch: String?
    let lastCommitMessage: String?
    var decayDays: Double = 7.0

    var freshness: Double {
        guard let date = lastCommitDate else { return 0.0 }
        let days = -date.timeIntervalSinceNow / (24 * 3600)
        return max(0.0, 1.0 - (days / decayDays))
    }

    var freshnessLevel: FreshnessLevel {
        switch freshness {
        case 0.7...: return .fresh
        case 0.4..<0.7: return .warm
        case 0.01..<0.4: return .cooling
        default: return .sleeping
        }
    }

    static func < (lhs: Project, rhs: Project) -> Bool {
        if lhs.freshness != rhs.freshness {
            return lhs.freshness > rhs.freshness
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    static func relativeDate(from date: Date?) -> String {
        guard let date else { return "never" }
        let seconds = -date.timeIntervalSinceNow
        let hours = seconds / 3600
        let days = seconds / (24 * 3600)
        if hours < 1 { return "just now" }
        if days < 1 { return "\(Int(hours))h ago" }
        return "\(Int(days))d ago"
    }
}

enum FreshnessLevel {
    case fresh, warm, cooling, sleeping

    var barColors: (Color, Color) {
        switch self {
        case .fresh: return (Color(hex: 0x22c55e), Color(hex: 0x4ade80))
        case .warm: return (Color(hex: 0xeab308), Color(hex: 0xfacc15))
        case .cooling: return (Color(hex: 0xf97316), Color(hex: 0xfb923c))
        case .sleeping: return (.clear, .clear)
        }
    }

    var nameOpacity: Double {
        self == .sleeping ? 0.5 : 1.0
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
