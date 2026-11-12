import AppKit
import SwiftUI
import UniformTypeIdentifiers

public final class FileGhostWindow: NSPanel {
    public static let shared = FileGhostWindow()

    private var hostingView: NSHostingView<FileGhostContentView>?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 110, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = true
        self.animationBehavior = .none
    }

    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }

    /// Spawns a visual replica of the file right at the file's physical screen coordinates
    public func spawn(at point: CGPoint, name: String, icon: NSImage) {
        let content = FileGhostContentView(name: name, icon: icon)
        let host = NSHostingView(rootView: content)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = host
        self.hostingView = host

        // Center on the given point
        let origin = CGPoint(x: point.x - 55, y: point.y - 55)
        self.setFrameOrigin(origin)
        self.alphaValue = 1.0
        self.orderFrontRegardless()
    }

    /// Performs the visual "lift into hands" animation, then hides the ghost window
    public func liftAndTransfer(to targetOrigin: CGPoint, completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrameOrigin(CGPoint(x: targetOrigin.x, y: targetOrigin.y + 25))
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1.0
            completion()
        })
    }

    public func hide() {
        self.orderOut(nil)
    }
}

public struct FileGhostContentView: View {
    let name: String
    let icon: NSImage

    public var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)

            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.45))
                )
                .shadow(color: Color.black.opacity(0.6), radius: 2, x: 0, y: 1)
        }
        .frame(width: 100, height: 100)
    }
}
