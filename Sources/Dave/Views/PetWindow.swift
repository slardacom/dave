import AppKit
import SwiftUI

public final class PetWindow: NSPanel {
    public var acceptsKeyFocus: Bool = false

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
        self.isReleasedWhenClosed = false
    }

    // Dynamic key status: allows keyboard input when the chat box is open, but stays non-intrusive otherwise
    public override var canBecomeKey: Bool {
        return acceptsKeyFocus
    }

    public override var canBecomeMain: Bool {
        return acceptsKeyFocus
    }
}
