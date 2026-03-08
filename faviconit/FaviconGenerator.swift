import AppKit

struct GeneratedFavicon {
    let fileName: String
    let data: Data
    let previewSize: Int?
}

struct FaviconResult {
    let sourceImage: NSImage
    let sourceName: String
    let files: [GeneratedFavicon]
    let htmlSnippet: String
    let manifestJSON: String
    let isSVGSource: Bool
}

enum FaviconGeneratorError: LocalizedError {
    case failedToLoadImage
    case failedToResize(Int)

    var errorDescription: String? {
        switch self {
        case .failedToLoadImage:
            "Could not load the image file."
        case .failedToResize(let size):
            "Failed to resize image to \(size)×\(size)."
        }
    }
}

struct FaviconGenerator {

    static func generate(from sourceURL: URL) throws -> FaviconResult {
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw FaviconGeneratorError.failedToLoadImage
        }

        let isSVG = sourceURL.pathExtension.lowercased() == "svg"
        let sourceName = sourceURL.lastPathComponent
        var files: [GeneratedFavicon] = []

        // favicon.ico — 16, 32, 48 embedded as PNG-in-ICO
        let icoEntries = try [16, 32, 48].map { size in
            ICOEncoder.IconEntry(
                width: size,
                height: size,
                pngData: try resizedPNGData(from: image, to: size)
            )
        }
        files.append(GeneratedFavicon(
            fileName: "favicon.ico",
            data: ICOEncoder.encode(entries: icoEntries),
            previewSize: 48
        ))

        // PNG outputs at standard sizes
        for (name, size) in [("apple-touch-icon.png", 180), ("icon-192.png", 192), ("icon-512.png", 512)] {
            files.append(GeneratedFavicon(
                fileName: name,
                data: try resizedPNGData(from: image, to: size),
                previewSize: size
            ))
        }

        // SVG — copy original file bytes
        if isSVG {
            files.append(GeneratedFavicon(
                fileName: "favicon.svg",
                data: try Data(contentsOf: sourceURL),
                previewSize: nil
            ))
        }

        // HTML snippet
        let htmlSnippet = buildHTMLSnippet(isSVG: isSVG)
        files.append(GeneratedFavicon(
            fileName: "favicon-snippet.html",
            data: Data(htmlSnippet.utf8),
            previewSize: nil
        ))

        // Web manifest
        let manifestJSON = buildManifest()
        files.append(GeneratedFavicon(
            fileName: "site.webmanifest",
            data: Data(manifestJSON.utf8),
            previewSize: nil
        ))

        return FaviconResult(
            sourceImage: image,
            sourceName: sourceName,
            files: files,
            htmlSnippet: htmlSnippet,
            manifestJSON: manifestJSON,
            isSVGSource: isSVG
        )
    }

    // MARK: - Image Resizing

    private static func resizedPNGData(from image: NSImage, to size: Int) throws -> Data {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw FaviconGeneratorError.failedToResize(size)
        }

        rep.size = NSSize(width: size, height: size)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw FaviconGeneratorError.failedToResize(size)
        }

        return pngData
    }

    // MARK: - Snippet Generation

    private static func buildHTMLSnippet(isSVG: Bool) -> String {
        var lines = [#"<link rel="icon" href="/favicon.ico" sizes="48x48">"#]
        if isSVG {
            lines.append(#"<link rel="icon" href="/favicon.svg" type="image/svg+xml">"#)
        }
        lines.append(#"<link rel="apple-touch-icon" href="/apple-touch-icon.png">"#)
        lines.append(#"<link rel="manifest" href="/site.webmanifest">"#)
        return lines.joined(separator: "\n")
    }

    private static func buildManifest() -> String {
        """
        {
          "icons": [
            { "src": "/icon-192.png", "type": "image/png", "sizes": "192x192" },
            { "src": "/icon-512.png", "type": "image/png", "sizes": "512x512" }
          ]
        }
        """
    }
}
