import SwiftUI
import AppKit

public struct PetSpriteView: View {
    let state: PetState
    @ObservedObject var animator = SpriteAnimator.shared

    private var frames: [NSImage] {
        AssetLoader.shared.frames(for: state)
    }

    public init(state: PetState) {
        self.state = state
    }

    public var body: some View {
        Group {
            if !frames.isEmpty {
                let validIndex = animator.currentFrameIndex % frames.count
                Image(nsImage: frames[validIndex])
                    .interpolation(.none) // Keep pixel art sharp and crisp!
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
