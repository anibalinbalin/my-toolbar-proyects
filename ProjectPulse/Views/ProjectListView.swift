import SwiftUI
import AppKit

struct ProjectListView: View {
    let projects: [Project]
    let scanPath: String
    enum Tab: String, CaseIterable {
        case pinned = "Pinned"
        case all = "All"
    }
    @State private var selectedTab: Tab = .all

    private var sleepingCount: Int {
        projects.filter { $0.freshnessLevel == .sleeping }.count
    }

    private var hiddenCount: Int {
        AppSettings.shared.hiddenPaths.count
    }

    private var filteredProjects: [Project] {
        switch selectedTab {
        case .pinned:
            return projects.filter { AppSettings.shared.isPinned(path: $0.path) }
        case .all:
            return projects.filter { !AppSettings.shared.isPinned(path: $0.path) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0x888888))
                    .tracking(0.5)
                Spacer()
                Text(scanPath.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x555555))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Divider()
                .background(Color.white.opacity(0.06))

            // Tab picker
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .white : Color(hex: 0x555555))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            // Project list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredProjects.sorted()) { project in
                        ProjectRowView(project: project, onTap: {
                            openTerminal(at: project.path)
                        })
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            Divider()
                .background(Color.white.opacity(0.06))

            // Footer
            HStack {
                Text("\(projects.count) projects · \(sleepingCount) sleeping")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x555555))

                if hiddenCount > 0 {
                    Button("\(hiddenCount) hidden") {
                        AppSettings.shared.unhideAll()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x555555))
                    .underline()
                }

                Spacer()

                Button("+") {
                    addFolderAndPin()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: 0x555555))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

        }
        .frame(width: 340)
        .onReceive(NotificationCenter.default.publisher(for: .switchToPinnedTab)) { _ in
            selectedTab = .pinned
        }
    }

    private func addFolderAndPin() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.message = "Select folders to pin"
        if panel.runModal() == .OK {
            for url in panel.urls {
                let name = url.lastPathComponent
                let path = url.path
                AppSettings.shared.addManualProject(name: name, path: path)
                AppSettings.shared.pin(path: path)
            }
            selectedTab = .pinned
        }
    }

    private func openTerminal(at path: String) {
        _ = try? ShellCommand.run("/usr/bin/open", arguments: ["-a", "Ghostty", path])
    }
}
