import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onComplete: (FaviconResult) -> Void

    @State private var isTargeted = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with app branding
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("FavIconIt")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Drop zone area
            dropZoneCard
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(minWidth: 420, minHeight: 380)
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

    // MARK: - Drop Zone Card

    private var dropZoneCard: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with animated ring
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(isTargeted ? 0.15 : 0.07))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isTargeted ? 1.1 : 1.0)

                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                    .symbolEffect(.bounce, value: isTargeted)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isTargeted)

            // Text content
            VStack(spacing: 8) {
                Text(isTargeted ? "Drop to generate favicons" : "Drop your image here")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)

                Text("PNG, JPEG, TIFF, HEIC, or SVG")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Or divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(.separator)
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Rectangle()
                    .fill(.separator)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)

            // Browse button
            Button {
                showFilePicker = true
            } label: {
                Label("Choose a file", systemImage: "folder")
                    .frame(minWidth: 140)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: isTargeted ? 2.5 : 1.5,
                        dash: [8, 5]
                    )
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        }
        .contentShape(Rectangle())
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
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
