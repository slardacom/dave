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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )

            // Triangle pointer
            Triangle()
                .fill(.ultraThinMaterial)
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
