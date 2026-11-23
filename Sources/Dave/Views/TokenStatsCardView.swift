import SwiftUI
import AppKit

public struct TokenStatsCardView: View {
    @ObservedObject var tracker = TokenTracker.shared
    @ObservedObject var bridge = AntigravityBridge.shared

    @State private var rotationDegrees: Double = 0
    @State private var isSpinning: Bool = false
    @State private var isHovering: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Title & Antigravity Status
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)

                Text("Token 消耗统计")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(bridge.isBusy ? Color.orange : Color.green)
                        .frame(width: 6, height: 6)
                    Text(bridge.isBusy ? "工作中" : "空闲")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(bridge.isBusy ? .orange : .green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill((bridge.isBusy ? Color.orange : Color.green).opacity(0.12))
                )
            }

            Divider()
                .opacity(0.5)

            // Section 1: Current Conversation / Active Task
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("当前会话")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if tracker.currentUsage.stepCount > 0 {
                        Text("\(tracker.currentUsage.stepCount) 步调用")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                // 2x2 Metric Grid
                HStack(spacing: 6) {
                    metricBox(
                        title: "输入 (Prompt)",
                        value: TokenTracker.formatTokens(tracker.currentUsage.inputTokens),
                        fullNumber: TokenTracker.formatNumberWithCommas(tracker.currentUsage.inputTokens),
                        icon: "arrow.down.circle.fill",
                        color: .blue
                    )

                    metricBox(
                        title: "输出 (Output)",
                        value: TokenTracker.formatTokens(tracker.currentUsage.outputTokens),
                        fullNumber: TokenTracker.formatNumberWithCommas(tracker.currentUsage.outputTokens),
                        icon: "arrow.up.circle.fill",
                        color: .purple
                    )
                }

                HStack(spacing: 6) {
                    metricBox(
                        title: "缓存命中 (Cache)",
                        value: TokenTracker.formatTokens(tracker.currentUsage.cacheReadTokens),
                        fullNumber: TokenTracker.formatNumberWithCommas(tracker.currentUsage.cacheReadTokens),
                        icon: "sparkles",
                        color: .green
                    )

                    metricBox(
                        title: "会话总计 (Total)",
                        value: TokenTracker.formatTokens(tracker.currentUsage.totalTokens),
                        fullNumber: TokenTracker.formatNumberWithCommas(tracker.currentUsage.totalTokens),
                        icon: "sum",
                        color: .orange
                    )
                }
            }

            Divider()
                .opacity(0.5)

            // Section 2: Daily (24h) Cumulative Summary
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("今日累计消耗 (24h)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tracker.dailyUsage.activeConversationsCount) 个会话")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("总消耗")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(TokenTracker.formatTokens(tracker.dailyUsage.totalTokens))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("输入/输出")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text("\(TokenTracker.formatTokens(tracker.dailyUsage.inputTokens)) / \(TokenTracker.formatTokens(tracker.dailyUsage.outputTokens))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("缓存节省")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(TokenTracker.formatTokens(tracker.dailyUsage.cacheReadTokens))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.04))
                )
            }

            // Footer: Model Name & Natural Refresh Button
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                    Text(tracker.currentModelName)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    guard !isSpinning else { return }
                    isSpinning = true
                    tracker.refresh()

                    withAnimation(.easeInOut(duration: 0.65)) {
                        rotationDegrees += 360
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        isSpinning = false
                    }
                } label: {
                    HStack(spacing: 3.5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .semibold))
                            .rotationEffect(.degrees(rotationDegrees))

                        Text(isSpinning ? "更新中" : "刷新")
                            .font(.system(size: 9.5, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(isHovering ? 0.15 : 0.08))
                    )
                }
                .buttonStyle(.plain)
                .onHover { h in
                    isHovering = h
                }
            }
            .padding(.top, 2)
        }
        .padding(10)
        .frame(width: 275)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func metricBox(title: String, value: String, fullNumber: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .help(fullNumber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(color.opacity(0.18), lineWidth: 0.8)
                )
        )
    }
}
