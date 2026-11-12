import Foundation

public enum PetState: String, CaseIterable, Identifiable {
    case idle
    case coding
    case debugging
    case coffee
    case sleeping
    case dragged
    case running
    case carrying
    case throwing
    case celebrating

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .idle: return "摸鱼待机"
        case .coding: return "疯狂码字"
        case .debugging: return "抓虫思考"
        case .coffee: return "品味咖啡"
        case .sleeping: return "午休小憩"
        case .dragged: return "被抓走了"
        case .running: return "全力飞奔"
        case .carrying: return "抱起文件"
        case .throwing: return "暴扣垃圾桶"
        case .celebrating: return "庆祝搞定"
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
        case .running: return "figure.run"
        case .carrying: return "doc.fill"
        case .throwing: return "trash.fill"
        case .celebrating: return "party.popper.fill"
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
        case .coding: return 0.15
        case .running: return 0.12     // Fast running stride
        case .carrying: return 0.14    // Fast carrying sprint
        case .throwing: return 0.18    // Slam dunk timing
        case .celebrating: return 0.25 // Victory jump
        case .dragged: return 0.18
        case .debugging: return 0.45
        case .coffee: return 0.35
        case .sleeping: return 0.55
        case .idle: return 0.4
        }
    }
}
