import SwiftUI

public struct SpeechBubbleView: View {
    let text: String
    var onDismiss: (() -> Void)?

    public var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    // Solid high-opacity background without blur shaders to prevent dragging ghosting
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
                        )
                )

            // Triangle pointer
            Triangle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .frame(width: 12, height: 6)
                .offset(y: -1)
        }
        .onTapGesture {
            onDismiss?()
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
