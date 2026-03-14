import SwiftUI

struct ProjectRowView: View {
    let project: Project
    var onTap: (() -> Void)?
    @State private var isHovered = false

    private static let vsCodePath: String? = {
        let candidates = [
            "/usr/local/bin/code",
            "/opt/homebrew/bin/code",
            NSHomeDirectory() + "/.local/bin/code"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }()

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(project.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(project.freshnessLevel.nameOpacity))
                    Spacer()

                    let pinned = AppSettings.shared.isPinned(path: project.path)
                    if isHovered || pinned {
                        Button {
                            AppSettings.shared.togglePin(path: project.path)
                        } label: {
                            Image(systemName: pinned ? "pin.fill" : "pin")
                                .font(.system(size: 11))
                                .foregroundColor(pinned ? .white.opacity(0.7) : .white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }

                    Text(Project.relativeDate(from: project.lastCommitDate))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x666666))
                }

                FreshnessBarView(freshness: project.freshness, level: project.freshnessLevel)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(RowButtonStyle(isHovered: isHovered))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Open in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(project.path, forType: .string)
            }
            if Self.vsCodePath != nil {
                Button("Open in VS Code") {
                    if let codePath = Self.vsCodePath {
                        _ = try? ShellCommand.run(codePath, arguments: [project.path])
                    }
                }
            }
            Divider()
            Button("Hide Project") {
                AppSettings.shared.hide(path: project.path)
            }
        }
    }
}

private struct RowButtonStyle: ButtonStyle {
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.white.opacity(0.10) : isHovered ? Color.white.opacity(0.06) : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
