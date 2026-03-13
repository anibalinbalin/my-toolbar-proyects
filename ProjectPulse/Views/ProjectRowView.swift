import SwiftUI

struct ProjectRowView: View {
    let project: Project
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(project.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(project.freshnessLevel.nameOpacity))
                Spacer()
                Text(Project.relativeDate(from: project.lastCommitDate))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x666666))
            }

            FreshnessBarView(freshness: project.freshness, level: project.freshnessLevel)

            if isHovered, let branch = project.branch {
                HStack(spacing: 4) {
                    Text(branch)
                    if let msg = project.lastCommitMessage {
                        Text("·")
                        Text(msg)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x666666))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.024) : .clear)
        )
        .onHover { hovering in
            withAnimation(.spring(duration: 0.25, bounce: 0.15)) {
                isHovered = hovering
            }
        }
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
        }
    }
}
