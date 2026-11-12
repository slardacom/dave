import AppKit
import Foundation

public final class FileTrashMonitor {
    public static let shared = FileTrashMonitor()

    private var desktopSource: DispatchSourceFileSystemObject?
    private var downloadsSource: DispatchSourceFileSystemObject?
    private var desktopFiles: Set<String> = []
    private var downloadsFiles: Set<String> = []
    private var keyEventMonitor: Any?

    private init() {}

    public func startMonitoring() {
        startDesktopMonitor()
        startDownloadsMonitor()
        startGlobalKeyMonitor()
    }

    private func startDesktopMonitor() {
        let path = NSHomeDirectory() + "/Desktop"
        desktopFiles = currentContents(of: path)

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let updated = self.currentContents(of: path)
            let removed = self.desktopFiles.subtracting(updated)
            self.desktopFiles = updated

            // Filter out system files like .DS_Store
            let userFiles = removed.filter { !$0.hasPrefix(".") && !$0.hasPrefix("~$") }
            if let deletedFile = userFiles.first {
                // Detected desktop file deletion!
                let mouse = NSEvent.mouseLocation
                let icon = PetManager.resolveIcon(name: deletedFile)
                DispatchQueue.main.async {
                    TrashDutyService.shared.performTrashMission(from: mouse, filename: deletedFile, fileIcon: icon)
                }
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.desktopSource = source
    }

    private func startDownloadsMonitor() {
        let path = NSHomeDirectory() + "/Downloads"
        downloadsFiles = currentContents(of: path)

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let updated = self.currentContents(of: path)
            let removed = self.downloadsFiles.subtracting(updated)
            self.downloadsFiles = updated

            let userFiles = removed.filter { !$0.hasPrefix(".") && !$0.hasPrefix("~$") }
            if let deletedFile = userFiles.first {
                let mouse = NSEvent.mouseLocation
                let icon = PetManager.resolveIcon(name: deletedFile)
                DispatchQueue.main.async {
                    TrashDutyService.shared.performTrashMission(from: mouse, filename: deletedFile, fileIcon: icon)
                }
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.downloadsSource = source
    }

    private func startGlobalKeyMonitor() {
        // Listen for Cmd + Delete (Backspace is keyCode 51)
        keyEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 51, event.modifierFlags.contains(.command) else { return }

            // If frontmost app is Finder, user just triggered "Move to Trash"!
            if let frontApp = NSWorkspace.shared.frontmostApplication, frontApp.bundleIdentifier == "com.apple.finder" {
                let mouse = NSEvent.mouseLocation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    TrashDutyService.shared.performTrashMission(from: mouse, filename: nil)
                }
            }
        }
    }

    private func currentContents(of dirPath: String) -> Set<String> {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: dirPath)
            return Set(items)
        } catch {
            return []
        }
    }

    deinit {
        desktopSource?.cancel()
        downloadsSource?.cancel()
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
