import Foundation
import AppKit

/// Centralized animator responsible for driving sprite frames across all states.
/// By maintaining a single source of truth and a single Timer reference, we guarantee
/// that timers never leak or duplicate across view re-renders.
public final class SpriteAnimator: ObservableObject {
    public static let shared = SpriteAnimator()

    @Published public var currentFrameIndex: Int = 0

    private var timer: Timer?
    private var cyclesRemaining: Int = 0

    private init() {
        startLoop(for: PetManager.shared.currentState)
    }

    /// Called whenever PetManager.currentState changes
    public func updateState(_ state: PetState) {
        stop()
        currentFrameIndex = 0
        cyclesRemaining = 0

        if state == .peeking {
            // Folded state defaults to static frame 0.
            // Animate only if the mouse is physically over Dave right now.
            if EdgePeekingService.shared.isMouseOverPeekingDave() {
                EdgePeekingService.shared.isHovered = true
                startPeekingLoop()
            } else {
                EdgePeekingService.shared.isHovered = false
            }
        } else {
            startLoop(for: state)
        }
    }

    /// Called when mouse hover status over peeking Dave changes
    public func handleHoverChange(isHovered: Bool) {
        guard PetManager.shared.currentState == .peeking else { return }

        if isHovered {
            if timer == nil {
                startPeekingLoop()
            }
        } else {
            // If mouse left and no requested task cycles are running, stop immediately and lock to frame 0
            if cyclesRemaining == 0 {
                stop()
                currentFrameIndex = 0
            }
        }
    }

    /// Plays a specific number of peeking animation cycles (e.g. 3 cycles for task completion/failure)
    public func playPeekingCycles(count: Int = 3) {
        guard PetManager.shared.currentState == .peeking else { return }
        self.cyclesRemaining = count
        if timer == nil {
            startPeekingLoop()
        }
    }

    private func startLoop(for state: PetState) {
        stop()
        let frames = AssetLoader.shared.frames(for: state)
        guard frames.count > 1 else { return }

        let interval = state.frameDuration
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let count = max(1, AssetLoader.shared.frames(for: PetManager.shared.currentState).count)
            self.currentFrameIndex = (self.currentFrameIndex + 1) % count
        }
    }

    private func startPeekingLoop() {
        stop()
        let interval = PetState.peeking.frameDuration
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard PetManager.shared.currentState == .peeking else {
                self.stop()
                return
            }

            let count = max(1, AssetLoader.shared.frames(for: .peeking).count)
            let nextIndex = (self.currentFrameIndex + 1) % count
            self.currentFrameIndex = nextIndex

            // On completing a full 4-frame cycle (transitioning back to 0)
            if nextIndex == 0 {
                if self.cyclesRemaining > 0 {
                    self.cyclesRemaining -= 1
                }

                let isStillHovered = EdgePeekingService.shared.isMouseOverPeekingDave()
                EdgePeekingService.shared.isHovered = isStillHovered

                if self.cyclesRemaining == 0 && !isStillHovered {
                    self.stop()
                    self.currentFrameIndex = 0
                }
            }
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
