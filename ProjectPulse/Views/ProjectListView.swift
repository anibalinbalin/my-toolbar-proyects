import SwiftUI

struct ProjectListView: View {
    let projects: [Project]
    let scanPath: String

    private var sleepingCount: Int {
        projects.filter { $0.freshnessLevel == .sleeping }.count
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

            // Project list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(projects.sorted()) { project in
                        ProjectRowView(project: project)
                            .onTapGesture {
                                openTerminal(at: project.path)
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 500)
            .scrollIndicators(.hidden)

            Divider()
                .background(Color.white.opacity(0.06))

            // Footer
            HStack {
                Text("\(projects.count) projects · \(sleepingCount) sleeping")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x555555))
                Spacer()
                Button("Settings ⌘,") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x555555))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 340)
        .background(Color(hex: 0x0e0e10))
    }

    private func openTerminal(at path: String) {
        _ = try? ShellCommand.run("/usr/bin/open", arguments: ["-a", "Terminal", path])
    }
}
