import AppKit
import Foundation
import SwiftUI
import SQLite3

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

public struct TranscriptStepInfo {
    public let stepIndex: Int
    public let type: String
    public let toolName: String?
    public let toolSummary: String?
}

public struct TaskOutcome {
    public let isError: Bool
    public let errorMessage: String?
}

public final class AntigravityBridge: ObservableObject {
    public static let shared = AntigravityBridge()

    @Published public var isBusy: Bool = false
    @Published public var currentTask: String = ""
    @Published public var statusText: String = "待机中"
    @Published public var activeToolName: String = ""
    @Published public var messages: [ChatMessage] = []
    @Published public var isChatPanelOpen: Bool = false
    @Published public var conversationId: String = ""

    private let statusFileURL: URL
    private var statusMonitorTimer: Timer?
    private var agMonitorTimer: Timer?
    private var celebrationTimer: Timer?
    private var lastFileModificationDate: Date?
    private var lastProcessedStepIndex: Int = -1

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let daveDir = home.appendingPathComponent(".dave")
        try? FileManager.default.createDirectory(at: daveDir, withIntermediateDirectories: true)
        self.statusFileURL = daveDir.appendingPathComponent("status.json")

        // Initial welcome message in chat history
        messages.append(ChatMessage(
            sender: "dave",
            content: "嗨！我是 Dave。你可以直接在这里给我派发开发任务，我会实时根据工作状态展示动画并协同工作！🚀"
        ))

