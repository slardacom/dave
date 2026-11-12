import AppKit
import SwiftUI

public final class PetHostingView: NSHostingView<PetView> {
    private var dragStartMouseLocation: NSPoint = .zero
    private var dragStartWindowOrigin: NSPoint = .zero
    private var isDragging = false
    private var hasMovedSignificantly = false
    private var trackingArea: NSTrackingArea?

    public init() {
        super.init(rootView: PetView())
        setupLayer()
    }

    @MainActor @preconcurrency required public init(rootView: PetView) {
        super.init(rootView: rootView)
        setupLayer()
    }

    private func setupLayer() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        self.layer?.isOpaque = false
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .cursorUpdate]
        let newArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }

    public override func cursorUpdate(with event: NSEvent) {
        if isDragging {
            NSCursor.closedHand.set()
        } else {
            NSCursor.openHand.set()
        }
    }

    public override func mouseDown(with event: NSEvent) {
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartWindowOrigin = self.window?.frame.origin ?? .zero
        isDragging = true
        hasMovedSignificantly = false
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isDragging, let window = self.window else { return }

        let currentMouseLocation = NSEvent.mouseLocation
        let dx = currentMouseLocation.x - dragStartMouseLocation.x
        let dy = currentMouseLocation.y - dragStartMouseLocation.y

        if !hasMovedSignificantly && (abs(dx) > 3 || abs(dy) > 3) {
            hasMovedSignificantly = true
            NSCursor.closedHand.set()
            PetManager.shared.startDragging()
        }

        if hasMovedSignificantly {
            // Directly move the window origin in screen coordinates.
            // Screen coordinates in macOS have (0,0) at bottom-left, so dy directly adds to y!
            let newOrigin = NSPoint(
                x: dragStartWindowOrigin.x + dx,
                y: dragStartWindowOrigin.y + dy
            )
            window.setFrameOrigin(newOrigin)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        NSCursor.openHand.set()

        if hasMovedSignificantly {
            PetManager.shared.finishDragging()
        } else {
            // It was a click, not a drag
            if event.clickCount == 2 {
                PetManager.shared.cycleState()
                SoundManager.shared.playHero()
            } else {
                PetManager.shared.handlePoke()
            }
        }

        isDragging = false
        hasMovedSignificantly = false
    }

    public override func rightMouseDown(with event: NSEvent) {
        // Let SwiftUI's context menu handle right-click seamlessly
        super.rightMouseDown(with: event)
    }
}
