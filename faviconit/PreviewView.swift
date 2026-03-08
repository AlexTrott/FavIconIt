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

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
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
                }
                .controlSize(.regular)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 24)

            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    sourceCard
                    faviconGridCard
                    snippetCard(
                        title: "HTML Snippet",
                        subtitle: "Paste into your <head> tag",
                        content: result.htmlSnippet,
                        copied: $htmlCopied
                    )
                    snippetCard(
                        title: "Web Manifest",
                        subtitle: "site.webmanifest",
                        content: result.manifestJSON,
                        copied: $manifestCopied
                    )
                    saveSection
                }
                .padding(24)
            }
        }
        .frame(minWidth: 480, minHeight: 500)
        .alert("Save Error", isPresented: $showSaveError) {
            Button("OK") { }
        } message: {
            Text(saveError ?? "An unknown error occurred.")
        }
    }

    // MARK: - Source Card

    private var sourceCard: some View {
        HStack(spacing: 16) {
            // Source image with nice framing
            Image(nsImage: result.sourceImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.sourceName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Image(systemName: result.isSVGSource ? "doc.text" : "photo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(result.isSVGSource ? "SVG Vector" : "Raster Image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("\(result.files.count) files generated")
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    // MARK: - Favicon Grid

    private var faviconGridCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Generated Favicons", systemImage: "square.grid.2x2")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(imageFiles, id: \.fileName) { file in
                    faviconTile(file: file)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    private func faviconTile(file: GeneratedFavicon) -> some View {
        VStack(spacing: 8) {
            if let image = NSImage(data: file.data) {
                ZStack {
                    // Checkerboard pattern to show transparency
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.background)
                        .overlay {
                            checkerboardPattern
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                }
                .frame(width: 72, height: 72)
            }

            VStack(spacing: 2) {
                Text(file.fileName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let size = file.previewSize {
                    Text("\(size) x \(size)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private var checkerboardPattern: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 6
            let cols = Int(ceil(size.width / cellSize))
            let rows = Int(ceil(size.height / cellSize))
            for row in 0..<rows {
                for col in 0..<cols {
                    if (row + col) % 2 == 0 {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        context.fill(Path(rect), with: .color(.primary.opacity(0.05)))
                    }
                }
            }
        }
    }

    // MARK: - Code Snippets

    private func snippetCard(title: String, subtitle: String, content: String, copied: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Label(
                        copied.wrappedValue ? "Copied!" : "Copy",
                        systemImage: copied.wrappedValue ? "checkmark.circle.fill" : "doc.on.doc"
                    )
                    .font(.caption)
                    .foregroundStyle(copied.wrappedValue ? .green : Color.accentColor)
                }
                .buttonStyle(.borderless)
                .animation(.easeInOut(duration: 0.15), value: copied.wrappedValue)
            }

            Text(content)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    // MARK: - Save Section

    private var saveSection: some View {
        Button {
            saveFiles()
        } label: {
            Label(
                saved ? "Saved!" : "Save All Files",
                systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down"
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .animation(.easeInOut(duration: 0.15), value: saved)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                saved = false
            }
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
