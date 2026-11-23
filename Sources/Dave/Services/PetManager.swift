import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

public final class PetManager: ObservableObject {
    public static let shared = PetManager()

    @Published public var currentState: PetState = .idle {
        didSet {
            SpriteAnimator.shared.updateState(currentState)
        }
    }
    @Published public var previousState: PetState = .idle
    @Published public var currentSpeech: String? = nil
    @Published public var currentSpeechStyle: SpeechBubbleStyle = .normal
    @Published public var isAlwaysOnTop: Bool = true
    @Published public var isHealthReminderEnabled: Bool = true
    @Published public var bounceTrigger: Bool = false
    @Published public var isFacingLeft: Bool = false
    @Published public var isChatInputVisible: Bool = false

    public weak var window: NSWindow?
    private var speechDismissTimer: Timer?
    private var reminderTimer: Timer?
    private var randomIdleTimer: Timer?

    private init() {
        startHealthReminder()
        startRandomInteractions()
    }

    public func setState(_ state: PetState) {
        setState(state, speech: nil, showQuote: true, style: .normal)
    }

    public func setState(_ state: PetState, speech: String?, showQuote: Bool = true, style: SpeechBubbleStyle = .normal) {
        if currentState != .dragged && currentState != .running {
            previousState = currentState
        }
        currentState = state

        let resolvedStyle: SpeechBubbleStyle
        if style != .normal {
            resolvedStyle = style
        } else if state == .celebrating {
            resolvedStyle = .success
        } else {
            resolvedStyle = .normal
        }

        if let speech = speech {
            speak(speech, style: resolvedStyle)
        } else if showQuote {
            speak(PetQuote.quote(for: state), style: resolvedStyle)
        }
    }

    public func startDragging() {
        if currentState != .dragged {
            previousState = currentState
            currentState = .dragged
            SoundManager.shared.playPop()
        }
    }

    public func finishDragging() {
        currentState = previousState
        SoundManager.shared.playDrop()
        triggerBounce()
    }

    public func handlePoke() {
        triggerBounce()
        SoundManager.shared.playPop()
        speak(PetQuote.random())
    }

    public func openChatInput() {
        isChatInputVisible = true
        if let win = window as? PetWindow {
            ensureWindowWithinVisibleScreen(win)
            win.acceptsKeyFocus = true
            NSApp.activate(ignoringOtherApps: true)
            win.makeKeyAndOrderFront(nil)
        }
        SoundManager.shared.playPop()
    }

    public func closeChatInput() {
        isChatInputVisible = false
        if let win = window as? PetWindow {
            win.acceptsKeyFocus = false
        }
    }

    /// Automatically nudges Dave inside visible screen bounds when opening chat so it is never clipped
    private func ensureWindowWithinVisibleScreen(_ win: NSWindow) {
        guard let screen = win.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var origin = win.frame.origin
        let width = win.frame.width
        let height = win.frame.height

        let minX = visible.minX + 8
        let maxX = visible.maxX - width - 8
        let minY = visible.minY + 8
        let maxY = visible.maxY - height - 8

        var adjusted = false
        if origin.x < minX { origin.x = minX; adjusted = true }
        if origin.x > maxX { origin.x = maxX; adjusted = true }
        if origin.y < minY { origin.y = minY; adjusted = true }
        if origin.y > maxY { origin.y = maxY; adjusted = true }

        if adjusted {
            var newFrame = win.frame
            newFrame.origin = origin
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                win.animator().setFrame(newFrame, display: true)
            }
        }
    }

    public func triggerBounce() {
        bounceTrigger.toggle()
    }

    public func cycleState() {
        let all = PetState.allCases.filter {
            $0 != .dragged && $0 != .running && $0 != .peeking && $0 != .celebrating
        }
        if let idx = all.firstIndex(of: currentState) {
            let next = all[(idx + 1) % all.count]
            setState(next)
        } else {
            setState(.idle)
        }
    }

    public func speak(_ text: String, duration: TimeInterval = 4.0, style: SpeechBubbleStyle = .normal) {
        speechDismissTimer?.invalidate()
        speechDismissTimer = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            self.currentSpeech = text
            self.currentSpeechStyle = style
        }

        // Only schedule auto-dismiss if NOT busy with an active task.
        // During task execution, speech is tied to active task progress and replaced by subsequent steps.
        if !AntigravityBridge.shared.isBusy && duration > 0 {
            speechDismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.currentSpeech = nil
                    self?.currentSpeechStyle = .normal
                }
            }
        }
    }

    public func dismissSpeech() {
        speechDismissTimer?.invalidate()
        withAnimation(.easeOut(duration: 0.2)) {
            currentSpeech = nil
            currentSpeechStyle = .normal
        }
    }

    public func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        window?.level = isAlwaysOnTop ? .floating : .normal
    }

    public func snapToBottom() {
        EdgePeekingService.shared.unsnap()
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let newX = screenRect.maxX - window.frame.width - 40
        let newY = screenRect.minY + 20
        window.setFrameOrigin(NSPoint(x: newX, y: newY))
        SoundManager.shared.playHero()
    }

    private func startHealthReminder() {
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 2400, repeats: true) { [weak self] _ in
            guard let self = self, self.isHealthReminderEnabled, !EdgePeekingService.shared.isPeeking else { return }
            self.setState(.coffee)
            self.speak("坐着敲代码快 40 分钟啦！站起来伸个懒腰、喝口水吧 💧", duration: 6.0)
            SoundManager.shared.playPurr()
        }
    }

    private func startRandomInteractions() {
        randomIdleTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            guard let self = self, self.currentState == .idle else { return }
            if Double.random(in: 0...1) < 0.35 {
                self.speak(PetQuote.random(), duration: 4.5)
            }
        }
    }
}
