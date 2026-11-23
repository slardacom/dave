import Foundation
import Combine

public struct ConversationTokenUsage: Equatable {
    public var inputTokens: Int = 0
    public var outputTokens: Int = 0
    public var cacheReadTokens: Int = 0
    public var stepCount: Int = 0
    public var title: String = ""
    public var conversationId: String = ""

    public var totalTokens: Int {
        inputTokens + outputTokens
    }
}

public struct DailyTokenUsage: Equatable {
    public var totalTokens: Int = 0
    public var inputTokens: Int = 0
    public var outputTokens: Int = 0
    public var cacheReadTokens: Int = 0
    public var activeConversationsCount: Int = 0
}

public final class TokenTracker: ObservableObject {
    public static let shared = TokenTracker()

    @Published public var currentUsage = ConversationTokenUsage()
    @Published public var dailyUsage = DailyTokenUsage()
    @Published public var currentModelName: String = "Gemini 3.8 Flash"
    @Published public var lastUpdated: Date = Date()
    @Published public var isRefreshing: Bool = false

    private var refreshQueue = DispatchQueue(label: "com.dave.tokentracker", qos: .userInitiated)

    private init() {
        refresh()
    }

    public static func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    public static func formatNumberWithCommas(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    public func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        refreshQueue.async { [weak self] in
            guard let self = self else { return }
            let home = NSHomeDirectory()
            let brainDir = "\(home)/.gemini/antigravity/brain"
            let fm = FileManager.default

            let targetCid = AntigravityBridge.shared.conversationId
            var currentStats = ConversationTokenUsage()
            currentStats.conversationId = targetCid
            currentStats.title = AntigravityBridge.shared.currentTask

            var modelFound = "Gemini 3.8 Flash"

            // 1. Calculate tokens for the current active conversation
            if !targetCid.isEmpty {
                let transcriptPath = "\(brainDir)/\(targetCid)/.system_generated/logs/transcript.jsonl"
                if let data = try? Data(contentsOf: URL(fileURLWithPath: transcriptPath)),
                   let str = String(data: data, encoding: .utf8) {
                    for line in str.split(separator: "\n") {
                        if line.contains("Model Selection") {
                            if let match = self.extractModelName(from: String(line)) {
                                modelFound = match
                            }
                        }
                        if line.contains("input_tokens") {
                            if let lineData = line.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                               json["type"] as? String == "PLANNER_RESPONSE" {
                                currentStats.stepCount += 1
                                currentStats.inputTokens += json["input_tokens"] as? Int ?? 0
                                currentStats.outputTokens += json["output_tokens"] as? Int ?? 0
                                currentStats.cacheReadTokens += json["cache_read_tokens"] as? Int ?? 0
                            }
                        }
                    }
                }
            }

            // 2. Calculate daily cumulative tokens (past 24 hours across all conversations)
            var daily = DailyTokenUsage()
            let dayAgo = Date().addingTimeInterval(-86400)

            if let convDirs = try? fm.contentsOfDirectory(atPath: brainDir) {
                for dir in convDirs {
                    let tPath = "\(brainDir)/\(dir)/.system_generated/logs/transcript.jsonl"
                    guard let attrs = try? fm.attributesOfItem(atPath: tPath),
                          let modDate = attrs[.modificationDate] as? Date,
                          modDate >= dayAgo else {
                        continue
                    }

                    daily.activeConversationsCount += 1

                    if let data = try? Data(contentsOf: URL(fileURLWithPath: tPath)),
                       let str = String(data: data, encoding: .utf8) {
                        for line in str.split(separator: "\n") {
                            if line.contains("input_tokens") {
                                if let lineData = line.data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                                   json["type"] as? String == "PLANNER_RESPONSE" {
                                    daily.inputTokens += json["input_tokens"] as? Int ?? 0
                                    daily.outputTokens += json["output_tokens"] as? Int ?? 0
                                    daily.cacheReadTokens += json["cache_read_tokens"] as? Int ?? 0
                                }
                            }
                        }
                    }
                }
            }
            daily.totalTokens = daily.inputTokens + daily.outputTokens

            DispatchQueue.main.async {
                self.currentUsage = currentStats
                self.dailyUsage = daily
                self.currentModelName = modelFound
                self.lastUpdated = Date()
                self.isRefreshing = false
            }
        }
    }

    private func extractModelName(from text: String) -> String? {
        if let range = text.range(of: "Model Selection` from None to ") {
            let sub = text[range.upperBound...]
            if let paren = sub.firstIndex(of: "(") {
                return String(sub[..<paren]).trimmingCharacters(in: .whitespaces)
            } else if let end = sub.firstIndex(of: "\n") {
                return String(sub[..<end]).trimmingCharacters(in: CharacterSet(charactersIn: ". \r\t"))
            } else {
                return String(sub).trimmingCharacters(in: CharacterSet(charactersIn: ". \r\t\n"))
            }
        }
        return nil
    }
}
