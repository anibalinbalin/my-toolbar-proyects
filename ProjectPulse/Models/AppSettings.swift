import Foundation
import Observation

@Observable
class AppSettings {
    static let shared = AppSettings()

    var scanPath: String {
        didSet { UserDefaults.standard.set(scanPath, forKey: "scanPath") }
    }

    var refreshInterval: TimeInterval {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }

    var decayDays: Double {
        didSet { UserDefaults.standard.set(decayDays, forKey: "decayDays") }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.scanPath = defaults.string(forKey: "scanPath") ?? NSHomeDirectory() + "/Sites/2026"
        self.refreshInterval = defaults.double(forKey: "refreshInterval").nonZero ?? 60
        self.decayDays = defaults.double(forKey: "decayDays").nonZero ?? 7
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
