import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onComplete: (FaviconResult) -> Void

    @State private var isTargeted = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                Text("Drop an image here")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("PNG, JPEG, TIFF, HEIC, or SVG")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Browse…") {
                    showFilePicker = true
                }
                .controlSize(.large)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .padding(8)
            }
        }
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    processFile(at: url)
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - File Handling

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        Task {
            let url = await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true) {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }

            if let url {
                processFile(at: url)
            }
        }
    }

    private func processFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let result = try FaviconGenerator.generate(from: url)
            onComplete(result)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
