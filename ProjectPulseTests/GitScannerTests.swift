import XCTest
@testable import ProjectPulse

final class GitScannerTests: XCTestCase {
    func testFindsGitReposInDirectory() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let repo1 = tmp.appendingPathComponent("project-a/.git")
        let repo2 = tmp.appendingPathComponent("project-b/.git")
        try FileManager.default.createDirectory(at: repo1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repo2, withIntermediateDirectories: true)

        let notRepo = tmp.appendingPathComponent("just-a-folder")
        try FileManager.default.createDirectory(at: notRepo, withIntermediateDirectories: true)

        let repos = GitScanner.scan(directory: tmp.path)
        XCTAssertEqual(repos.count, 2)
        XCTAssertTrue(repos.contains(where: { $0.hasSuffix("project-a") }))
        XCTAssertTrue(repos.contains(where: { $0.hasSuffix("project-b") }))
    }

    func testRespectsMaxDepthOfTwo() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let shallow = tmp.appendingPathComponent("shallow/.git")
        try FileManager.default.createDirectory(at: shallow, withIntermediateDirectories: true)

        let deep = tmp.appendingPathComponent("a/b/deep/.git")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)

        let repos = GitScanner.scan(directory: tmp.path)
        XCTAssertEqual(repos.count, 1)
        XCTAssertTrue(repos[0].hasSuffix("shallow"))
    }

    func testSkipsNestedGitInsideRepo() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let parent = tmp.appendingPathComponent("monorepo/.git")
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

        let nested = tmp.appendingPathComponent("monorepo/packages/sub/.git")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let repos = GitScanner.scan(directory: tmp.path)
        XCTAssertEqual(repos.count, 1)
        XCTAssertTrue(repos[0].hasSuffix("monorepo"))
    }
}
