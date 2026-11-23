import SwiftUI
import AppKit

public struct DaveChatView: View {
    @ObservedObject var bridge = AntigravityBridge.shared
    @ObservedObject var tracker = TokenTracker.shared
    @State private var inputText: String = ""
    var onClose: (() -> Void)?

    private let suggestions = [
        "🔍 检查当前 Git 变更与提交状态",
        "⚡️ 执行项目编译与构建测试",
        "☕️ 汇报当前开发进度与总结",
        "🧹 扫描并清理工程临时缓存"
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("💻")
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Dave · 桌面工程师")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(bridge.isBusy ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        Text(bridge.isBusy ? "全力工作中..." : "就绪 · 随时接受任务")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text(TokenTracker.formatTokens(tracker.currentUsage.totalTokens))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
                .help("当前会话 Token 消耗: \(tracker.currentUsage.totalTokens) tokens")

                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))

            Divider()

            // Chat Messages History
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(bridge.messages) { msg in
                            HStack {
                                if msg.sender == "user" {
                                    Spacer()
                                    Text(msg.content)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.blue)
                                        )
                                        .frame(maxWidth: 240, alignment: .trailing)
                                } else {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("🤖")
                                            .font(.system(size: 14))
                                            .offset(y: 2)
                                        Text(msg.content)
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color(nsColor: .controlBackgroundColor))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                                    )
                                            )
                                            .frame(maxWidth: 250, alignment: .leading)
                                    }
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: bridge.messages.count) { _ in
                    if let last = bridge.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Quick suggestion chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            inputText = suggestion
                            sendMessage()
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(Capsule().stroke(Color.blue.opacity(0.2), lineWidth: 1))
                                )
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))

            Divider()

            // Input Bar
            HStack(spacing: 8) {
                TextField("给 Dave 派发任务 (Enter 发送)...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    )
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(10)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
        }
        .frame(width: 330, height: 440)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        bridge.sendTask(prompt: text)
    }
}
