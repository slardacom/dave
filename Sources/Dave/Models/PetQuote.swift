import Foundation

public struct PetQuote {
    // MARK: - Time-Aware Greetings & Care (时间段感知)
    public static func timeAwareQuote() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())

        switch hour {
        case 7..<11:
            return [
                "早安！今天又是精力充沛的一天，先来拉个最新代码 🌅",
                "早上好！咖啡续命已到位，准备大干一场 ☕️✨",
                "新的一天，先看一眼昨晚生产环境稳不稳 ☀️",
                "清晨思维最清晰，先啃最硬的一块架构骨头！🧠",
                "晨会前先装作在全力敲代码... 🤫⌨️"
            ].randomElement()

        case 11..<14:
            if hour == 11 && minute < 30 {
                return [
                    "快到饭点了，今天中午去吃啥好呢？🍲",
                    "肚子开始抗议了，再写两行代码就去干饭 🍜"
                ].randomElement()
            } else {
                return [
                    "干饭人干饭魂！今天中午吃什么好呢？🍱",
                    "到饭点了！代码等会儿写，吃饱了才有力气捉虫 🍜",
                    "干饭要积极，编程思路才清晰！走走走觅食去 🥢",
                    "中午不睡，下午崩溃... 吃完饭准备小眯一会儿 😴",
                    "给大脑补充能量中，碳水是第一生产力 🍚"
                ].randomElement()
            }

        case 14..<17:
            return [
                "三点几嘞，饮茶先啦！来杯奶茶/冰美式提提神 🧋",
                "下午三四点，灵魂与肉体开始在工位上游离... 🫠",
                "咖啡因代谢完毕，亟需注入第二杯深烘焙 ☕️🔋",
                "下午写代码容易犯困，起来活动活动接杯水吧 🚶‍♂️💧",
                "点杯下午茶犒劳一下辛苦搬砖的自己 🍰",
                "伸个懒腰，看看窗外的绿色，保护视力 🌿"
            ].randomElement()

        case 17..<21:
            return [
                "下班时间到！拒绝无效内卷，准点打卡撤退 🏃‍♂️💨",
                "天色已晚，今天的工作就到这里啦，下班快乐！🌇",
                "代码千千万，下班第一条！今天你准点了吗？🍻",
                "今晚绝对不推代码到生产环境，安心下班 🏠",
                "下班啦！快合上电脑，生活比代码更精彩 ✨",
                "收拾书包，准备撤退，明天的 Bug 明天再修 🎒"
            ].randomElement()

        case 21..<24, 0..<7:
            return [
                "夜深了，注意发际线呀！早点休息明天再战 🌙",
                "凌晨还在敲代码？！身体是第一本钱，快去睡觉啦 🛌",
                "夜猫子工程师出没... 记得多喝热水，别熬太晚 🍵",
                "深夜修 Bug，越修越多！睡一觉明天灵感自来 💡",
                "星星都睡了，你的代码也该休息啦 💤",
                "屏幕蓝光太伤眼了，赶紧存盘睡觉，听话 😴"
            ].randomElement()

        default:
            return nil
        }
    }

    // MARK: - Comprehensive Quotes Library (通用自言自语 + AI热梗 + 程序员日常)
    public static let quotes: [String] = [
        // --- 经典程序员梗 ---
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
        "Keep calm and restart the service 🔄",
        "node_modules 已经比黑洞还要沉重了... 🕳️",
        "代码千万行，注释第一行；命名不规范，重构两行泪 🥹",
        "删除了 300 行祖传无用代码，心情舒畅！🧹✨",
        "又在用 Print 调试大法，简单粗暴但管用 🖨️",
        "不要动那段代码！虽然不知道它为什么能跑，但它就是能跑 🕯️",
        "Git rebase 突发冲突，汗流浃背了老弟 💦",
        "写代码 5 分钟，配环境两小时 ⏳",
        "删库跑路是玩笑，优雅下班才是真本事 🏃‍♂️",
        "世界上只有两件事最难：缓存失效与变量命名 📚",
        "只要我不提交代码，Bug 就永远追不上我 💨",
        "这个需求很明确，只有三句话，但要改半年 📈",
        "代码审查中：LGTM (Looks Good To Me) 迅速通过！👍",
        "Docker 容器起飞了，我的电脑风扇也跟着起飞 🐳💨",
        "真正的大师，永远怀着一颗重启服务的心 🧘‍♂️",
        "重构一时爽，联调火葬场 🚒",
        "先上线再修复，敏捷开发的精髓就在于敏捷 ⚡️",
        "键盘轴体越脆，写出的 Bug 越脆生生 ⌨️💥",
        "产品经理又带着‘简单的改动’走过来了... 快装作在沉思 🫣",

        // --- AI 时代热梗 ---
        "只要 Prompt 写得好，下班走得早 ✨",
        "AI 负责写代码，我负责喝咖啡 Review，这叫架构师风范 ☕️",
        "今天也是一名优秀的‘AI 驯兽师’ 🦁",
        "代码有 Bug？肯定是模型上下文被挤爆了 🧠💥",
        "别慌，再点一次‘重新生成’就玄学修好了 🪄",
        "Vibe Coding 中，不要打断我的心流节奏 🎧⚡️",
        "Prompt 工程学：从‘帮我写个网站’到‘作为资深全栈...’ 🧙‍♂️",
        "模型出现了微小的幻觉，但我用坚定的信念把它变成了新功能 🔮",
        "代码写得太快，Token 烧得比显卡还烫 🔥",
        "我和 AI 谁更懂这段代码？答：谁也不懂，但它能跑 🤖",
        "给 AI 的 Prompt 里加了句‘请务必仔细检查’，Bug 率立减 50% 🤫",
        "从零手写代码？时代变了大人，现在讲究的是人机协同 🏎️",
        "Token 是有限的，但天马行空的需（p）求（o）是无限的 💸",
        "上下文窗口就像打工人的记忆，聊着聊着就把前面的忘了 🪟",
        "AI 代写代码一时爽，一直代写一直爽 🚀✨",
        "只要需求描述得够抽象，AI 的发挥就够惊艳 🎨"
    ]

    public static func random() -> String {
        // 35% 几率优先触发当前时间段相关的感知对话
        if Double.random(in: 0...1) < 0.35, let timeQuote = timeAwareQuote() {
            return timeQuote
        }
        return quotes.randomElement() ?? "Hello, Dave is here! 🚀"
    }

    public static func quote(for state: PetState) -> String {
        switch state {
        case .coding:
            return [
                "正在高速输出无 Bug 代码！⌨️",
                "键盘冒烟中... 别打扰我的心流！🔥",
                "10x 工程师模式已启动 🚀",
                "代码如流水，正在疯狂码字中 💻⚡️",
                "指尖起舞，又一个需求搞定在即 💃"
            ].randomElement()!
        case .debugging:
            return [
                "奇了怪了，刚才明明还能跑的... 🐛",
                "二分法排查中，到底是哪一行的问题？🔍",
                "加个 print 调试大法好！🖨️",
                "正在逐行捉虫，真相只有一个！🕵️‍♂️",
                "深呼吸，Bug 只是迷路了的小特性 🔍"
            ].randomElement()!
        case .coffee:
            return [
                "程序员 = 把咖啡转化成代码的机器 ☕️",
                "这口深烘焙，注入了灵魂 ✨",
                "咖啡因浓度回升中... 🔋",
                "喝口咖啡，灵感爆棚 ☕️💡"
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
        case .running:
            return [
                "跑起来！风一样的工程师！💨",
                "稍等，马上就位！⚡️",
                "冲刺阶段，绝不掉链子！🏃‍♂️"
            ].randomElement()!
        case .sweating:
            return [
                "风扇起飞了！谁在写死循环？🔥💦",
                "好烫好烫！CPU 已经狂飙到 80%+ 了！🥵",
                "代码太火热了，给我来杯冰美式降降温！🧊",
                "散热口在咆哮，本工程师快要化了！💨"
            ].randomElement()!
        case .peeking:
            return [
                "我躲在屏幕边缘偷看你敲代码～👀",
                "偷偷观察...发现一个新特性！✨",
                "缩进边缘啦，把整个桌面留给你～💻",
                "鼠标滑过来我就探出头哦～^ ^"
            ].randomElement()!
        case .celebrating:
            return [
                "任务搞定！一身轻松！🎉",
                "完美通过！下班喝一杯！🍻",
                "Dave 出马，一个顶俩！🥳",
                "全部绿灯通过！这波稳如老狗！🏆",
                "需求完结，功德 +1！✨"
            ].randomElement()!
        case .idle:
            return random()
        }
    }
}
