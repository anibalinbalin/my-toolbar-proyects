import SwiftUI

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Scan Directory") {
                HStack {
                    TextField("Path", text: $settings.scanPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.scanPath = url.path
                        }
                    }
                }
            }

            Section("Refresh") {
                Picker("Interval", selection: $settings.refreshInterval) {
                    Text("30s").tag(30.0)
                    Text("60s").tag(60.0)
                    Text("120s").tag(120.0)
                    Text("300s").tag(300.0)
                }
                .pickerStyle(.segmented)
            }

            Section("Decay Window") {
                Picker("Days until empty", selection: $settings.decayDays) {
                    Text("3 days").tag(3.0)
                    Text("7 days").tag(7.0)
                    Text("14 days").tag(14.0)
                    Text("30 days").tag(30.0)
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }
}
