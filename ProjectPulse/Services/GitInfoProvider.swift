import Foundation

enum GitInfoProvider {
    private static let gitPath = "/usr/bin/git"
    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func info(for repoPath: String) throws -> Project {
        let name = URL(fileURLWithPath: repoPath).lastPathComponent

        var date: Date?
        var message: String?
        do {
            let dateStr = try ShellCommand.run(
                gitPath, arguments: ["log", "-1", "--format=%aI"],
                currentDirectory: repoPath
            )
            date = dateFormatter.date(from: dateStr)

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
