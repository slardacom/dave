import AppKit
import SwiftUI

public final class DaveChatWindow: NSPanel {
    public static let shared = DaveChatWindow()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 330, height: 440),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = true
        self.animationBehavior = .none

        let contentView = DaveChatView { [weak self] in
            self?.hide()
        }
        let hosting = NSHostingView(rootView: contentView)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = hosting
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public func toggle() {
        if self.isVisible {
            hide()
        } else {
            show()
        }
    }

    public func show() {
        positionBesidePet()
        self.orderFrontRegardless()
        self.makeKey()
        AntigravityBridge.shared.isChatPanelOpen = true
        SoundManager.shared.playPop()
    }

    public func hide() {
        self.orderOut(nil)
        AntigravityBridge.shared.isChatPanelOpen = false
    }

    private func positionBesidePet() {
        guard let petWin = PetManager.shared.window,
              let screen = petWin.screen ?? NSScreen.main else { return }

        let petFrame = petWin.frame
        let chatWidth: CGFloat = 330
        let chatHeight: CGFloat = 440

        var newX = petFrame.minX - chatWidth - 12
        if newX < screen.visibleFrame.minX {
            // Not enough room on the left, place on the right
            newX = petFrame.maxX + 12
        }

        var newY = petFrame.minY
        if newY + chatHeight > screen.visibleFrame.maxY {
            newY = screen.visibleFrame.maxY - chatHeight - 10
        }
        if newY < screen.visibleFrame.minY {
            newY = screen.visibleFrame.minY + 10
        }

        self.setFrameOrigin(CGPoint(x: newX, y: newY))
    }
}
