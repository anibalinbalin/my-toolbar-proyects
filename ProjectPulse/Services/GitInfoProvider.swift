import Foundation

enum GitInfoProvider {
    private static let gitPath = "/usr/bin/git"

    static func info(for repoPath: String) throws -> Project {
        let name = URL(fileURLWithPath: repoPath).lastPathComponent

        var date: Date?
        var message: String?
        do {
            let dateStr = try ShellCommand.run(
                gitPath, arguments: ["log", "-1", "--format=%aI"],
                currentDirectory: repoPath
            )
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateStr)

            message = try ShellCommand.run(
                gitPath, arguments: ["log", "-1", "--format=%s"],
                currentDirectory: repoPath
            )
        } catch {
            date = nil
            message = nil
        }

        let branch: String?
        do {
            let branchName = try ShellCommand.run(
                gitPath, arguments: ["branch", "--show-current"],
                currentDirectory: repoPath
            )
            if branchName.isEmpty {
                let hash = try? ShellCommand.run(
                    gitPath, arguments: ["rev-parse", "--short", "HEAD"],
                    currentDirectory: repoPath
                )
                branch = hash
            } else {
                branch = branchName
            }
        } catch {
            branch = nil
        }

        return Project(
            name: name, path: repoPath,
            lastCommitDate: date, branch: branch,
            lastCommitMessage: message
        )
    }
}
