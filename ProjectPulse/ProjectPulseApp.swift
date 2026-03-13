import SwiftUI

@main
struct ProjectPulseApp: App {
    var body: some Scene {
        MenuBarExtra("Project Pulse", systemImage: "circle.fill") {
            Text("Project Pulse")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
