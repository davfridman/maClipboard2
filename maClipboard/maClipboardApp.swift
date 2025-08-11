import SwiftUI
import AppKit

@main
struct MenuClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("History", for: String.self) { _ in
            HistoryView()
                .environmentObject(appDelegate.clipboardManager)
        }
        .defaultSize(width: 520, height: 420)

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var clipboardManager = ClipboardManager()

    private var escLocalMonitor: Any?
    private var escGlobalMonitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
            button.action = #selector(togglePopover(_:))
        }

        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(clipboardManager))
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.behavior = .transient // close when clicking outside
        self.popover = popover

        // Close popover on ESC
        escLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53, self.popover?.isShown == true { // 53 = Escape
                self.popover.performClose(event)
                return nil
            }
            return event
        }
        escGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            if event.keyCode == 53, self.popover?.isShown == true {
                DispatchQueue.main.async { self.popover.performClose(nil) }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = escLocalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = escGlobalMonitor { NSEvent.removeMonitor(monitor) }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
