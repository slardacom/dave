import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

public final class PetManager: ObservableObject {
    public static let shared = PetManager()

    @Published public var currentState: PetState = .idle
    @Published public var previousState: PetState = .idle
    @Published public var currentSpeech: String? = nil
    @Published public var isAlwaysOnTop: Bool = true
    @Published public var isHealthReminderEnabled: Bool = true
    @Published public var bounceTrigger: Bool = false
    @Published public var isFacingLeft: Bool = false
    @Published public var isChatInputVisible: Bool = false

    // Real carried file properties
    @Published public var carriedFileIcon: NSImage? = nil
    @Published public var carriedFileName: String? = nil
    @Published public var isThrowingFile: Bool = false

    public weak var window: NSWindow?
    private var speechDismissTimer: Timer?
    private var reminderTimer: Timer?
    private var randomIdleTimer: Timer?

    private init() {
        startHealthReminder()
        startRandomInteractions()
    }

    public func setState(_ state: PetState) {
        if currentState != .dragged {
            previousState = currentState
        }
        currentState = state
        speak(PetQuote.quote(for: state))
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

    public func triggerBounce() {
        bounceTrigger.toggle()
    }

    public func cycleState() {
        let all = PetState.allCases.filter {
            $0 != .dragged && $0 != .running && $0 != .carrying && $0 != .throwing && $0 != .celebrating
        }
        if let idx = all.firstIndex(of: currentState) {
            let next = all[(idx + 1) % all.count]
            setState(next)
        } else {
            setState(.idle)
        }
    }

    public func speak(_ text: String, duration: TimeInterval = 4.0) {
        speechDismissTimer?.invalidate()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            self.currentSpeech = text
        }

        speechDismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.currentSpeech = nil
            }
        }
    }

    public func dismissSpeech() {
        speechDismissTimer?.invalidate()
        withAnimation(.easeOut(duration: 0.2)) {
            currentSpeech = nil
        }
    }

    public func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        window?.level = isAlwaysOnTop ? .floating : .normal
    }

    public func snapToBottom() {
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let newX = screenRect.maxX - window.frame.width - 40
        let newY = screenRect.minY + 20
        window.setFrameOrigin(NSPoint(x: newX, y: newY))
        SoundManager.shared.playHero()
    }

    public static func resolveIcon(name: String, path: String? = nil) -> NSImage {
        if let path = path, FileManager.default.fileExists(atPath: path) {
            let img = NSWorkspace.shared.icon(forFile: path)
            img.size = NSSize(width: 56, height: 56)
            return img
        }
        let ext = (name as NSString).pathExtension
        if !ext.isEmpty, let uti = UTType(filenameExtension: ext) {
            let img = NSWorkspace.shared.icon(for: uti)
            img.size = NSSize(width: 56, height: 56)
            return img
        }
        let img = NSWorkspace.shared.icon(for: .item)
        img.size = NSSize(width: 56, height: 56)
        return img
    }

    private func startHealthReminder() {
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 2400, repeats: true) { [weak self] _ in
            guard let self = self, self.isHealthReminderEnabled else { return }
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
