import AppKit
import Foundation
import SwiftUI

public enum PeekingEdge: String, CaseIterable {
    case left
    case right
}

public final class EdgePeekingService: ObservableObject {
    public static let shared = EdgePeekingService()

    @Published public var isPeeking: Bool = false
    @Published public var currentEdge: PeekingEdge? = nil
    @Published public var isExpanded: Bool = false
    @Published public var isHovered: Bool = false {
        didSet {
            if isHovered != oldValue {
                SpriteAnimator.shared.handleHoverChange(isHovered: isHovered)
            }
        }
    }
    @Published public var peekingResultStyle: SpeechBubbleStyle? = nil

    private var collapseTimer: Timer?
    private var resultDismissTimer: Timer?
    private var hoverCooldownUntil: TimeInterval = 0
    private var stateBeforePeeking: PetState = .idle

    private init() {}

    /// Precise check: is the mouse cursor directly on Dave's visible body while peeking?
    public func isMouseOverPeekingDave() -> Bool {
        guard isPeeking,
              ProcessInfo.processInfo.systemUptime >= hoverCooldownUntil,
              let window = PetManager.shared.window,
              let edge = currentEdge else { return false }

        let mouse = NSEvent.mouseLocation
        let winFrame = window.frame
        let daveRect: NSRect
        switch edge {
        case .left:
            // Dave clings to left screen bezel, visible in [minX, minX + 85], y: [minY, minY + 150]
            daveRect = NSRect(x: winFrame.minX, y: winFrame.minY, width: 85, height: 150)
        case .right:
            // Dave clings to right screen bezel, visible in [maxX - 85, maxX], y: [minY, minY + 150]
            daveRect = NSRect(x: winFrame.maxX - 85, y: winFrame.minY, width: 85, height: 150)
        }
        return daveRect.contains(mouse)
    }

    /// Trigger peeking animation for a specified number of cycles
    public func playPeekingCycles(count: Int = 3) {
        SpriteAnimator.shared.playPeekingCycles(count: count)
    }

    /// Displays the success or failure badge and plays peeking animation without expanding out
    public func showTaskResult(style: SpeechBubbleStyle) {
        resultDismissTimer?.invalidate()
        resultDismissTimer = nil

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            self.peekingResultStyle = style
        }

        // Play 3 cycles of peeking animation
        self.playPeekingCycles(count: 3)

        // Play sound
        if style == .success {
            SoundManager.shared.playTaskSuccess()
        } else {
            SoundManager.shared.playTaskFailure()
        }

