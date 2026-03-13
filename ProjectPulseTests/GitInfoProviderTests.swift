import XCTest
@testable import ProjectPulse

final class GitInfoProviderTests: XCTestCase {
    func testExtractsInfoFromRealRepo() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let path = tmp.path
        try ShellCommand.run("/usr/bin/git", arguments: ["init"], currentDirectory: path)
        try ShellCommand.run("/usr/bin/git", arguments: ["-c", "user.name=Test", "-c", "user.email=test@test.com", "commit", "--allow-empty", "-m", "test commit"], currentDirectory: path)

        let project = try GitInfoProvider.info(for: path)
        XCTAssertEqual(project.name, tmp.lastPathComponent)
        XCTAssertTrue(project.branch == "main" || project.branch == "master")
        XCTAssertEqual(project.lastCommitMessage, "test commit")
        XCTAssertNotNil(project.lastCommitDate)
    }

    func testHandlesDetachedHead() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let path = tmp.path
        try ShellCommand.run("/usr/bin/git", arguments: ["init"], currentDirectory: path)
        try ShellCommand.run("/usr/bin/git", arguments: ["-c", "user.name=Test", "-c", "user.email=test@test.com", "commit", "--allow-empty", "-m", "first"], currentDirectory: path)
        try ShellCommand.run("/usr/bin/git", arguments: ["-c", "user.name=Test", "-c", "user.email=test@test.com", "commit", "--allow-empty", "-m", "second"], currentDirectory: path)
        let firstHash = try ShellCommand.run("/usr/bin/git", arguments: ["rev-parse", "HEAD~1"], currentDirectory: path)
        try ShellCommand.run("/usr/bin/git", arguments: ["checkout", firstHash], currentDirectory: path)

        let project = try GitInfoProvider.info(for: path)
        XCTAssertNotNil(project.branch)
        XCTAssertLessThanOrEqual(project.branch!.count, 10)
        XCTAssertTrue(project.branch != "main" && project.branch != "master")
    }

    func testHandlesEmptyRepoGracefully() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        try ShellCommand.run("/usr/bin/git", arguments: ["init"], currentDirectory: tmp.path)

        let project = try GitInfoProvider.info(for: tmp.path)
        XCTAssertEqual(project.name, tmp.lastPathComponent)
        XCTAssertNil(project.lastCommitDate)
        XCTAssertEqual(project.freshnessLevel, .sleeping)
    }
}
