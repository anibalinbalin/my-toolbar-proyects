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

    var listHeight: Double {
        didSet { UserDefaults.standard.set(listHeight, forKey: "listHeight") }
    }

    var hiddenPaths: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenPaths), forKey: "hiddenPaths") }
    }

    var pinnedPaths: Set<String> {
        didSet { UserDefaults.standard.set(Array(pinnedPaths), forKey: "pinnedPaths") }
    }

    var manualProjects: [[String: String]] {
        didSet { UserDefaults.standard.set(manualProjects, forKey: "manualProjects") }
    }

    func hide(path: String) {
        hiddenPaths.insert(path)
    }

    func unhideAll() {
        hiddenPaths.removeAll()
    }

    func pin(path: String) {
        pinnedPaths.insert(path)
    }

    func unpin(path: String) {
        pinnedPaths.remove(path)
    }

    func isPinned(path: String) -> Bool {
        pinnedPaths.contains(path)
    }

    func togglePin(path: String) {
        if isPinned(path: path) { unpin(path: path) } else { pin(path: path) }
    }

    func addManualProject(name: String, path: String) {
        manualProjects.append(["name": name, "path": path])
    }

    func removeManualProject(at index: Int) {
        manualProjects.remove(at: index)
    }

    private init() {
        let defaults = UserDefaults.standard
        self.scanPath = defaults.string(forKey: "scanPath") ?? NSHomeDirectory() + "/Sites/2026"
        self.refreshInterval = defaults.double(forKey: "refreshInterval").nonZero ?? 60
        self.decayDays = defaults.double(forKey: "decayDays").nonZero ?? 7
        self.listHeight = defaults.double(forKey: "listHeight").nonZero ?? 400
        self.hiddenPaths = Set(defaults.stringArray(forKey: "hiddenPaths") ?? [])
        self.pinnedPaths = Set(defaults.stringArray(forKey: "pinnedPaths") ?? [])
        self.manualProjects = (defaults.array(forKey: "manualProjects") as? [[String: String]]) ?? []
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
