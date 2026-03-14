import SwiftUI
import Observation
import ObjectiveC

@Observable
class ProjectStore {
    var projects: [Project] = []
    private let settings = AppSettings.shared
    private var refreshTask: Task<Void, Never>?

    init() {
        startRefreshing()
    }

    func startRefreshing() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(settings.refreshInterval))
            }
        }
    }

    func refresh() async {
        let repoPaths = GitScanner.scan(directory: settings.scanPath)
        let decay = settings.decayDays
        let hidden = settings.hiddenPaths
        var newProjects = repoPaths.compactMap { path -> Project? in
            guard !hidden.contains(path) else { return nil }
            guard var project = try? GitInfoProvider.info(for: path) else { return nil }
            project.decayDays = decay
            return project
        }

        // Merge manual projects
        let gitPaths = Set(newProjects.map(\.path))
        for entry in settings.manualProjects {
            guard let name = entry["name"], let path = entry["path"] else { continue }
            if hidden.contains(path) { continue }
            // If it now has a .git dir, let git-based tracking handle it
            if gitPaths.contains(path) { continue }
            // Check if it became a git repo since being added
            let gitDir = (path as NSString).appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitDir) {
                if var project = try? GitInfoProvider.info(for: path) {
                    project.decayDays = decay
                    newProjects.append(project)
                    continue
                }
            }
            newProjects.append(Project(
                name: name, path: path, lastCommitDate: nil,
                branch: nil, lastCommitMessage: nil, decayDays: decay
            ))
        }

        let result = newProjects
        await MainActor.run {
            self.projects = result
        }
    }

    var iconColor: Color {
        let hasActive = projects.contains { $0.freshnessLevel != .sleeping }
        return hasActive ? FreshnessLevel.activeColor : Color(hex: 0x555555)
    }
}

private func spiralIcon(color: Color) -> NSImage {
    let size: CGFloat = 18
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let ctx = NSGraphicsContext.current!.cgContext
        let center = CGPoint(x: size / 2, y: size / 2)
        let path = CGMutablePath()
        let turns: CGFloat = 2.5
        let steps = 120
        let maxRadius: CGFloat = size / 2 - 1

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = t * turns * 2 * .pi
            let r = t * maxRadius
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        let nsColor = NSColor(color)
        ctx.setStrokeColor(nsColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)
        ctx.addPath(path)
        ctx.strokePath()
        return true
    }
    image.isTemplate = false
    return image
}

// MARK: - DraggableStatusBarButton (isa-swizzled onto NSStatusBarButton)

private var appDelegateKey: UInt8 = 0

class DraggableStatusBarButton: NSStatusBarButton {

    var dropDelegate: AppDelegate? {
        get { objc_getAssociatedObject(self, &appDelegateKey) as? AppDelegate }
        set { objc_setAssociatedObject(self, &appDelegateKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let hasDirs = hasDirectories(in: sender)
        if hasDirs { self.image = spiralIcon(color: Color(hex: 0x888888)) }
        return hasDirs ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return hasDirectories(in: sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.image = spiralIcon(color: .white)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.image = spiralIcon(color: .white)
        guard let urls = directoryURLs(from: sender), !urls.isEmpty else { return false }
        dropDelegate?.handleDrop(urls: urls)
        return true
    }

    private func hasDirectories(in info: NSDraggingInfo) -> Bool {
        guard let urls = directoryURLs(from: info) else { return false }
        return !urls.isEmpty
    }

    private func directoryURLs(from info: NSDraggingInfo) -> [URL]? {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]) as? [URL] else { return nil }
        return items.filter { url in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
}

// MARK: - PopoverContentView

struct PopoverContentView: View {
    let store: ProjectStore

    var body: some View {
        ProjectListView(
            projects: store.projects,
            scanPath: AppSettings.shared.scanPath
        )
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let store = ProjectStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = spiralIcon(color: .white)
            button.action = #selector(togglePopover)
            button.target = self

            // Isa-swizzle the button to our DraggableStatusBarButton subclass
            object_setClass(button, DraggableStatusBarButton.self)
            button.registerForDraggedTypes([.fileURL])
            (button as? DraggableStatusBarButton)?.dropDelegate = self


        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView(store: store)
        )

        trackIconColor()
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func handleDrop(urls: [URL]) {
        let settings = AppSettings.shared
        for url in urls {
            settings.addManualProject(name: url.lastPathComponent, path: url.path)
            settings.pin(path: url.path)
        }
        Task { await store.refresh() }

        // Show popover on Pinned tab
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
        NotificationCenter.default.post(name: .switchToPinnedTab, object: nil)
    }

    private func trackIconColor() {
        // Icon is always white; observation kept for future use
    }
}

extension Notification.Name {
    static let switchToPinnedTab = Notification.Name("switchToPinnedTab")
}

// MARK: - App Entry Point

@main
struct ProjectPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
