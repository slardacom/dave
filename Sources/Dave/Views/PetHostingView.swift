import AppKit
import SwiftUI

public final class PetHostingView: NSHostingView<PetView> {
    private var dragStartMouseLocation: NSPoint = .zero
    private var dragStartWindowOrigin: NSPoint = .zero
    private var isDragging = false
    private var hasMovedSignificantly = false
    private var wasPeekingAtDragStart = false
    private var edgeAtDragStart: PeekingEdge? = nil
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
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .cursorUpdate]
        let trackingRect: NSRect
        if EdgePeekingService.shared.isPeeking {
            let width = bounds.width
            if EdgePeekingService.shared.currentEdge == .left {
                trackingRect = NSRect(x: 0, y: 0, width: 140, height: 160)
            } else {
                trackingRect = NSRect(x: width - 140, y: 0, width: 140, height: 160)
            }
        } else {
            trackingRect = self.bounds
        }
        let newArea = NSTrackingArea(rect: trackingRect, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if EdgePeekingService.shared.isPeeking {
            EdgePeekingService.shared.isHovered = EdgePeekingService.shared.isMouseOverPeekingDave()
        }
    }

    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        if EdgePeekingService.shared.isPeeking {
            let actual = EdgePeekingService.shared.isMouseOverPeekingDave()
            if EdgePeekingService.shared.isHovered != actual {
                EdgePeekingService.shared.isHovered = actual
            }
        }
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if EdgePeekingService.shared.isPeeking {
            EdgePeekingService.shared.isHovered = false
        }
    }

    public override func cursorUpdate(with event: NSEvent) {
        if isDragging {
            NSCursor.closedHand.set()
        } else {
            NSCursor.openHand.set()
        }
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        // If chat input or bubble is active, normal SwiftUI hit testing
        if PetManager.shared.isChatInputVisible || PetManager.shared.currentSpeech != nil {
            return super.hitTest(point)
        }

        // When tucked into edge peeking mode, Dave's visible head/hands are right at the bezel!
        if EdgePeekingService.shared.isPeeking {
            let width = bounds.width
            // Dave's sprite in peeking mode is vertically within [0, 160]
            if point.y >= 0 && point.y <= 160 {
                if EdgePeekingService.shared.currentEdge == .left {
                    // Left edge: Dave's head and hands are in [0, 140]
                    if point.x >= 0 && point.x <= 140 {
                        return self
                    }
                } else {
                    // Right edge: Dave's head and hands are in [width - 140, width]
                    if point.x >= width - 140 && point.x <= width {
                        return self
                    }
                }
            }
            return nil
        }

        // Free-floating Dave on desktop:
        // Dave's character area is roughly centered: [width/2 - 75, width/2 + 75], y in [0, 160]
        let width = bounds.width
        let charRect = NSRect(x: width / 2.0 - 75, y: 0, width: 150, height: 160)
        if charRect.contains(point) {
            return self
        }

        return super.hitTest(point)
    }

    public override func mouseDown(with event: NSEvent) {
        let mouse = NSEvent.mouseLocation
        dragStartMouseLocation = mouse
        dragStartWindowOrigin = self.window?.frame.origin ?? .zero
        isDragging = true
        hasMovedSignificantly = false
        wasPeekingAtDragStart = EdgePeekingService.shared.isPeeking
        edgeAtDragStart = EdgePeekingService.shared.currentEdge

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

        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!
        let visible = screen.visibleFrame
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height

        if !hasMovedSignificantly && (abs(dx) > 3 || abs(dy) > 3) {
            hasMovedSignificantly = true
            NSCursor.closedHand.set()

            // If user begins dragging while in edge peeking mode, pull him out smoothly!
            if EdgePeekingService.shared.isPeeking {
                EdgePeekingService.shared.unsnap(nudgeWindow: false)

                // Align window so Dave's body center is comfortably inside the screen and follows mouse
                let newOriginX: CGFloat
                if edgeAtDragStart == .left {
                    newOriginX = max(visible.minX + 20.0, currentMouseLocation.x - windowWidth / 2.0)
                } else {
                    newOriginX = min(visible.maxX - windowWidth - 20.0, currentMouseLocation.x - windowWidth / 2.0)
                }
                let newOrigin = NSPoint(x: newOriginX, y: dragStartWindowOrigin.y)
                window.setFrameOrigin(newOrigin)
                dragStartWindowOrigin = newOrigin
                dragStartMouseLocation = currentMouseLocation
            }

            PetManager.shared.startDragging()
        }

        if hasMovedSignificantly {
            let rawX = dragStartWindowOrigin.x + (currentMouseLocation.x - dragStartMouseLocation.x)
            let rawY = dragStartWindowOrigin.y + (currentMouseLocation.y - dragStartMouseLocation.y)

            // Clamping: ensure at least 60pt of window remains on-screen so Dave is never lost
            let minX = visible.minX - windowWidth + 60.0
            let maxX = visible.maxX - 60.0
            let minY = visible.minY
            let maxY = visible.maxY - windowHeight
            let clampedX = min(max(rawX, minX), maxX)
            let clampedY = min(max(rawY, minY), maxY)

            // Dynamic edge anticipation: turn face inward towards the screen when nearing borders
            if (clampedX - visible.minX) < 40.0 {
                PetManager.shared.isFacingLeft = false
            } else if (visible.maxX - (clampedX + windowWidth)) < 40.0 {
                PetManager.shared.isFacingLeft = true
            }

            let newOrigin = NSPoint(x: clampedX, y: clampedY)
            window.setFrameOrigin(newOrigin)
        } else {
            super.mouseDragged(with: event)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        NSCursor.openHand.set()

        // Capture chat input visibility BEFORE forwarding the click to SwiftUI
        let wasChatVisible = PetManager.shared.isChatInputVisible

        // Forward to SwiftUI for Button clicks
        super.mouseUp(with: event)

        if hasMovedSignificantly, let window = self.window {
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!
            let visible = screen.visibleFrame
            let currentX = window.frame.origin.x
            let windowWidth = window.frame.width
            let charCenterX = currentX + windowWidth / 2.0

            var shouldSnapLeft = false
            var shouldSnapRight = false

            // Snapping condition:
            // Snap ONLY when Dave's character center is pushed within 25pt of the bezel (partially obstructed)!
            if charCenterX < visible.minX + 25.0 {
                shouldSnapLeft = true
            } else if charCenterX > visible.maxX - 25.0 {
                shouldSnapRight = true
            }

            if shouldSnapLeft {
                EdgePeekingService.shared.snapToEdge(.left)
            } else if shouldSnapRight {
                EdgePeekingService.shared.snapToEdge(.right)
            } else {
                // Successfully dropped in desktop space!
                EdgePeekingService.shared.unsnap(nudgeWindow: false)
                PetManager.shared.finishDragging()
            }
        } else {
            // It was a click!
            if EdgePeekingService.shared.isPeeking {
                // Clicking on peeking Dave plays a cute poke reaction without pulling him out of the edge
                PetManager.shared.triggerBounce()
                SoundManager.shared.playPop()
                PetManager.shared.speak(PetQuote.quote(for: .peeking), duration: 3.5)
            } else if !wasChatVisible {
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
            } else {
                // Chat was visible! If user clicked on Dave's character (y <= 140) outside chat box, close it!
                let loc = event.locationInWindow
                if loc.y <= 140 {
                    PetManager.shared.closeChatInput()
                    SoundManager.shared.playPop()
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
