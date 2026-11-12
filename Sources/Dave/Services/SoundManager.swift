import AppKit
import Foundation

public final class SoundManager {
    public static let shared = SoundManager()
    public var isMuted: Bool = false

    private init() {}

    public func playPop() {
        guard !isMuted else { return }
        NSSound(named: "Pop")?.play()
    }

    public func playTink() {
        guard !isMuted else { return }
        NSSound(named: "Tink")?.play()
    }

    public func playPurr() {
        guard !isMuted else { return }
        NSSound(named: "Purr")?.play()
    }

    public func playHero() {
        guard !isMuted else { return }
        NSSound(named: "Hero")?.play()
    }

    public func playDrop() {
        guard !isMuted else { return }
        NSSound(named: "Bottle")?.play()
    }
}
