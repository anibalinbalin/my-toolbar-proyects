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
        // Both active: sort by freshness descending
        if lhs.freshness > 0 && rhs.freshness > 0 {
            if lhs.freshness != rhs.freshness {
                return lhs.freshness > rhs.freshness
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        // Active before sleeping
        if lhs.freshness > 0 { return true }
        if rhs.freshness > 0 { return false }
        // Both sleeping: sort by lastCommitDate descending (newest first, nil last)
        switch (lhs.lastCommitDate, rhs.lastCommitDate) {
        case let (l?, r?): return l > r
        case (_?, nil): return true
        case (nil, _?): return false
        default: return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
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

    static let activeColor = Color(hex: 0xE8863A)

    var barColors: (Color, Color) {
        switch self {
        case .fresh, .warm, .cooling: return (Self.activeColor, Self.activeColor)
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
