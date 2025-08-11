import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var fullTextToShow: String? = nil
    @AppStorage("timeFormatPattern") private var timeFormatPattern = "HH:mm"

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = timeFormatPattern
        return df
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Full clipboard history")
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.horizontal, 16)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(clipboardManager.history, id: \.self) { item in
                        HistoryRowView(item: item, formattedTime: dateFormatter.string(from: item.date)) { text in
                            fullTextToShow = text
                        }
                        .padding(.horizontal, 16)
                        Divider()
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
        .sheet(isPresented: Binding(
            get: { fullTextToShow != nil },
            set: { if !$0 { fullTextToShow = nil } }
        )) {
            if let text = fullTextToShow {
                FullTextView(text: text)
            }
        }
    }
}

struct HistoryRowView: View {
    let item: ClipboardItem
    let formattedTime: String
    var onOpenFullText: (String) -> Void
    @EnvironmentObject private var clipboardManager: ClipboardManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content preview
            switch item.data {
            case .text(let text):
                Text(text)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: 420, alignment: .leading)
            case .image(let data):
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 96)
                }
            }

            Spacer(minLength: 8)

            // Trailing controls
            VStack(alignment: .trailing, spacing: 6) {
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Button {
                        copyToClipboard(item)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        clipboardManager.delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if case .text(let text) = item.data {
                onOpenFullText(text)
            }
        }
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

private struct FullTextView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Text("copied text")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Button("Close") { dismiss() }
                }
            }
            .padding(.top, 8)

            ScrollView {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
            .frame(minHeight: 240)

            HStack {
                Spacer()
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(text, forType: .string)
                    dismiss()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .frame(minWidth: 460, minHeight: 340)
    }
}