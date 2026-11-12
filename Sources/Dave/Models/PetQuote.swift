import Foundation

public struct PetQuote {
    public static let quotes: [String] = [
        "在我机器上运行得好好的！💻",
        "这不是 Bug，这叫未公开的特性 ✨",
        "咖啡注入完毕，Ready to Code! ☕️",
        "坐久了，记得站起来喝口水、伸个懒腰呀 💧",
        "周五下午绝不上生产环境 🛑",
        "代码如诗，但我写的是现代抽象派 📝",
        "谁写的烂代码？...哦，原来是我半年前写的 🙈",
        "没有一杯咖啡解决不了的 Bug，如果有，那就两杯 ☕️",
        "编译通过！今晚能准时下班吗？🎉",
        "正在全力构思：到底给这个变量起什么名字好 🤔",
        "别戳我啦，再戳要段错误 (Segmentation Fault) 了！😵",
        "Git Commit: 'Fix bugs and minor improvements' 😇",
        "先写 TODO，下个迭代一定做！(承诺脸) 📋",
        "遇到卡壳别硬撑，去洗手间走一圈灵感就来了 🚶",
        "Keep calm and restart the service 🔄"
    ]

    public static func random() -> String {
        return quotes.randomElement() ?? "Hello, Dave is here! 🚀"
    }

    public static func quote(for state: PetState) -> String {
        switch state {
        case .coding:
            return [
                "正在高速输出无 Bug 代码！⌨️",
                "键盘冒烟中... 别打扰我的心流！🔥",
                "10x 工程师模式已启动 🚀"
            ].randomElement()!
        case .debugging:
            return [
                "奇了怪了，刚才明明还能跑的... 🐛",
                "二分法排查中，到底是哪一行的问题？🔍",
                "加个 print 调试大法好！🖨️"
            ].randomElement()!
        case .coffee:
            return [
                "程序员 = 把咖啡转化成代码的机器 ☕️",
                "这口深烘焙，注入了灵魂 ✨",
                "咖啡因浓度回升中... 🔋"
            ].randomElement()!
        case .sleeping:
            return [
                "呼噜呼噜... 在梦里改 Bug 💤",
                "正在休眠节能中... Zzz",
                "充电完毕后再战江湖 🌙"
            ].randomElement()!
        case .dragged:
            return [
                "哇啊！轻点轻点，帽子要掉了！🪂",
                "救命，悬空了悬空了！😵‍💫",
                "你要把我放去哪个屏幕？👀"
            ].randomElement()!
        case .idle:
            return random()
        }
    }
}
