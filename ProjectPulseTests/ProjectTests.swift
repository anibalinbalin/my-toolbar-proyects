import XCTest
@testable import ProjectPulse

final class ProjectTests: XCTestCase {
    func testFreshnessFullWhenCommittedNow() {
        let project = Project(
            name: "test", path: "/tmp/test",
            lastCommitDate: Date(), branch: "main", lastCommitMessage: "init"
        )
        XCTAssertGreaterThan(project.freshness, 0.99)
        XCTAssertEqual(project.freshnessLevel, .fresh)
    }

    func testFreshnessZeroAfterSevenDays() {
        let project = Project(
            name: "test", path: "/tmp/test",
            lastCommitDate: Date().addingTimeInterval(-7 * 24 * 3600),
            branch: "main", lastCommitMessage: "init"
        )
        XCTAssertEqual(project.freshness, 0.0)
        XCTAssertEqual(project.freshnessLevel, .sleeping)
    }

    func testFreshnessYellowAtThreeDays() {
        let project = Project(
            name: "test", path: "/tmp/test",
            lastCommitDate: Date().addingTimeInterval(-3 * 24 * 3600),
            branch: "main", lastCommitMessage: "init"
        )
        XCTAssertEqual(project.freshnessLevel, .warm)
    }

    func testFreshnessOrangeAtFiveDays() {
        let project = Project(
            name: "test", path: "/tmp/test",
            lastCommitDate: Date().addingTimeInterval(-5 * 24 * 3600),
            branch: "main", lastCommitMessage: "init"
        )
        XCTAssertEqual(project.freshnessLevel, .cooling)
    }

    func testSleepingProjectHasNilDate() {
        let project = Project(
            name: "empty", path: "/tmp/empty",
            lastCommitDate: nil, branch: nil, lastCommitMessage: nil
        )
        XCTAssertEqual(project.freshness, 0.0)
        XCTAssertEqual(project.freshnessLevel, .sleeping)
    }

    func testProjectsSortByFreshnessThenName() {
        let a = Project(name: "zzz", path: "/a", lastCommitDate: Date(), branch: "main", lastCommitMessage: "x")
        let b = Project(name: "aaa", path: "/b", lastCommitDate: Date(), branch: "main", lastCommitMessage: "x")
        let c = Project(name: "mmm", path: "/c", lastCommitDate: Date().addingTimeInterval(-5 * 24 * 3600), branch: "main", lastCommitMessage: "x")
        let sorted = [c, a, b].sorted()
        XCTAssertEqual(sorted.map(\.name), ["aaa", "zzz", "mmm"])
    }

    func testRelativeDateFormatting() {
        XCTAssertEqual(Project.relativeDate(from: Date()), "just now")
        XCTAssertEqual(Project.relativeDate(from: Date().addingTimeInterval(-3600)), "1h ago")
        XCTAssertEqual(Project.relativeDate(from: Date().addingTimeInterval(-5 * 3600)), "5h ago")
        XCTAssertEqual(Project.relativeDate(from: Date().addingTimeInterval(-2 * 24 * 3600)), "2d ago")
        XCTAssertEqual(Project.relativeDate(from: Date().addingTimeInterval(-10 * 24 * 3600)), "10d ago")
    }
}
