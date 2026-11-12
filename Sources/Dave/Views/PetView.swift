import SwiftUI
import AppKit

public struct PetView: View {
    @ObservedObject var manager = PetManager.shared
    @State private var dragInitialOrigin: CGPoint? = nil
    @State private var bounceScale: CGFloat = 1.0
    @State private var isHovering: Bool = false

    public var body: some View {
        VStack(spacing: 4) {
            // Speech Bubble (Above Dave)
            if let speech = manager.currentSpeech {
                SpeechBubbleView(text: speech) {
                    manager.dismissSpeech()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity),
                    removal: .opacity
                ))
                .padding(.horizontal, 8)
                .frame(maxHeight: 70)
            } else {
                Spacer().frame(height: 16)
            }

            // Dave Sprite
            ZStack {
                // Subtle shadow under Dave's feet
                Ellipse()
                    .fill(Color.black.opacity(manager.currentState == .dragged ? 0.08 : 0.22))
                    .frame(width: 80, height: 14)
                    .offset(y: 52)
                    .scaleEffect(manager.currentState == .dragged ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: manager.currentState)

                PetSpriteView(state: manager.currentState)
                    .frame(width: 140, height: 140)
                    .scaleEffect(bounceScale)
                    .scaleEffect(manager.currentState == .dragged ? 1.08 : 1.0)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            }
            .contentShape(Rectangle())
            // Context Menu on Right-Click
            .contextMenu {
                menuContent
            }
            // Tap Interaction
            .onTapGesture(count: 2) {
                // Double tap: cycle state
                manager.cycleState()
                triggerBounce()
                SoundManager.shared.playHero()
            }
            .onTapGesture(count: 1) {
                // Single tap: poke Dave!
                triggerBounce()
                SoundManager.shared.playPop()
                manager.speak(PetQuote.random())
            }
            // Drag gesture for moving around screen
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        if dragInitialOrigin == nil {
                            dragInitialOrigin = manager.window?.frame.origin
                            manager.setState(.dragged)
                            SoundManager.shared.playPop()
                        }
                        if let initial = dragInitialOrigin, let window = manager.window {
                            // macOS screen coordinates: Y goes upwards, so subtracting translation.height
                            let newX = initial.x + value.translation.width
                            let newY = initial.y - value.translation.height
                            window.setFrameOrigin(CGPoint(x: newX, y: newY))
                        }
                    }
                    .onEnded { _ in
                        dragInitialOrigin = nil
                        triggerBounce()
                        SoundManager.shared.playDrop()
                        manager.currentState = manager.previousState
                    }
            )
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .frame(width: 220, height: 240)
        .padding(8)
    }

    private func triggerBounce() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        Section("Dave 状态切换") {
            ForEach(PetState.allCases.filter { $0 != .dragged }) { state in
                Button {
                    manager.setState(state)
                    SoundManager.shared.playTink()
                } label: {
                    Label(
                        state.displayName,
                        systemImage: manager.currentState == state ? "checkmark.circle.fill" : state.icon
                    )
                }
            }
        }

        Divider()

        Section("互动与实用功能") {
            Button {
                manager.speak(PetQuote.random())
                SoundManager.shared.playPop()
            } label: {
                Label("说句骚话 💬", systemImage: "bubble.left")
            }

            Button {
                manager.toggleAlwaysOnTop()
            } label: {
                Label(
                    manager.isAlwaysOnTop ? "取消置顶" : "保持置顶 📌",
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
                    SoundManager.shared.isMuted ? "开启音效 🔊" : "静音 🔇",
                    systemImage: SoundManager.shared.isMuted ? "speaker.slash" : "speaker.wave.2"
                )
            }

            Button {
                manager.snapToBottom()
            } label: {
                Label("回到底部边缘 📍", systemImage: "arrow.down.to.line")
            }
        }

        Divider()

        Button(role: .destructive) {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出 Dave 🚪", systemImage: "power")
        }
    }
}
