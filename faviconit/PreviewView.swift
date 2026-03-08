import SwiftUI
import AppKit

struct PreviewView: View {
    let result: FaviconResult
    let onStartOver: () -> Void

    @State private var htmlCopied = false
    @State private var manifestCopied = false
    @State private var saved = false
    @State private var saveError: String?
    @State private var showSaveError = false
    @State private var showCode = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("FavIconIt")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onStartOver()
                } label: {
                    Label("New Image", systemImage: "arrow.counterclockwise")
                        .font(.callout)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // Source image hero
                    sourceHero

                    // Generated icons visual grid
                    faviconGrid

                    // Save button — primary action
                    saveButton

                    // Developer section (collapsible)
                    codeSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 480, minHeight: 500)
        .alert("Save Error", isPresented: $showSaveError) {
            Button("OK") { }
        } message: {
            Text(saveError ?? "An unknown error occurred.")
        }
    }

    // MARK: - Source Hero

    private var sourceHero: some View {
        HStack(spacing: 16) {
            Image(nsImage: result.sourceImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(result.sourceName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(result.files.count) files ready to save")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Favicon Grid

    private var faviconGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your favicons")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                ForEach(imageFiles, id: \.fileName) { file in
                    faviconTile(file: file)
                }
            }
        }
    }

    private func faviconTile(file: GeneratedFavicon) -> some View {
        VStack(spacing: 8) {
            if let image = NSImage(data: file.data) {
                ZStack {
                    checkerboard
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                }
            }

            VStack(spacing: 2) {
                Text(labelForFile(file))
                    .font(.caption)
                    .fontWeight(.medium)

                if let size = file.previewSize {
                    Text("\(size)px")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func labelForFile(_ file: GeneratedFavicon) -> String {
        switch file.fileName {
        case "favicon.ico": return "Browser"
        case "apple-touch-icon.png": return "Apple"
        case "icon-192.png": return "Android"
        case "icon-512.png": return "PWA"
        default: return file.fileName
        }
    }

    private var checkerboard: some View {
        Canvas { context, size in
            let cell: CGFloat = 6
            let cols = Int(ceil(size.width / cell))
            let rows = Int(ceil(size.height / cell))
            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 0 {
                    let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(.primary.opacity(0.04)))
                }
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveFiles()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.body.weight(.medium))
                Text(saved ? "Saved!" : "Save All Files")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(saved ? .green : Color.accentColor)
        .controlSize(.large)
        .animation(.easeInOut(duration: 0.2), value: saved)
    }

    // MARK: - Code Section

    private var codeSection: some View {
        DisclosureGroup(isExpanded: $showCode) {
            VStack(spacing: 14) {
                codeBlock(
                    title: "HTML",
                    subtitle: "Paste into your <head>",
                    content: result.htmlSnippet,
                    copied: $htmlCopied
                )
                codeBlock(
                    title: "Manifest",
                    subtitle: "site.webmanifest",
                    content: result.manifestJSON,
                    copied: $manifestCopied
                )
            }
            .padding(.top, 12)
        } label: {
            Label("Developer Code", systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .tint(.secondary)
    }

    private func codeBlock(title: String, subtitle: String, content: String, copied: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.caption).fontWeight(.semibold)
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    copied.wrappedValue = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied.wrappedValue = false
                    }
                } label: {
                    Image(systemName: copied.wrappedValue ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied.wrappedValue ? .green : .secondary)
                }
                .buttonStyle(.borderless)
            }

            Text(content)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Helpers

    private var imageFiles: [GeneratedFavicon] {
        result.files.filter { $0.previewSize != nil }
    }

    private func saveFiles() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Save Here"
        panel.message = "Choose a folder to save your favicon files"

        guard panel.runModal() == .OK, let folderURL = panel.url else { return }

        do {
            for file in result.files {
                try file.data.write(to: folderURL.appendingPathComponent(file.fileName))
            }
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { saved = false }
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
