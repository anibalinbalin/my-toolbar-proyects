import Foundation

enum ShellCommand {
    enum Error: Swift.Error {
        case executionFailed(status: Int32, stderr: String)
        case commandNotFound
    }

    static func run(
        _ command: String,
        arguments: [String] = [],
        currentDirectory: String? = nil
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        if let dir = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw Error.commandNotFound
        }

        process.waitUntilExit()

        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw Error.executionFailed(status: process.terminationStatus, stderr: stderrString)
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
