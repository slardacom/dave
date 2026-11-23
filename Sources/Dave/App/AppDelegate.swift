import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: PetWindow?
    private var statusItem: NSStatusItem?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app: no Dock icon, purely floating companion & menu bar
        NSApplication.shared.setActivationPolicy(.accessory)

        setupWindow()
        setupStatusItem()

        // Start Antigravity Bridge
        AntigravityBridge.shared.startListening()

        // Start Hardware & Battery Monitoring (CPU load & MagSafe power)
        HardwareMonitor.shared.startMonitoring()

        // Welcome greeting from Dave!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            PetManager.shared.speak("你好！我是 Dave，你的桌面专属工程师搭档 🚀", duration: 5.0)
            SoundManager.shared.playHero()
        }
    }

    private func setupWindow() {
        let width: CGFloat = 260
        let height: CGFloat = 270

        let screen = NSScreen.main ?? NSScreen.screens.first!
        let visibleFrame = screen.visibleFrame

        // Initial position: Bottom right corner above dock
        let initialX = visibleFrame.maxX - width - 30
        let initialY = visibleFrame.minY + 20
        let contentRect = NSRect(x: initialX, y: initialY, width: width, height: height)

        let petWindow = PetWindow(contentRect: contentRect)
        let hostingView = PetHostingView()
        petWindow.contentView = hostingView

        petWindow.orderFrontRegardless()
        self.window = petWindow
        PetManager.shared.window = petWindow
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        button.title = ""
        button.image = createDaveStatusIcon()
        button.imagePosition = .imageOnly
        button.toolTip = "Dave 桌面小宠物"

        let menu = NSMenu()
        menu.delegate = self

        // 1. Embedded Token Statistics Card in Status Bar Popup
        let statsItem = NSMenuItem()
        let hostingView = NSHostingView(rootView: TokenStatsCardView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 275, height: 215)
        statsItem.view = hostingView
        menu.addItem(statsItem)

        menu.addItem(NSMenuItem.separator())

        let snapItem = NSMenuItem(title: "移回屏幕底部", action: #selector(snapToBottom), keyEquivalent: "b")
        snapItem.target = self
        snapItem.image = NSImage(systemSymbolName: "arrow.down.to.line", accessibilityDescription: nil)
        menu.addItem(snapItem)

        let toggleVisibleItem = NSMenuItem(title: "显示 / 隐藏 Dave", action: #selector(toggleVisibility), keyEquivalent: "h")
        toggleVisibleItem.target = self
        toggleVisibleItem.image = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)
        menu.addItem(toggleVisibleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Dave", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func createDaveStatusIcon() -> NSImage {
        // 1. Try to load bundled / local image asset first
        let possibleFilenames = ["status_dave", "status_icon"]
        for name in possibleFilenames {
            let relativeSubpaths = ["Assets/\(name).png", "\(name).png"]
            if let resURL = Bundle.main.resourceURL {
                for sub in relativeSubpaths {
                    let url = resURL.appendingPathComponent(sub)
                    if FileManager.default.fileExists(atPath: url.path),
                       let img = NSImage(contentsOf: url) {
                        img.size = NSSize(width: 18, height: 18)
                        img.isTemplate = true
                        return img
                    }
                }
            }
            let cwd = FileManager.default.currentDirectoryPath
            for sub in relativeSubpaths {
                let path = "\(cwd)/\(sub)"
                if FileManager.default.fileExists(atPath: path),
                   let img = NSImage(contentsOfFile: path) {
                    img.size = NSSize(width: 18, height: 18)
                    img.isTemplate = true
                    return img
                }
            }
        }

        // 2. High-precision procedural pixel fallback (18x18 crisp pixel-art Dave)
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.interpolationQuality = .none
            context.setFillColor(NSColor.white.cgColor)

            let pattern: [String] = [
                "..................", // 0
                "...#...#..........", // 1 hair tufts
                "..############....", // 2 hair top
                "..#############...", // 3 hair
                "..#############...", // 4 hair
                ".###############..", // 5 hair
                ".#####.#######.##.", // 6 bangs
                ".#####.#######.##.", // 7 bangs
                ".##...###...###.##", // 8 forehead & bangs
                ".##.............##", // 9 glasses upper cutout
                ".##..##.#...##.#.#", // 10 glasses lenses & eyes
                ".##.............##", // 11 glasses lower cutout
                "....###########...", // 12 cheeks
                "....#####..####...", // 13 smile
                "....###########...", // 14 cheeks
                ".....#########....", // 15 chin
                "..................", // 16
                ".................."  // 17
            ]

            let pixelSize: CGFloat = 1.0
            for (rowIdx, row) in pattern.enumerated() {
                let y = CGFloat(17 - rowIdx) * pixelSize
                for (colIdx, ch) in row.enumerated() {
                    if ch == "#" {
                        let x = CGFloat(colIdx) * pixelSize
                        context.fill(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
                    }
                }
            }
            return true
        }

        image.isTemplate = true
        return image
    }

    @objc private func refreshTokenStats() {
        TokenTracker.shared.refresh()
    }

    @objc private func changeState(_ sender: NSMenuItem) {
        if let state = sender.representedObject as? PetState {
            PetManager.shared.setState(state)
        }
    }

    @objc private func triggerSpeak() {
        PetManager.shared.speak(PetQuote.random())
        SoundManager.shared.playPop()
    }

    @objc private func toggleChat() {
        DaveChatWindow.shared.toggle()
    }

    @objc private func simulateHighCPU() {
        HardwareMonitor.shared.simulateHighCPU()
    }

    @objc private func simulatePlugIn() {
        HardwareMonitor.shared.simulatePlugIn()
    }

    @objc private func snapToLeftEdge() {
        EdgePeekingService.shared.snapToEdge(.left)
    }

    @objc private func snapToRightEdge() {
        EdgePeekingService.shared.snapToEdge(.right)
    }

    @objc private func unsnapFromEdge() {
        EdgePeekingService.shared.unsnap()
    }

    @objc private func snapToBottom() {
        PetManager.shared.snapToBottom()
    }

    @objc private func toggleVisibility() {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    public func menuWillOpen(_ menu: NSMenu) {
        TokenTracker.shared.refresh()
    }
}
