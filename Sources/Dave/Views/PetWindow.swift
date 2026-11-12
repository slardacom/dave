import AppKit
import SwiftUI

public final class PetWindow: NSPanel {
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
    }

    // Crucial: Allow clicking and dragging without stealing focus from user's active IDE or terminal
    public override var canBecomeKey: Bool {
        return false
    }

    public override var canBecomeMain: Bool {
        return false
    }
}
