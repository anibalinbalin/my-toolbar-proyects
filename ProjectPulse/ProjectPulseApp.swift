import SwiftUI

@main
struct ProjectPulseApp: App {
    @State private var projects: [Project] = []
    private let settings = AppSettings.shared

    private var iconColor: Color {
        let best = projects.sorted().first?.freshnessLevel ?? .sleeping
        return best.barColors.0 == .clear ? Color(hex: 0x555555) : best.barColors.0
    }

    var body: some Scene {
        MenuBarExtra {
            ProjectListView(projects: projects, scanPath: settings.scanPath)
                .task {
                    while !Task.isCancelled {
                        await refreshProjects()
                        try? await Task.sleep(for: .seconds(settings.refreshInterval))
                    }
                }
        } label: {
            Image(systemName: "circle.fill")
                .foregroundColor(iconColor)
                .font(.system(size: 8))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }

    private func refreshProjects() async {
        let repoPaths = GitScanner.scan(directory: settings.scanPath)
        let decay = settings.decayDays
        let newProjects = repoPaths.compactMap { path -> Project? in
            guard var project = try? GitInfoProvider.info(for: path) else { return nil }
            project.decayDays = decay
            return project
        }
        await MainActor.run {
            projects = newProjects
        }
    }
}
