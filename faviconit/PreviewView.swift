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
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                faviconGrid
                snippetSection(title: "HTML Snippet", content: result.htmlSnippet, copied: $htmlCopied)
                snippetSection(title: "Web Manifest", content: result.manifestJSON, copied: $manifestCopied)
                saveButton
            }
            .padding(24)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(nsImage: result.sourceImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(result.sourceName)
                    .font(.headline)
                Text(result.isSVGSource ? "SVG source" : "Raster source")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Start Over", systemImage: "arrow.counterclockwise") {
                onStartOver()
            }
        }
    }

    // MARK: - Favicon Grid

    private var faviconGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Favicons")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 16) {
                ForEach(imageFiles, id: \.fileName) { file in
                    VStack(spacing: 6) {
                        if let image = NSImage(data: file.data) {
                            Image(nsImage: image)
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                        }

                        Text(file.fileName)
                            .font(.caption2)
                            .lineLimit(1)

                        if let size = file.previewSize {
                            Text("\(size)px")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Code Snippets

    private func snippetSection(title: String, content: String, copied: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
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
                        copied.wrappedValue ? "Copied" : "Copy",
                        systemImage: copied.wrappedValue ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            Text(content)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveFiles()
        } label: {
            Label(
                saved ? "Saved!" : "Save All Files",
                systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .alert("Save Error", isPresented: $showSaveError) {
            Button("OK") { }
        } message: {
            Text(saveError ?? "An unknown error occurred.")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                saved = false
            }
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