        // Auto dismiss badge after 3 cycles (3 * 4 frames * 0.38s ≈ 4.6s)
        let totalDuration = 3.0 * Double(PetState.peeking.frameCount) * PetState.peeking.frameDuration + 0.5
        resultDismissTimer = Timer.scheduledTimer(withTimeInterval: totalDuration, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.peekingResultStyle = nil
            }
        }
    }

    /// Snaps Dave into the specified screen edge, switching to the dedicated peeking animation
    public func snapToEdge(_ edge: PeekingEdge, animate: Bool = true) {
        guard let window = PetManager.shared.window,
              let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

        collapseTimer?.invalidate()
        collapseTimer = nil
        resultDismissTimer?.invalidate()
        resultDismissTimer = nil

        if PetManager.shared.currentState != .peeking {
            self.stateBeforePeeking = PetManager.shared.currentState == .dragged ? PetManager.shared.previousState : PetManager.shared.currentState
        }

        self.isPeeking = true
        self.currentEdge = edge
        self.isExpanded = false
        self.isHovered = false
        self.peekingResultStyle = nil
        // Cooldown prevents immediate re-expansion from mouseUp over the window
        self.hoverCooldownUntil = ProcessInfo.processInfo.systemUptime + 1.2

        let visible = screen.visibleFrame
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height

        // Facing direction: always look inward toward the active screen center
        switch edge {
        case .left:
            PetManager.shared.isFacingLeft = false
        case .right:
            PetManager.shared.isFacingLeft = true
        }

        // Switch Dave to the dedicated peeking animation (clinging to bezel with hands & glasses)
        PetManager.shared.currentState = .peeking
        PetManager.shared.dismissSpeech()

        // Keep current Y within screen bounds
        var targetY = window.frame.origin.y
        let minY = visible.minY + 10
        let maxY = visible.maxY - windowHeight - 10
        targetY = min(max(targetY, minY), maxY)

        // Target X: align flush against physical screen bezel
        let targetX: CGFloat
        switch edge {
        case .left:
            targetX = visible.minX
        case .right:
            targetX = visible.maxX - windowWidth
        }

        let targetPoint = NSPoint(x: targetX, y: targetY)
        var targetFrame = window.frame
        targetFrame.origin = targetPoint

        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true)
        }

        SoundManager.shared.playPop()
    }

    /// Expands Dave smoothly out of the edge when the user hovers over him or clicks
    public func expand(force: Bool = false) {
        guard isPeeking, !isExpanded,
              let window = PetManager.shared.window,
              let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first,
              let edge = currentEdge else { return }

        // Block accidental hover expansion immediately after mouse drop
        if !force && ProcessInfo.processInfo.systemUptime < hoverCooldownUntil {
            return
        }

        collapseTimer?.invalidate()
        collapseTimer = nil
        isExpanded = true

        let visible = screen.visibleFrame
        let windowWidth = window.frame.width
        let currentY = window.frame.origin.y

        // Expanded position: step 80 points inward from the bezel so Dave's full body and speech bubble fit comfortably
        let targetX: CGFloat
        switch edge {
        case .left:
            targetX = visible.minX + 80
        case .right:
            targetX = visible.maxX - windowWidth - 80
        }

        var expandedFrame = window.frame
        expandedFrame.origin = NSPoint(x: targetX, y: currentY)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(expandedFrame, display: true)
        }

        // Restore normal body state so full character is displayed
        let targetState = (stateBeforePeeking == .peeking) ? .idle : stateBeforePeeking
        PetManager.shared.setState(targetState, speech: "嘿！被你发现啦！👋", showQuote: false)
        SoundManager.shared.playPop()
        PetManager.shared.triggerBounce()
    }

    /// Schedules Dave to tuck back into the screen edge after mouse leaves
    public func scheduleCollapse(delay: TimeInterval = 2.2) {
        guard isPeeking, isExpanded, !PetManager.shared.isChatInputVisible else { return }

        collapseTimer?.invalidate()
        collapseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isPeeking, self.isExpanded, !PetManager.shared.isChatInputVisible else { return }
            self.collapse()
        }
    }

    /// Tucks Dave back into the edge with the peeking animation
    public func collapse() {
        guard isPeeking, isExpanded, !PetManager.shared.isChatInputVisible,
              let window = PetManager.shared.window,
              let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first,
              let edge = currentEdge else { return }

        collapseTimer?.invalidate()
        collapseTimer = nil
        isExpanded = false

        let visible = screen.visibleFrame
        let windowWidth = window.frame.width
        let currentY = window.frame.origin.y

        // Tucked position: flush with screen border
        let targetX: CGFloat
        switch edge {
        case .left:
            targetX = visible.minX
        case .right:
            targetX = visible.maxX - windowWidth
        }

        var collapsedFrame = window.frame
        collapsedFrame.origin = NSPoint(x: targetX, y: currentY)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(collapsedFrame, display: true)
        }

        // Switch back to peeking animation!
        PetManager.shared.currentState = .peeking
        PetManager.shared.dismissSpeech()
        SoundManager.shared.playPurr()
    }

    /// Unsnaps Dave and restores free-floating mode
    public func unsnap(nudgeWindow: Bool = true) {
        guard isPeeking else { return }

        collapseTimer?.invalidate()
        collapseTimer = nil
        resultDismissTimer?.invalidate()
        resultDismissTimer = nil
        isPeeking = false
        currentEdge = nil
        isExpanded = false
        isHovered = false
        peekingResultStyle = nil

        // Switch out of peeking state back to regular state
        if PetManager.shared.currentState == .peeking {
            let targetState = (stateBeforePeeking == .peeking) ? .idle : stateBeforePeeking
            PetManager.shared.setState(targetState)
        }

        // Ensure window is comfortably inside visible frame if requested (e.g. from menu)
        if nudgeWindow,
           let window = PetManager.shared.window,
           let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first {
            let visible = screen.visibleFrame
            var origin = window.frame.origin
            let width = window.frame.width

            if origin.x < visible.minX + 20 {
                origin.x = visible.minX + 35
                window.setFrameOrigin(origin)
            } else if origin.x + width > visible.maxX - 20 {
                origin.x = visible.maxX - width - 35
                window.setFrameOrigin(origin)
            }
        }
    }
}