        startListening()
    }

    public func startListening() {
        statusMonitorTimer?.invalidate()
        agMonitorTimer?.invalidate()

        // 1. Poll external status file every 0.5s (scripts, CLI, hooks)
        statusMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkStatusFile()
        }

        // 2. Real-time Antigravity Agent Observer (0.3s interval, ultra-fast SQLite WAL + transcript inspection)
        agMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkAntigravityRealtimeStatus()
        }
    }

    // MARK: - Direct Task Dispatch to Antigravity

    public func sendTask(prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 1. Record chat message
        messages.append(ChatMessage(sender: "user", content: trimmed))

        // 2. Put Dave into busy coding mode immediately
        self.isBusy = true
        self.currentTask = trimmed
        self.statusText = "正在全力编写代码中..."

        PetManager.shared.setState(.coding, speech: "收到！正在开工：\(trimmed) 💻🔥", showQuote: false)
        // No intermediate sound on dispatch; only update status text/bubble

        // 3. Update status file
        updateStatusFile(isBusy: true, task: trimmed, text: "正在全力编码中...", state: "coding")

        // 4. Invoke Antigravity agentapi CLI in background with dynamic conversation discovery
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.dispatchToAntigravity(prompt: trimmed)
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
        let home = NSHomeDirectory()
        let agentapiCandidates = [
            "\(home)/.gemini/antigravity/bin/agentapi",
            "/Applications/Antigravity.app/Contents/Resources/bin/language_server"
        ]

        var executed = false
        let daemon = discoverDaemon()

        // Ensure we have the latest active conversation ID
        let targetCid = self.conversationId.isEmpty ? fetchLatestConversationIdFromDB() : self.conversationId

        for binary in agentapiCandidates {
            if FileManager.default.fileExists(atPath: binary) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: binary)

                var env = ProcessInfo.processInfo.environment
                if let d = daemon {
                    env["ANTIGRAVITY_LS_ADDRESS"] = "localhost:\(d.port)"
                    env["ANTIGRAVITY_CSRF_TOKEN"] = d.csrfToken
                    env["ANTIGRAVITY_APP_DATA_DIR"] = "\(home)/.gemini/antigravity"
                    if !targetCid.isEmpty {
                        env["ANTIGRAVITY_CONVERSATION_ID"] = targetCid
                    }
                }
                process.environment = env

                let taskMessage = "【来自桌面小宠物 Dave 的用户指令】\n\(prompt)\n\n（请注意：用户已在桌面小宠物 Dave 中看到你正在全力工作，请在解决任务后更新状态）"

                let isAgentApi = binary.hasSuffix("agentapi")
                if !targetCid.isEmpty {
                    var args = [
                        "send-message",
                        "--title=桌面小宠物 Dave 派发任务",
                        targetCid,
                        taskMessage
                    ]
                    if !isAgentApi {
                        args.insert("agentapi", at: 0)
                    }
                    process.arguments = args
                } else {
                    var args = [
                        "new-conversation",
                        "--title=桌面小宠物 Dave 派发任务",
                        taskMessage
                    ]
                    if !isAgentApi {
                        args.insert("agentapi", at: 0)
                    }
                    process.arguments = args
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
            "conversationId": targetCid,
            "executedViaAgentAPI": executed,
            "daemonDiscovered": daemon != nil
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) {
            try? data.write(to: inboxURL)
        }

        DispatchQueue.main.async {
            self.messages.append(ChatMessage(
                sender: "dave",
                content: "任务已送达！我现在在电脑前忙活啦，你随时可以在对话面板查看进度 💻"
            ))
        }
    }

    // MARK: - Native Antigravity State Observer (Antigravity -> Dave)

    private func checkAntigravityRealtimeStatus() {
        let home = NSHomeDirectory()
        let dbPath = (home as NSString).appendingPathComponent(".gemini/antigravity/conversation_summaries.db")
        guard FileManager.default.fileExists(atPath: dbPath) else { return }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else { return }
        defer { sqlite3_close(db) }

        // Query: prioritize any active running conversation, otherwise get the most recent one
        let sql = """
        SELECT conversation_id, title, not_fully_idle, status, last_modified_time
        FROM conversation_summaries
        ORDER BY (CASE WHEN not_fully_idle = 1 OR status = 'CASCADE_RUN_STATUS_RUNNING' THEN 0 ELSE 1 END), last_modified_time DESC
        LIMIT 1;
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return }

        guard let cCid = sqlite3_column_text(stmt, 0),
              let cStatus = sqlite3_column_text(stmt, 3) else { return }

        let cid = String(cString: cCid)
        let title = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
        let notIdle = sqlite3_column_int(stmt, 2)
        let status = String(cString: cStatus)

        let isRunning = (notIdle == 1 || status == "CASCADE_RUN_STATUS_RUNNING")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.conversationId = cid
            if !title.isEmpty && (self.currentTask.isEmpty || self.isBusy) {
                self.currentTask = title
            }
            self.handleAntigravityStateChange(cid: cid, title: title, isRunning: isRunning)
        }
    }

    private func handleAntigravityStateChange(cid: String, title: String, isRunning: Bool) {
        if isRunning {
            // Antigravity is actively executing a task!
            celebrationTimer?.invalidate()
            celebrationTimer = nil

            let wasNotBusy = !self.isBusy
            self.isBusy = true
            if wasNotBusy && !title.isEmpty {
                self.currentTask = title
            }

            // Inspect the latest step in transcript to pick the best animation
            let stepInfo = readLatestTranscriptStep(conversationId: cid)

            let targetState: PetState
            let speechText: String?
            let currentStatusText: String

            if let tool = stepInfo.toolName, !tool.isEmpty {
                self.activeToolName = tool
                let summary = stepInfo.toolSummary?.trimmingCharacters(in: CharacterSet(charactersIn: "\" '")) ?? ""

                if tool == "edit_file" || tool == "write_file" {
                    targetState = .coding
                    speechText = summary.isEmpty ? "正在疯狂码字中... 💻⚡️" : "正在修改文件: \(summary) 💻"
                    currentStatusText = "正在编写代码"
                } else if tool == "run_command" {
                    targetState = .coding
                    speechText = summary.isEmpty ? "正在执行命令 / 构建测试... ⚙️" : "正在执行: \(summary) ⚙️"
                    currentStatusText = "正在执行指令"
                } else if tool == "read_file" || tool == "search_web" || tool == "search_marketplace" || tool == "list_resources" || tool == "read_resource" {
                    targetState = .debugging
                    speechText = summary.isEmpty ? "正在抓虫思考 / 查阅资料... 🔍" : "正在查阅: \(summary) 🔍"
                    currentStatusText = "正在查阅分析"
                } else {
                    targetState = .coding
                    speechText = summary.isEmpty ? "正在调用工具 \(tool)... ⚡️" : "\(summary) ⚡️"
                    currentStatusText = "正在运行工具"
                }
            } else if stepInfo.type == "PLANNER_RESPONSE" {
                targetState = .debugging
                speechText = "正在深入思考架构与解题方案... 🧠"
                currentStatusText = "正在思考规划"
            } else if stepInfo.type == "USER_INPUT" {
                targetState = .debugging
                speechText = "收到新任务！立即开工 🚀"
                currentStatusText = "收到任务开工"
            } else {
                targetState = .coding
                speechText = "正在全力工作中... 💻"
                currentStatusText = "全力工作中"
            }

            self.statusText = currentStatusText

            // Safely apply animation state without interrupting user dragging, edge peeking or CPU overheating
            if PetManager.shared.currentState != .dragged &&
                PetManager.shared.currentState != .sweating &&
                PetManager.shared.currentState != .peeking &&
                PetManager.shared.currentState != .running &&
                !EdgePeekingService.shared.isPeeking {

                if PetManager.shared.currentState != targetState {
                    PetManager.shared.setState(targetState, speech: speechText, showQuote: false)
                } else if let speech = speechText, PetManager.shared.currentSpeech != speech {
                    // Update speech text smoothly when step description changes
                    PetManager.shared.speak(speech)
                }
            }

        } else {
            // Antigravity is IDLE
            if self.isBusy {
                self.isBusy = false
                self.activeToolName = ""

                // Refresh token consumption stats on task completion
                TokenTracker.shared.refresh()

                let outcome = inspectTaskOutcome(conversationId: cid)
                if outcome.isError {
                    self.statusText = "执行中断 ⚠️"

                    let rawErr = outcome.errorMessage ?? "遇到网络或服务异常"
                    let cleanErr: String
                    if rawErr.contains("EOF") || rawErr.contains("connect") || rawErr.contains("interrupted") || rawErr.contains("stream") {
                        cleanErr = "网络连接异常中断"
                    } else if rawErr.contains("overloaded") {
                        cleanErr = "模型服务繁忙响应超时"
                    } else {
                        cleanErr = String(rawErr.prefix(50))
                    }

                    let speechMsg = "哎呀，任务遇到网络或异常问题中断了 ⚠️"
                    self.messages.append(ChatMessage(
                        sender: "dave",
                        content: "⚠️ 任务执行中断: \(cleanErr)"
                    ))

                    if EdgePeekingService.shared.isPeeking {
                        // Folded state: stay tucked at edge! Show warning badge, play 3 peeking cycles & alert sound
                        EdgePeekingService.shared.showTaskResult(style: .failure)
                    } else {
                        // Desktop free-floating: scratch head in debugging & red bubble
                        PetManager.shared.setState(.debugging, speech: speechMsg, showQuote: false, style: .failure)
                        SoundManager.shared.playTaskFailure()

                        celebrationTimer?.invalidate()
                        celebrationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                            guard let self = self else { return }
                            if PetManager.shared.currentState == .debugging && !self.isBusy {
                                PetManager.shared.setState(.idle, speech: nil, showQuote: false)
                                self.statusText = "摸鱼待机"
                            }
                        }
                    }
                } else {
                    self.statusText = "已完成"

                    let label = self.currentTask.isEmpty ? "所有工作" : self.currentTask
                    self.messages.append(ChatMessage(
                        sender: "dave",
                        content: "🎉 刚刚完成了任务: \(label)"
                    ))

                    if EdgePeekingService.shared.isPeeking {
                        // Folded state: stay tucked at edge! Show green checkmark, play 3 peeking cycles & victory sound
                        EdgePeekingService.shared.showTaskResult(style: .success)
                    } else {
                        // Desktop free-floating: celebratory victory jump & green bubble!
                        PetManager.shared.setState(.celebrating, speech: "搞定啦！任务已顺利完成！🎉✨", showQuote: false, style: .success)
                        SoundManager.shared.playTaskSuccess()

                        celebrationTimer?.invalidate()
                        celebrationTimer = Timer.scheduledTimer(withTimeInterval: 3.8, repeats: false) { [weak self] _ in
                            guard let self = self else { return }
                            if PetManager.shared.currentState == .celebrating && !self.isBusy {
                                PetManager.shared.setState(.idle, speech: nil, showQuote: false)
                                self.statusText = "摸鱼待机"
                            }
                        }
                    }
                }
            }
        }
    }

    private func readLatestTranscriptStep(conversationId: String) -> TranscriptStepInfo {
        let home = NSHomeDirectory()
        let path = "\(home)/.gemini/antigravity/brain/\(conversationId)/.system_generated/logs/transcript.jsonl"
        guard let handle = FileHandle(forReadingAtPath: path) else {
            return TranscriptStepInfo(stepIndex: -1, type: "UNKNOWN", toolName: nil, toolSummary: nil)
        }
        defer { handle.closeFile() }

        let size = handle.seekToEndOfFile()
        guard size > 0 else {
            return TranscriptStepInfo(stepIndex: -1, type: "EMPTY", toolName: nil, toolSummary: nil)
        }

        let readSize: UInt64 = min(size, 8192)
        handle.seek(toFileOffset: size - readSize)
        let data = handle.readDataToEndOfFile()
        guard let str = String(data: data, encoding: .utf8) else {
            return TranscriptStepInfo(stepIndex: -1, type: "INVALID_UTF8", toolName: nil, toolSummary: nil)
        }

        let lines = str.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for line in lines.reversed() {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }
            let type = json["type"] as? String ?? ""
            let stepIndex = json["step_index"] as? Int ?? -1

            if let toolCalls = json["tool_calls"] as? [[String: Any]], let first = toolCalls.first {
                let name = first["name"] as? String
                let args = first["args"] as? [String: Any] ?? [:]
                let summary = args["toolSummary"] as? String
                return TranscriptStepInfo(stepIndex: stepIndex, type: type, toolName: name, toolSummary: summary)
            }

            if type == "PLANNER_RESPONSE" || type == "USER_INPUT" {
                return TranscriptStepInfo(stepIndex: stepIndex, type: type, toolName: nil, toolSummary: nil)
            }
        }

        return TranscriptStepInfo(stepIndex: -1, type: "GENERIC", toolName: nil, toolSummary: nil)
    }

    private func inspectTaskOutcome(conversationId: String) -> TaskOutcome {
        // 1. Check status.json first
        if FileManager.default.fileExists(atPath: statusFileURL.path),
           let data = try? Data(contentsOf: statusFileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let isErr = json["isError"] as? Bool, isErr {
                let errText = json["statusText"] as? String ?? json["error"] as? String
                return TaskOutcome(isError: true, errorMessage: errText)
            }
            if let st = json["state"] as? String, st == "error" || st == "failed" {
                let errText = json["statusText"] as? String
                return TaskOutcome(isError: true, errorMessage: errText)
            }
        }

        // 2. Check transcript.jsonl
        guard !conversationId.isEmpty else {
            return TaskOutcome(isError: false, errorMessage: nil)
        }

        let home = NSHomeDirectory()
        let path = "\(home)/.gemini/antigravity/brain/\(conversationId)/.system_generated/logs/transcript.jsonl"
        guard let handle = FileHandle(forReadingAtPath: path) else {
            return TaskOutcome(isError: false, errorMessage: nil)
        }
        defer { handle.closeFile() }

        let size = handle.seekToEndOfFile()
        guard size > 0 else {
            return TaskOutcome(isError: false, errorMessage: nil)
        }

        let readSize: UInt64 = min(size, 8192)
        handle.seek(toFileOffset: size - readSize)
        let data = handle.readDataToEndOfFile()
        guard let str = String(data: data, encoding: .utf8) else {
            return TaskOutcome(isError: false, errorMessage: nil)
        }

        let lines = str.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for line in lines.reversed() {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }
            let type = json["type"] as? String ?? ""
            let status = json["status"] as? String ?? ""
            let err = json["error"] as? String

            // Normal completion: latest decisive step is a successful PLANNER_RESPONSE
            if type == "PLANNER_RESPONSE" && status == "DONE" && (err == nil || err?.isEmpty == true) {
                return TaskOutcome(isError: false, errorMessage: nil)
            }

            // Error step detected
            if type == "ERROR_MESSAGE" || status == "ERROR" || (err != nil && !(err!.isEmpty)) {
                let msg = err ?? (json["content"] as? String) ?? "网络或服务异常"
                return TaskOutcome(isError: true, errorMessage: msg)
            }
        }

        return TaskOutcome(isError: false, errorMessage: nil)
    }

    private func fetchLatestConversationIdFromDB() -> String {
        let home = NSHomeDirectory()
        let dbPath = (home as NSString).appendingPathComponent(".gemini/antigravity/conversation_summaries.db")
        guard FileManager.default.fileExists(atPath: dbPath) else { return "" }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else { return "" }
        defer { sqlite3_close(db) }

        let sql = "SELECT conversation_id FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return "" }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW, let cCid = sqlite3_column_text(stmt, 0) {
            return String(cString: cCid)
        }
        return ""
    }

    // MARK: - Status File Watcher (~/.dave/status.json)

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

        let task = json["task"] as? String ?? ""
        let text = json["statusText"] as? String ?? ""
        let stateStr = json["state"] as? String ?? ""
        let action = json["action"] as? String ?? ""

        DispatchQueue.main.async {
            switch action {
            case "snap_left":
                EdgePeekingService.shared.snapToEdge(.left)
            case "snap_right":
                EdgePeekingService.shared.snapToEdge(.right)
            case "expand":
                EdgePeekingService.shared.expand(force: true)
            case "collapse":
                EdgePeekingService.shared.collapse()
            case "unsnap":
                EdgePeekingService.shared.unsnap()
            case "simulate_cpu":
                HardwareMonitor.shared.simulateHighCPU()
            case "simulate_battery":
                HardwareMonitor.shared.simulateLowBattery()
            case "simulate_plugin":
                HardwareMonitor.shared.simulatePlugIn()
            default:
                break
            }

            // Do not override animation if Dave is currently peeking at the screen edge, being dragged, or overheating
            guard !EdgePeekingService.shared.isPeeking,
                  PetManager.shared.currentState != .dragged,
                  PetManager.shared.currentState != .sweating else {
                return
            }

            // If explicit state is given in status.json, apply it
            if !stateStr.isEmpty, let explicitState = PetState(rawValue: stateStr) {
                if PetManager.shared.currentState != explicitState {
                    PetManager.shared.setState(explicitState, speech: text.isEmpty ? nil : text, showQuote: false)
                }
            }

            if let remoteBusy = json["isBusy"] as? Bool, self.isBusy != remoteBusy {
                self.isBusy = remoteBusy
                self.currentTask = task
                self.statusText = text

                if remoteBusy {
                    if PetManager.shared.currentState != .coding && PetManager.shared.currentState != .debugging {
                        PetManager.shared.setState(.coding, speech: "正在工作中: \(text) 💻⚡️", showQuote: false)
                    }
                } else {
                    let isError = json["isError"] as? Bool ?? (stateStr == "error" || stateStr == "failed")
                    if isError {
                        self.statusText = "执行中断 ⚠️"
                        self.messages.append(ChatMessage(
                            sender: "dave",
                            content: "⚠️ 任务执行中断: \(text.isEmpty ? "网络或服务异常" : text)"
                        ))

                        if EdgePeekingService.shared.isPeeking {
                            EdgePeekingService.shared.showTaskResult(style: .failure)
                        } else {
                            PetManager.shared.setState(.debugging, speech: "哎呀，任务遇到网络或异常问题中断了 ⚠️", showQuote: false, style: .failure)
                            SoundManager.shared.playTaskFailure()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                if PetManager.shared.currentState == .debugging && !self.isBusy {
                                    PetManager.shared.setState(.idle, speech: nil, showQuote: false)
                                    self.statusText = "摸鱼待机"
                                }
                            }
                        }
                    } else {
                        self.messages.append(ChatMessage(
                            sender: "dave",
                            content: "🎉 刚刚完成了任务: \(text.isEmpty ? task : text)"
                        ))

                        if EdgePeekingService.shared.isPeeking {
                            EdgePeekingService.shared.showTaskResult(style: .success)
                        } else {
                            PetManager.shared.setState(.celebrating, speech: "工作搞定: \(text) 🎉✨", showQuote: false, style: .success)
                            SoundManager.shared.playTaskSuccess()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                if PetManager.shared.currentState == .celebrating && !self.isBusy {
                                    PetManager.shared.setState(.idle, speech: nil, showQuote: false)
                                    self.statusText = "摸鱼待机"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func updateStatusFile(isBusy: Bool, task: String, text: String, state: String = "") {
        let payload: [String: Any] = [
            "isBusy": isBusy,
            "state": state,
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
