import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(value: "history")
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
                .help("Open Full History")
                .buttonStyle(PlainButtonStyle())

                SettingsLink {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(clipboardManager.history, id: \.self) { item in
                        MenuItemRow(item: item) {
                            copyToClipboard(item)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Text("Click an item to copy it.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)

            HStack {
                Button("Clear History") {
                    self.clipboardManager.clearHistory()
                }
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.bottom)
        }
        .onAppear(perform: clipboardManager.startMonitoring)
    }

    private func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.data {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let imageData):
            pasteboard.setData(imageData, forType: .tiff)
        }
    }
}

private struct MenuItemRow: View {
    let item: ClipboardItem
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                switch item.data {
                case .text(let text):
                    Text(text)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .image(let imageData):
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                        Text("Image")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(nsColor: .selectedMenuItemColor).opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let historyKey = "clipboardHistory"
    @AppStorage("historyLimit") private var historyLimit = 50
    @AppStorage("itemExpiration") private var itemExpiration = "never"

    init() {
        loadHistory()
    }

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.lastChangeCount != NSPasteboard.general.changeCount {
                self.lastChangeCount = NSPasteboard.general.changeCount
                
                if let newString = NSPasteboard.general.string(forType: .string) {
                    let newItem = ClipboardItem(data: .text(newString), date: Date())
                    DispatchQueue.main.async {
                        self.upsert(newItem)
                    }
                } else if let imageData = NSPasteboard.general.data(forType: .tiff) {
                    let newItem = ClipboardItem(data: .image(imageData), date: Date())
                    DispatchQueue.main.async {
                        self.upsert(newItem)
                    }
                }
            }
        }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func delete(_ item: ClipboardItem) {
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
            saveHistory()
        }
    }

    private func upsert(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.data == item.data }) {
            history.remove(at: index)
        }
        history.insert(item, at: 0)
        trimHistory()
        saveHistory()
    }

    private func trimHistory() {
        if history.count > historyLimit {
            history = Array(history.prefix(historyLimit))
        }
    }

    private func saveHistory() {
        if let encodedData = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encodedData, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let savedData = UserDefaults.standard.data(forKey: historyKey) {
            if let decodedHistory = try? JSONDecoder().decode([ClipboardItem].self, from: savedData) {
                history = decodedHistory
                applyExpirationPolicy()
                trimHistory()
            }
        }
    }

    private func applyExpirationPolicy() {
        let now = Date()
        var expirationDate: Date?

        switch itemExpiration {
        case "hour":
            expirationDate = Calendar.current.date(byAdding: .hour, value: -1, to: now)
        case "day":
            expirationDate = Calendar.current.date(byAdding: .day, value: -1, to: now)
        case "week":
            expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)
        case "month":
            expirationDate = Calendar.current.date(byAdding: .month, value: -1, to: now)
        default:
            break
        }

        if let expirationDate = expirationDate {
            history = history.filter { $0.date >= expirationDate }
        }
    }
}

