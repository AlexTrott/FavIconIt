import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onComplete: (FaviconResult) -> Void

    @State private var isTargeted = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            // Draggable title area
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
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Drop zone
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(isTargeted ? 0.2 : 0.08))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isTargeted ? 1.15 : 1.0)

                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                        .symbolEffect(.bounce, value: isTargeted)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isTargeted)

                VStack(spacing: 8) {
                    Text(isTargeted ? "Drop to generate favicons" : "Drop your image here")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("PNG, JPEG, TIFF, HEIC, or SVG")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Rectangle().fill(.quaternary).frame(height: 1)
                    Text("or").font(.caption).foregroundStyle(.tertiary)
                    Rectangle().fill(.quaternary).frame(height: 1)
                }
                .padding(.horizontal, 60)

                Button {
                    showFilePicker = true
                } label: {
                    Label("Choose a file", systemImage: "folder")
                        .frame(minWidth: 160)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.white.opacity(0.08),
                        style: StrokeStyle(lineWidth: isTargeted ? 2.5 : 1, dash: [10, 6])
                    )
                    .padding(20)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            }
            .contentShape(Rectangle())
            .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { processFile(at: url) }
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
            if let url { processFile(at: url) }
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
