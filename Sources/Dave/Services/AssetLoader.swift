import AppKit
import Foundation

public final class AssetLoader {
    public static let shared = AssetLoader()
    private var cache: [String: [NSImage]] = [:]

    private init() {}

    public func frames(for state: PetState) -> [NSImage] {
        if let cached = cache[state.rawValue], !cached.isEmpty {
            return cached
        }

        var loaded: [NSImage] = []
        for i in 0..<state.frameCount {
            let filename = "frame_\(i)"
            if let img = loadImage(state: state.folderName, name: filename) {
                loaded.append(img)
            }
        }

        if loaded.isEmpty {
            // Fallback placeholder
            loaded = [createPlaceholderImage(state: state)]
        }

        cache[state.rawValue] = loaded
        return loaded
    }

    public func iconImage(named name: String) -> NSImage? {
        if let cached = cache["icons_\(name)"]?.first {
            return cached
        }
        if let img = loadImage(state: "icons", name: name) {
            cache["icons_\(name)"] = [img]
            return img
        }
        return nil
    }

    public func busyIconFrames() -> [NSImage] {
        if let cached = cache["icons_busy"], !cached.isEmpty {
            return cached
        }
        var frames: [NSImage] = []
        for i in 0..<4 {
            if let img = loadImage(state: "icons", name: "busy_\(i)") {
                frames.append(img)
            }
        }
        if !frames.isEmpty {
            cache["icons_busy"] = frames
        }
        return frames
    }

    private func loadImage(state: String, name: String) -> NSImage? {
        let relativeSubpath = "Sprites/\(state)/\(name).png"

        // 1. Try Bundle.main resources (when packaged in .app)
        if let resURL = Bundle.main.resourceURL {
            let possibleBundleURLs = [
                resURL.appendingPathComponent("Assets/\(relativeSubpath)"),
                resURL.appendingPathComponent(relativeSubpath)
            ]
            for url in possibleBundleURLs {
                if FileManager.default.fileExists(atPath: url.path),
                   let img = NSImage(contentsOf: url) {
                    return img
                }
            }
        }

        // 2. Try relative to executable path
        if let execPath = Bundle.main.executablePath {
            let execDir = URL(fileURLWithPath: execPath).deletingLastPathComponent()
            let possibleExecURLs = [
                execDir.appendingPathComponent("Assets/\(relativeSubpath)"),
                execDir.appendingPathComponent("../Resources/Assets/\(relativeSubpath)"),
                execDir.appendingPathComponent("../Resources/\(relativeSubpath)")
            ]
            for url in possibleExecURLs {
                if FileManager.default.fileExists(atPath: url.path),
                   let img = NSImage(contentsOf: url) {
                    return img
                }
            }
        }

        // 3. Try relative to current working directory or common development project roots
        let cwd = FileManager.default.currentDirectoryPath
        let candidates = [
            "\(cwd)/Assets/\(relativeSubpath)",
            "\(cwd)/../Assets/\(relativeSubpath)",
            "Assets/\(relativeSubpath)",
            "./Assets/\(relativeSubpath)"
        ]

        for path in candidates {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }

        return nil
    }

    private func createPlaceholderImage(state: PetState) -> NSImage {
        let size = NSSize(width: 120, height: 120)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.systemBlue.withAlphaComponent(0.8).setFill()
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)
        path.fill()

        let text = "\(state.displayName)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 14)
        ]
        let textSize = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2), withAttributes: attrs)
        img.unlockFocus()
        return img
    }
}
