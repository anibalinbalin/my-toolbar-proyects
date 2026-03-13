import SwiftUI
import AppKit

struct WindowResizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.styleMask.insert(.resizable)
                window.minSize = NSSize(width: 340, height: 200)
                window.maxSize = NSSize(width: 340, height: 900)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ProjectListView: View {
    let projects: [Project]
    let scanPath: String
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var newProjectPath = ""

    private var sleepingCount: Int {
        projects.filter { $0.freshnessLevel == .sleeping }.count
    }

    private var hiddenCount: Int {
        AppSettings.shared.hiddenPaths.count
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
                    newProjectName = ""
                    newProjectPath = ""
                    showingAddProject = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: 0x555555))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

        }
        .frame(width: 340)
        .background(WindowResizer())
        .popover(isPresented: $showingAddProject, arrowEdge: .bottom) {
            VStack(spacing: 12) {
                Text("Add Project")
                    .font(.system(size: 13, weight: .semibold))
                TextField("Name", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Path (optional)", text: $newProjectPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            newProjectPath = url.path
                            if newProjectName.isEmpty {
                                newProjectName = url.lastPathComponent
                            }
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button("Cancel") { showingAddProject = false }
                    Button("Add") {
                        guard !newProjectName.isEmpty else { return }
                        AppSettings.shared.addManualProject(
                            name: newProjectName,
                            path: newProjectPath.isEmpty ? newProjectName : newProjectPath
                        )
                        showingAddProject = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
            .frame(width: 300)
        }
    }

    private func openTerminal(at path: String) {
        _ = try? ShellCommand.run("/usr/bin/open", arguments: ["-a", "Ghostty", path])
    }
}
