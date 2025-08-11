import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("historyLimit") private var historyLimit = 50
    @AppStorage("itemExpiration") private var itemExpiration = "never"
    @AppStorage("timeFormatPattern") private var timeFormatPattern = "HH:mm" // e.g., "HH:mm", "HH:mm:ss", "dd MMM yyyy HH:mm"

    let historyLimits = [10, 20, 50, 100, 200]
    let expirationOptions = [
        "never": "Never",
        "hour": "1 Hour",
        "day": "1 Day",
        "week": "1 Week",
        "month": "1 Month"
    ]

    let timeFormatOptions: [(label: String, pattern: String)] = [
        ("HH:mm", "HH:mm"),
        ("HH:mm:ss", "HH:mm:ss"),
        ("yyyy-MM-dd", "yyyy-MM-dd"),
        ("yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm"),
        ("MMM d, yyyy", "MMM d, yyyy"),
        ("MMM d, yyyy HH:mm", "MMM d, yyyy HH:mm")
    ]

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { oldValue, newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }

            Picker("History Limit", selection: $historyLimit) {
                ForEach(historyLimits, id: \.self) { limit in
                    Text("\(limit) items")
                }
            }

            Picker("Delete Items After", selection: $itemExpiration) {
                ForEach(expirationOptions.keys.sorted(), id: \.self) { key in
                    Text(expirationOptions[key] ?? "")
                }
            }

            Picker("Time Display", selection: $timeFormatPattern) {
                ForEach(timeFormatOptions, id: \.pattern) { opt in
                    Text(opt.label).tag(opt.pattern)
                }
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear(perform: checkLaunchAtLogin)
    }

    private func checkLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions if needed
        }
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                launchAtLogin.toggle() // Revert UI on failure
            }
        } else {
            // Fallback for older macOS versions if needed
        }
    }
}
