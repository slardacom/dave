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

        // Start file deletion monitor (Desktop / Downloads / Finder)
        FileTrashMonitor.shared.startMonitoring()

        // Welcome greeting from Dave!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            PetManager.shared.speak("你好！我是 Dave，你的桌面专属工程师搭档 🚀", duration: 5.0)
            SoundManager.shared.playHero()
        }
    }

    private func setupWindow() {
        let width: CGFloat = 220
        let height: CGFloat = 240

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

        button.title = "💻 Dave"
        button.toolTip = "Dave 桌面小宠物"

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "Dave: 桌面工程师宠物", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // State submenu
        let stateMenu = NSMenu()
        for state in PetState.allCases.filter({ $0 != .dragged }) {
            let item = NSMenuItem(title: state.displayName, action: #selector(changeState(_:)), keyEquivalent: "")
            item.representedObject = state
            item.target = self
            stateMenu.addItem(item)
        }
        let stateSubmenuItem = NSMenuItem(title: "切换状态", action: nil, keyEquivalent: "")
        stateSubmenuItem.submenu = stateMenu
        menu.addItem(stateSubmenuItem)

        menu.addItem(NSMenuItem.separator())

        let speakItem = NSMenuItem(title: "让 Dave 说句话 💬", action: #selector(triggerSpeak), keyEquivalent: "s")
        speakItem.target = self
        menu.addItem(speakItem)

        let trashMissionItem = NSMenuItem(title: "帮我扔垃圾 (动画演示) 🗑️", action: #selector(triggerTrashMission), keyEquivalent: "t")
        trashMissionItem.target = self
        menu.addItem(trashMissionItem)

        let snapItem = NSMenuItem(title: "移回屏幕底部 📍", action: #selector(snapToBottom), keyEquivalent: "b")
        snapItem.target = self
        menu.addItem(snapItem)

        let toggleVisibleItem = NSMenuItem(title: "显示 / 隐藏 Dave 👁️", action: #selector(toggleVisibility), keyEquivalent: "h")
        toggleVisibleItem.target = self
        menu.addItem(toggleVisibleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Dave 🚪", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
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

    @objc private func triggerTrashMission() {
        TrashDutyService.shared.performTrashMission()
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
