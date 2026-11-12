import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct PetView: View {
    @ObservedObject var manager = PetManager.shared
    @ObservedObject var bridge = AntigravityBridge.shared
    @State private var bounceScale: CGFloat = 1.0
    @State private var isDropTargeted: Bool = false

    public var body: some View {
        VStack(spacing: 4) {
            // Speech Bubble or Quick Chat Pill (Above Dave)
            if let speech = manager.currentSpeech {
                SpeechBubbleView(text: speech) {
                    DaveChatWindow.shared.toggle()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity),
                    removal: .opacity
                ))
                .padding(.horizontal, 8)
                .frame(maxHeight: 70)
            } else {
                Button {
                    DaveChatWindow.shared.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 9))
                        Text(bridge.isBusy ? "编码中..." : "对话")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(bridge.isBusy ? Color.orange.opacity(0.9) : Color.blue.opacity(0.85)))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .frame(height: 20)
            }

            // Dave Sprite & Real Carried File
            ZStack {
                // Subtle flat shadow under Dave's feet (no blur filter to avoid ghosting)
                Ellipse()
                    .fill(Color.black.opacity(manager.currentState == .dragged ? 0.08 : 0.22))
                    .frame(width: 80, height: 14)
                    .offset(y: 52)
                    .scaleEffect(manager.currentState == .dragged ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: manager.currentState)

                // Dave Character Sprite
                PetSpriteView(state: manager.currentState)
                    .frame(width: 140, height: 140)
                    .scaleEffect(x: manager.isFacingLeft ? -1 : 1, y: 1)
                    .scaleEffect(bounceScale)
                    .scaleEffect(manager.currentState == .dragged ? 1.08 : 1.0)

                // Real Carried File Component (Held above Dave's head)
                if let fileIcon = manager.carriedFileIcon {
                    VStack(spacing: 2) {
                        Image(nsImage: fileIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

                        if let fname = manager.carriedFileName {
                            Text(fname)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.6)))
                        }
                    }
                    .offset(
                        x: manager.isThrowingFile ? (manager.isFacingLeft ? -50 : 50) : 0,
                        y: manager.isThrowingFile ? 65 : -42
                    )
                    .scaleEffect(manager.isThrowingFile ? 0.2 : 1.0)
                    .opacity(manager.isThrowingFile ? 0.0 : 1.0)
                    .animation(.easeIn(duration: 0.42), value: manager.isThrowingFile)
                }
            }
            .contentShape(Rectangle())
            // Drag-and-drop file onto Dave directly!
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleFileDrop(providers: providers)
            }
            // Context Menu on Right-Click
            .contextMenu {
                menuContent
            }
        }
        .frame(width: 220, height: 240)
        .padding(8)
        .onChange(of: manager.bounceTrigger) { _ in
            triggerBounce()
        }
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let fileURL = url else { return }
            DispatchQueue.main.async {
                let name = fileURL.lastPathComponent
                let icon = PetManager.resolveIcon(name: name, path: fileURL.path)
                let mouse = NSEvent.mouseLocation
                TrashDutyService.shared.performPhysicalTrashMission(fileURL: fileURL, name: name, icon: icon, at: mouse)
            }
        }
        return true
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
        Section("Dave 状态切换") {
            ForEach(PetState.allCases.filter {
                $0 != .dragged && $0 != .running && $0 != .carrying && $0 != .throwing && $0 != .celebrating
            }) { state in
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

        Section("特色功能") {
            Button {
                DaveChatWindow.shared.toggle()
            } label: {
                Label("与 Dave 对话 (调用 Antigravity) 💬", systemImage: "message.fill")
            }

            Button {
                TrashDutyService.shared.performTrashMission()
            } label: {
                Label("帮我扔垃圾 (动画演示) 🗑️", systemImage: "trash.circle")
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
