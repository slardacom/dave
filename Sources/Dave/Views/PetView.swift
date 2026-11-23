import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct PetView: View {
    @ObservedObject var manager = PetManager.shared
    @ObservedObject var bridge = AntigravityBridge.shared
    @ObservedObject var peeking = EdgePeekingService.shared
    @State private var bounceScale: CGFloat = 1.0

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Dave Sprite & Real Carried File (Anchored strictly at bottom of window, completely stationary)
            characterArea
                .frame(width: 260, height: 140)
                .padding(.bottom, 8)

            // Top Section: Inline Chat Input OR Speech Bubble OR Quick Dialogue Button
            // Floats strictly above Dave's head without affecting Dave's position
            VStack(spacing: 0) {
                Spacer()

                if manager.isChatInputVisible {
                    InlineChatInputView()
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .frame(height: 100)
                } else if let speech = activeSpeechText, manager.currentState != .peeking {
                    SpeechBubbleView(text: speech, style: activeSpeechStyle) {
                        manager.openChatInput()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.75).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .padding(.horizontal, 8)
                    .frame(maxHeight: 80)
                } else if !bridge.isBusy && manager.currentState != .peeking {
                    Button {
                        manager.openChatInput()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 9))
                            Text("💬 对话")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.88))
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .frame(height: 24)
                    .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 148) // Sits directly on top of Dave's head
        }
        .frame(width: 260, height: 260)
        .padding(6)
        .onChange(of: manager.bounceTrigger) { _ in
            triggerBounce()
        }
    }

    private var activeSpeechText: String? {
        if let s = manager.currentSpeech, !s.isEmpty {
            return s
        }
        if bridge.isBusy {
            return bridge.statusText.isEmpty ? "正在工作中... 💻" : bridge.statusText
        }
        return nil
    }

    private var activeSpeechStyle: SpeechBubbleStyle {
        if manager.currentSpeech != nil {
            return manager.currentSpeechStyle
        }
        if manager.currentState == .celebrating {
            return .success
        }
        return .normal
    }

    @ViewBuilder
    private var characterArea: some View {
        ZStack {
            // Subtle flat shadow under Dave's feet / desk (hide when clinging/peeking against wall)
            let isDeskState = manager.currentState == .coding || manager.currentState == .debugging || manager.currentState == .sweating
            Ellipse()
                .fill(Color.black.opacity(manager.currentState == .dragged ? 0.08 : (manager.currentState == .peeking ? 0.0 : 0.22)))
                .frame(width: isDeskState ? 120 : 80, height: 14)
                .offset(y: 52)
                .scaleEffect(manager.currentState == .dragged ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: manager.currentState)

            // Dave Character Sprite
            // In peeking mode, shift flush to the window edge so Dave's hands grip the physical screen bezel directly!
            let peekingOffsetX: CGFloat = (manager.currentState == .peeking) ? (manager.isFacingLeft ? 66 : -66) : 0
            PetSpriteView(state: manager.currentState)
                .frame(width: 140, height: 140)
                .scaleEffect(x: manager.isFacingLeft ? -1 : 1, y: 1)
                .offset(x: peekingOffsetX)
                .scaleEffect(bounceScale)
                .scaleEffect(manager.currentState == .dragged ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: manager.currentState)

            // In folded state, display execution indicator or completion checkmark directly above Dave's head
            let peekingHeadX: CGFloat = manager.isFacingLeft ? 112 : -112
            if manager.currentState == .peeking {
                if let result = peeking.peekingResultStyle {
                    PeekingResultBadge(style: result)
                        .offset(x: peekingHeadX, y: -52)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                        .onTapGesture {
                            withAnimation {
                                peeking.peekingResultStyle = nil
                            }
                        }
                } else if bridge.isBusy {
                    PeekingBusyBadge()
                        .offset(x: peekingHeadX, y: -52)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        // Context Menu on Right-Click
        .contextMenu {
            menuContent
        }
    }

    private func triggerBounce() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        Button {
            manager.toggleAlwaysOnTop()
        } label: {
            Label(
                manager.isAlwaysOnTop ? "取消置顶" : "保持置顶",
                systemImage: manager.isAlwaysOnTop ? "pin.fill" : "pin"
            )
        }

        Button {
            manager.isHealthReminderEnabled.toggle()
        } label: {
            Label(
                manager.isHealthReminderEnabled ? "喝水/工休提醒: 开" : "喝水/工休提醒: 关",
                systemImage: manager.isHealthReminderEnabled ? "drop.fill" : "drop"
            )
        }

        Button {
            SoundManager.shared.isMuted.toggle()
        } label: {
            Label(
                SoundManager.shared.isMuted ? "开启音效" : "静音",
                systemImage: SoundManager.shared.isMuted ? "speaker.slash" : "speaker.wave.2"
            )
        }

        Button {
            manager.snapToBottom()
        } label: {
            Label("回到底部边缘", systemImage: "arrow.down.to.line")
        }

        Divider()

        Button(role: .destructive) {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出 Dave", systemImage: "power")
        }
    }
}

public struct PeekingResultBadge: View {
    let style: SpeechBubbleStyle
    @State private var bounce: CGFloat = 0.6

    public var body: some View {
        Group {
            if let img = AssetLoader.shared.iconImage(named: style == .success ? "success" : "failure") {
                Image(nsImage: img)
                    .interpolation(.none) // Keep pixel art sharp and crisp!
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .scaleEffect(bounce)
                    .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                bounce = 1.0
            }
        }
    }
}

public struct PeekingBusyBadge: View {
    @State private var currentFrame: Int = 0
    @State private var timer: Timer?

    private var frames: [NSImage] {
        AssetLoader.shared.busyIconFrames()
    }

    public var body: some View {
        Group {
            if !frames.isEmpty {
                let img = frames[currentFrame % frames.count]
                Image(nsImage: img)
                    .interpolation(.none) // Keep pixel art sharp and crisp!
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
            }
        }
        .onAppear {
            startLoop()
        }
        .onDisappear {
            stopLoop()
        }
    }

    private func startLoop() {
        stopLoop()
        guard !frames.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { _ in
            let count = max(1, frames.count)
            currentFrame = (currentFrame + 1) % count
        }
    }

    private func stopLoop() {
        timer?.invalidate()
        timer = nil
    }
}
