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

        // Forward event down to SwiftUI hierarchy so buttons and TextFields can receive focus & clicks
        super.mouseDown(with: event)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isDragging, let window = self.window else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let dx = currentMouseLocation.x - dragStartMouseLocation.x
        let dy = currentMouseLocation.y - dragStartMouseLocation.y

        // Don't drag window if user is typing or interacting with chat input
        if PetManager.shared.isChatInputVisible {
            super.mouseDragged(with: event)
            return
        }

        if !hasMovedSignificantly && (abs(dx) > 3 || abs(dy) > 3) {
            hasMovedSignificantly = true
            NSCursor.closedHand.set()
            PetManager.shared.startDragging()
        }

        if hasMovedSignificantly {
            let newOrigin = NSPoint(
                x: dragStartWindowOrigin.x + dx,
                y: dragStartWindowOrigin.y + dy
            )
            window.setFrameOrigin(newOrigin)
        } else {
            super.mouseDragged(with: event)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        NSCursor.openHand.set()

        // Forward to SwiftUI for Button clicks
        super.mouseUp(with: event)

        if hasMovedSignificantly {
            PetManager.shared.finishDragging()
        } else {
            // It was a click!
            if !PetManager.shared.isChatInputVisible {
                let loc = event.locationInWindow
                // Top area of Dave's window (y > 140) is the dialogue/chat action zone
                if loc.y > 140 {
                    PetManager.shared.openChatInput()
                } else {
                    if event.clickCount == 2 {
                        PetManager.shared.cycleState()
                        SoundManager.shared.playHero()
                    } else {
                        PetManager.shared.handlePoke()
                    }
                }
            }
        }

        isDragging = false
        hasMovedSignificantly = false
    }

    public override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
    }
}
