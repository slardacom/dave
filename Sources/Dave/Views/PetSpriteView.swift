import SwiftUI
import AppKit

public struct PetSpriteView: View {
    let state: PetState
    @State private var currentFrameIndex: Int = 0
    @State private var timer: Timer?

    private var frames: [NSImage] {
        AssetLoader.shared.frames(for: state)
    }

    public init(state: PetState) {
        self.state = state
    }

    public var body: some View {
        Group {
            if !frames.isEmpty {
                let validIndex = currentFrameIndex % frames.count
                Image(nsImage: frames[validIndex])
                    .interpolation(.none) // Keep pixel art sharp and crisp!
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: state) { _ in
            currentFrameIndex = 0
            startAnimation()
        }
    }

    private func startAnimation() {
        stopAnimation()
        guard !frames.isEmpty else { return }

        let interval = state.frameDuration
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let count = max(1, frames.count)
            currentFrameIndex = (currentFrameIndex + 1) % count
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}
