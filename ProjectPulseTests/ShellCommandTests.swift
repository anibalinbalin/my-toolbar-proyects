import XCTest
@testable import ProjectPulse

final class ShellCommandTests: XCTestCase {
    func testShellCommandRunsEcho() throws {
        let result = try ShellCommand.run("/bin/echo", arguments: ["hello"])
        XCTAssertEqual(result, "hello")
    }

    func testShellCommandFailsOnBadCommand() {
        XCTAssertThrowsError(try ShellCommand.run("/nonexistent/binary")) { error in
            XCTAssertTrue(error is ShellCommand.Error)
        }
    }

    func testShellCommandRunsInDirectory() throws {
        let result = try ShellCommand.run("/bin/pwd", currentDirectory: "/tmp")
        XCTAssertEqual(result, "/private/tmp")
    }
}
