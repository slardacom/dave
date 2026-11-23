import SwiftUI

public enum SpeechBubbleStyle: Equatable {
    case normal
    case success
    case failure

    public var strokeColor: Color {
        switch self {
        case .normal:
            return Color.blue.opacity(0.38)
        case .success:
            return Color(red: 0.18, green: 0.78, blue: 0.42).opacity(0.92)
        case .failure:
            return Color(red: 0.95, green: 0.30, blue: 0.30).opacity(0.92)
        }
    }

    public var strokeWidth: CGFloat {
        switch self {
        case .normal: return 1.5
        case .success, .failure: return 1.8
        }
    }

    public var tintColor: Color? {
        switch self {
        case .normal:
            return nil
        case .success:
            return Color.green.opacity(0.12)
        case .failure:
            return Color.red.opacity(0.10)
        }
    }

    public var shadowColor: Color {
        switch self {
        case .normal:
            return Color.black.opacity(0.08)
        case .success:
            return Color.green.opacity(0.35)
        case .failure:
            return Color.red.opacity(0.35)
        }
    }

    public var shadowRadius: CGFloat {
        switch self {
        case .normal: return 4
        case .success, .failure: return 7
        }
    }

    public var iconName: String? {
        switch self {
        case .normal: return nil
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    public var iconColor: Color {
        switch self {
        case .normal: return .clear
        case .success: return Color(red: 0.16, green: 0.75, blue: 0.38)
        case .failure: return Color(red: 0.92, green: 0.28, blue: 0.28)
        }
    }
}

public struct SpeechBubbleView: View {
    let text: String
    var style: SpeechBubbleStyle = .normal
    var onDismiss: (() -> Void)?

    public var body: some View {
        HStack(spacing: 6) {
            if let icon = style.iconName {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(style.iconColor)
            }
            Text(text)
                .font(.system(size: 12, weight: style == .normal ? .medium : .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(minWidth: 44)
        .animation(.easeInOut(duration: 0.2), value: text)
        .background(
            SpeechBubbleShape()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .overlay(
                    Group {
                        if let tint = style.tintColor {
                            SpeechBubbleShape()
                                .fill(tint)
                        }
                    }
                )
                .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 2)
                .overlay(
                    SpeechBubbleShape()
                        .stroke(
                            style.strokeColor,
                            style: StrokeStyle(lineWidth: style.strokeWidth, lineCap: .round, lineJoin: .round)
                        )
                )
        )
        .contentShape(SpeechBubbleShape())
        .onTapGesture {
            onDismiss?()
        }
    }
}

public struct SpeechBubbleShape: Shape {
    public var cornerRadius: CGFloat = 12
    public var pointerWidth: CGFloat = 12
    public var pointerHeight: CGFloat = 6

    public init(cornerRadius: CGFloat = 12, pointerWidth: CGFloat = 12, pointerHeight: CGFloat = 6) {
        self.cornerRadius = cornerRadius
        self.pointerWidth = pointerWidth
        self.pointerHeight = pointerHeight
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let bubbleRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: max(0, rect.height - pointerHeight)
        )

        let safePointerWidth = min(pointerWidth, max(0, bubbleRect.width - 2 * r))
        let pointerLeft = bubbleRect.midX - safePointerWidth / 2
        let pointerRight = bubbleRect.midX + safePointerWidth / 2
        let pointerTip = CGPoint(x: bubbleRect.midX, y: rect.maxY)

        path.move(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY))
        // Top-right corner
        path.addArc(
            center: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY + r),
            radius: r,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        // Right edge
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - r))
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.maxY - r),
            radius: r,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        // Bottom edge to pointer right
        path.addLine(to: CGPoint(x: pointerRight, y: bubbleRect.maxY))
        // Pointer down to tip
        path.addLine(to: pointerTip)
        // Pointer up to pointer left
        path.addLine(to: CGPoint(x: pointerLeft, y: bubbleRect.maxY))
        // Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY))
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY - r),
            radius: r,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        // Left edge
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + r))
        // Top-left corner
        path.addArc(
            center: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY + r),
            radius: r,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
