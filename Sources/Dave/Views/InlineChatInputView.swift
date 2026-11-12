import SwiftUI
import AppKit

public struct InlineChatInputView: View {
    @ObservedObject var manager = PetManager.shared
    @ObservedObject var bridge = AntigravityBridge.shared
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    private let quickPrompts = [
        ("🔍 查Git", "检查当前 Git 变更与分支状态"),
        ("⚡️ 跑测试", "执行项目编译与构建测试"),
        ("☕️ 总结", "总结当前开发进度与代码改动")
    ]

    public var body: some View {
        VStack(spacing: 6) {
            // Header bar
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(bridge.isBusy ? Color.orange : Color.green)
                        .frame(width: 6, height: 6)
                    Text(bridge.isBusy ? "Antigravity 编码中" : "派发任务给 Dave & Antigravity")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button {
                    DaveChatWindow.shared.show()
                } label: {
                    Text("历史 ↗")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Button {
                    manager.closeChatInput()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Input TextField & Send button
            HStack(spacing: 6) {
                TextField("吩咐 Dave 做点什么 (按 Enter 发送)...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .focused($isFocused)
                    .onSubmit {
                        submit()
                    }

                Button {
                    submit()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Quick Prompt Chips
            HStack(spacing: 4) {
                ForEach(quickPrompts, id: \.0) { tag, prompt in
                    Button {
                        inputText = prompt
                        submit()
                    } label: {
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 0.8))
                            )
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(10)
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.97))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                )
        )
        .onAppear {
            isFocused = true
        }
    }

    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        manager.closeChatInput()
        bridge.sendTask(prompt: text)
    }
}
