import AppKit
import CryptoKit
import os.log

private let logger = Logger(subsystem: "com.clipflow", category: "ClipItem")

// MARK: - ClipContent

enum ClipContent {
    case text(String)
    case image(Data, thumbnail: NSImage, size: CGSize)
    case richText(NSAttributedString) // future
    case file(URL, name: String)      // future
}

extension ClipContent: Equatable {
    static func == (lhs: ClipContent, rhs: ClipContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)):
            return a == b
        case (.image(let a, _, _), .image(let b, _, _)):
            return a == b
        case (.richText, .richText):
            assertionFailure("richText not implemented")
            return false
        case (.file(let a, _), .file(let b, _)):
            return a == b
        default:
            return false
        }
    }
}

extension ClipContent: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .text(let str):
            hasher.combine(0)
            hasher.combine(str)
        case .image(let data, _, _):
            hasher.combine(1)
            hasher.combine(data.count)
            // Hash first and last 64 bytes for fast fingerprint
            if data.count > 128 {
                hasher.combine(data.prefix(64))
                hasher.combine(data.suffix(64))
            } else {
                hasher.combine(data)
            }
        case .richText:
            hasher.combine(2)
        case .file(let url, _):
            hasher.combine(3)
            hasher.combine(url)
        }
    }
}

// MARK: - ClipContent Helpers

extension ClipContent {
    var displayText: String {
        switch self {
        case .text(let str):
            return str
        case .image(_, _, let size):
            return "Image (\(Int(size.width))x\(Int(size.height)))"
        case .richText:
            return "Rich Text (coming soon)"
        case .file(_, let name):
            return "File: \(name) (coming soon)"
        }
    }

    var isImage: Bool {
        if case .image = self { return true }
        return false
    }
}

// MARK: - Image Processing

enum ImageProcessor {
    static let maxEdge: CGFloat = 2048
    static let thumbnailSize: CGFloat = 96 // @2x for 48pt

    static func processImage(from data: Data) -> (pngData: Data, thumbnail: NSImage, size: CGSize)? {
        guard let image = NSImage(data: data) else {
            logger.warning("Failed to create NSImage from pasteboard data")
            return nil
        }

        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else {
            logger.warning("Image has zero dimensions")
            return nil
        }

        // Downscale if exceeds max edge
        let scaledImage: NSImage
        if originalSize.width > maxEdge || originalSize.height > maxEdge {
            let scale = min(maxEdge / originalSize.width, maxEdge / originalSize.height)
            let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
            scaledImage = resizeImage(image, to: newSize)
        } else {
            scaledImage = image
        }

        // Convert to PNG
        guard let tiffData = scaledImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            logger.warning("Failed to convert image to PNG")
            return nil
        }

        // Generate thumbnail (aspect-fill, center crop)
        let thumbnail = generateThumbnail(from: scaledImage)

        return (pngData, thumbnail, originalSize)
    }

    private static func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    static func generateThumbnail(from image: NSImage) -> NSImage {
        let thumbSize = NSSize(width: thumbnailSize, height: thumbnailSize)
        let imageSize = image.size

        // Calculate aspect-fill crop rect
        let imageAspect = imageSize.width / imageSize.height
        let cropRect: NSRect
        if imageAspect > 1 {
            // Wider than tall: crop sides
            let cropWidth = imageSize.height
            let x = (imageSize.width - cropWidth) / 2
            cropRect = NSRect(x: x, y: 0, width: cropWidth, height: imageSize.height)
        } else {
            // Taller than wide: crop top/bottom
            let cropHeight = imageSize.width
            let y = (imageSize.height - cropHeight) / 2
            cropRect = NSRect(x: 0, y: y, width: imageSize.width, height: cropHeight)
        }

        let thumb = NSImage(size: thumbSize)
        thumb.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbSize),
                   from: cropRect,
                   operation: .copy, fraction: 1.0)
        thumb.unlockFocus()
        return thumb
    }
}

// MARK: - ClipItem

struct ClipItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipContent
    let timestamp: Date
    let sourceApp: String?

    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.content == rhs.content
    }
}
