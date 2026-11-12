import AppKit
import Foundation
import SwiftUI

public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let sender: String // "user" or "dave"
    public let content: String
    public let timestamp = Date()
}

public struct AntigravityDaemonInfo {
    public let port: Int
    public let csrfToken: String
}

public final class AntigravityBridge: ObservableObject {
    public static let shared = AntigravityBridge()

    @Published public var isBusy: Bool = false
    @Published public var currentTask: String = ""
    @Published public var statusText: String = "待机中"
    @Published public var messages: [ChatMessage] = []
    @Published public var isChatPanelOpen: Bool = false

    public var conversationId: String = "eba2deb0-6e33-43c0-8920-1896215f35b2"
    private let statusFileURL: URL
    private var statusMonitorTimer: Timer?
    private var lastFileModificationDate: Date?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let daveDir = home.appendingPathComponent(".dave")
        try? FileManager.default.createDirectory(at: daveDir, withIntermediateDirectories: true)
        self.statusFileURL = daveDir.appendingPathComponent("status.json")

        // Initial welcome message in chat history
        messages.append(ChatMessage(
            sender: "dave",
            content: "嗨！我是 Dave。你可以直接在这里给我派发开发任务，我会立刻呼叫 Antigravity 开工！🚀"
        ))

        startListening()
    }

    public func startListening() {
        statusMonitorTimer?.invalidate()
        // Poll status file every 0.5s for real-time synchronization
        statusMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkStatusFile()
        }
    }

    public func sendTask(prompt: String) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 1. Record chat message
        messages.append(ChatMessage(sender: "user", content: prompt))

        // 2. Put Dave into busy coding mode immediately
        self.isBusy = true
        self.currentTask = prompt
        self.statusText = "正在全力调用 Antigravity 编码中..."

        PetManager.shared.setState(.coding)
        SoundManager.shared.playPop()
        PetManager.shared.speak("收到！正在让 Antigravity 开工：\(prompt) 💻🔥", duration: 4.0)

        // 3. Update status file
        updateStatusFile(isBusy: true, task: prompt, text: "正在全力编码中...")

        // 4. Invoke Antigravity agentapi CLI in background with auto-discovered daemon config
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.dispatchToAntigravity(prompt: prompt)
        }
    }

    /// Automatically scans and discovers the running Antigravity daemon port & csrfToken
    public func discoverDaemon() -> AntigravityDaemonInfo? {
        let daemonDir = URL(fileURLWithPath: NSHomeDirectory() + "/.gemini/antigravity/daemon")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: daemonDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return nil
        }

        let hubFiles = files.filter { $0.lastPathComponent.hasPrefix("hub_") && $0.pathExtension == "json" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return d1 > d2
            }

        for file in hubFiles {
            if let data = try? Data(contentsOf: file),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let port = json["httpPort"] as? Int,
               let token = json["csrfToken"] as? String {
                return AntigravityDaemonInfo(port: port, csrfToken: token)
            }
        }
        return nil
    }

    private func dispatchToAntigravity(prompt: String) {
        let agentapiCandidates = [
            "/Users/suwenbo/.gemini/antigravity/bin/agentapi",
            "/Applications/Antigravity.app/Contents/Resources/bin/language_server"
        ]

        var executed = false
        let daemon = discoverDaemon()

        for binary in agentapiCandidates {
            if FileManager.default.fileExists(atPath: binary) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: binary)

                // Inject Antigravity daemon environment variables
                var env = ProcessInfo.processInfo.environment
                if let d = daemon {
                    env["ANTIGRAVITY_LS_ADDRESS"] = "localhost:\(d.port)"
                    env["ANTIGRAVITY_CSRF_TOKEN"] = d.csrfToken
                    env["ANTIGRAVITY_APP_DATA_DIR"] = NSHomeDirectory() + "/.gemini/antigravity"
                    env["ANTIGRAVITY_CONVERSATION_ID"] = self.conversationId
                }
                process.environment = env

                let taskMessage = "【来自桌面小宠物 Dave 的用户指令】\n\(prompt)\n\n（请注意：用户已在桌面小宠物 Dave 中看到你正在全力工作，请在解决任务后更新状态）"

                if binary.hasSuffix("agentapi") {
                    process.arguments = [
                        "send-message",
                        "--title=桌面小宠物 Dave 派发任务",
                        self.conversationId,
                        taskMessage
                    ]
                } else {
                    process.arguments = [
                        "agentapi",
                        "send-message",
                        "--title=桌面小宠物 Dave 派发任务",
                        self.conversationId,
                        taskMessage
                    ]
                }

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    executed = true
                    break
                } catch {
                    // Try next candidate
                }
            }
        }

        // Always write inbox backup
        let inboxURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".dave/inbox.json")
        let payload: [String: Any] = [
            "task": prompt,
            "timestamp": Date().timeIntervalSince1970,
            "conversationId": self.conversationId,
            "executedViaAgentAPI": executed,
            "daemonDiscovered": daemon != nil
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) {
            try? data.write(to: inboxURL)
        }

        DispatchQueue.main.async {
            self.messages.append(ChatMessage(
                sender: "dave",
                content: "任务已送达 Antigravity 核心大脑！我现在在电脑前忙活啦，你随时可以在对话面板查看进度 💻"
            ))
        }
    }

    private func checkStatusFile() {
        guard FileManager.default.fileExists(atPath: statusFileURL.path) else { return }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: statusFileURL.path),
              let modDate = attrs[.modificationDate] as? Date else { return }

        if lastFileModificationDate != nil && modDate == lastFileModificationDate {
            return
        }
        lastFileModificationDate = modDate

        guard let data = try? Data(contentsOf: statusFileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let remoteBusy = json["isBusy"] as? Bool ?? false
        let task = json["task"] as? String ?? ""
        let text = json["statusText"] as? String ?? ""

        DispatchQueue.main.async {
            if self.isBusy != remoteBusy {
                self.isBusy = remoteBusy
                self.currentTask = task
                self.statusText = text

                if remoteBusy {
                    // Antigravity is busy -> Dave sits at laptop and codes!
                    if PetManager.shared.currentState != .coding {
                        PetManager.shared.setState(.coding)
                        SoundManager.shared.playTink()
                        let label = task.isEmpty ? text : task
                        PetManager.shared.speak("Antigravity 正在工作中: \(label) 💻⚡️", duration: 4.5)
                    }
                } else {
                    // Antigravity finished -> Dave celebrates!
                    PetManager.shared.setState(.celebrating)
                    SoundManager.shared.playHero()
                    let label = text.isEmpty ? "任务全部搞定！" : text
                    PetManager.shared.speak("Antigravity 工作搞定: \(label) 🎉✨", duration: 4.0)

                    self.messages.append(ChatMessage(
                        sender: "dave",
                        content: "🎉 Antigravity 刚刚完成了任务: \(label)"
                    ))

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        if PetManager.shared.currentState == .celebrating {
                            PetManager.shared.setState(.idle)
                        }
                    }
                }
            }
        }
    }

    public func updateStatusFile(isBusy: Bool, task: String, text: String) {
        let payload: [String: Any] = [
            "isBusy": isBusy,
            "task": task,
            "statusText": text,
            "conversationId": self.conversationId,
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) {
            try? data.write(to: statusFileURL)
        }
    }
}
