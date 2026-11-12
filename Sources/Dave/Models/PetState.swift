import Foundation

public enum PetState: String, CaseIterable, Identifiable {
    case idle
    case coding
    case debugging
    case coffee
    case sleeping
    case dragged

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .idle: return "摸鱼待机"
        case .coding: return "疯狂码字"
        case .debugging: return "抓虫思考"
        case .coffee: return "品味咖啡"
        case .sleeping: return "午休小憩"
        case .dragged: return "被抓走了"
        }
    }

    public var icon: String {
        switch self {
        case .idle: return "figure.stand"
        case .coding: return "keyboard"
        case .debugging: return "ant"
        case .coffee: return "cup.and.saucer.fill"
        case .sleeping: return "zzz"
        case .dragged: return "hand.draw"
        }
    }

    public var folderName: String {
        return rawValue
    }

    public var frameCount: Int {
        return 4
    }

    public var frameDuration: TimeInterval {
        switch self {
        case .coding: return 0.15      // Fast frantic typing
        case .dragged: return 0.18     // Fast leg kicking
        case .debugging: return 0.45   // Slow thoughtful pause
        case .coffee: return 0.35      // Relaxed sipping
        case .sleeping: return 0.55    // Slow peaceful breathing
        case .idle: return 0.4         // Normal breathing/blinking
        }
    }
}
