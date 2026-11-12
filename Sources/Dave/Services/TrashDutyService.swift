import AppKit
import Foundation
import SwiftUI

public final class TrashDutyService: ObservableObject {
    public static let shared = TrashDutyService()

    @Published public var isBusy: Bool = false
    private var moveTimer: Timer?
    private var cachedTrashLocation: CGPoint?

    private init() {}

    /// Main Simulated Trash Mission:
    /// Spawns a visual replica so the file DOES NOT disappear on desktop,
    /// Dave runs to it, physically lifts it off the desktop, carries it across screen to Dock, and throws it in!
    public func performTrashMission(from sourcePoint: CGPoint? = nil, filename: String? = nil, fileIcon: NSImage? = nil) {
        guard !isBusy else { return }
        guard let window = PetManager.shared.window else { return }

        isBusy = true
        let homeOrigin = window.frame.origin
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!

        let name = filename ?? "代码草稿.swift"
        let icon = fileIcon ?? PetManager.resolveIcon(name: name)

        // Determine source point (where the file is on the screen)
        let fileLocation: CGPoint
        if let pt = sourcePoint, pt != .zero {
            fileLocation = pt
        } else {
            let mouse = NSEvent.mouseLocation
            if mouse != .zero {
                fileLocation = mouse
            } else {
                fileLocation = CGPoint(x: screen.visibleFrame.midX - 100, y: screen.visibleFrame.midY + 80)
            }
        }

        // 🌟 STEP 1: Immediately spawn the File Ghost Replica on the desktop!
        // To the user, the file DOES NOT disappear! It remains sitting right there!
        FileGhostWindow.shared.spawn(at: fileLocation, name: name, icon: icon)

        // Calculate Dave's standing target (beside the file)
        let pickupTarget = CGPoint(
            x: max(screen.visibleFrame.minX, min(screen.visibleFrame.maxX - window.frame.width, fileLocation.x - (window.frame.width / 2))),
            y: max(screen.visibleFrame.minY, min(screen.visibleFrame.maxY - window.frame.height, fileLocation.y - 30))
        )

        // Dave runs towards the file
        PetManager.shared.isFacingLeft = (pickupTarget.x < window.frame.origin.x)
        PetManager.shared.setState(.running)
        PetManager.shared.speak("发现待清理文件「\(name)」！看我飞奔过去！🏃‍♂️💨", duration: 3.0)
        SoundManager.shared.playPop()

        smoothMove(window: window, from: window.frame.origin, to: pickupTarget, speed: 600) { [weak self] in
            guard let self = self else { return }

            // 🌟 STEP 2: Dave arrives, bends down, and physically lifts the file!
            SoundManager.shared.playPop()
            PetManager.shared.speak("抱起「\(name)」！准备送往废纸篓！📦", duration: 3.0)

            // The ghost window lifts up into Dave's hands and transfers to Dave's sprite
            FileGhostWindow.shared.liftAndTransfer(to: fileLocation) { [weak self] in
                guard let self = self else { return }
                PetManager.shared.carriedFileIcon = icon
                PetManager.shared.carriedFileName = name
                PetManager.shared.setState(.carrying)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }

                    // 🌟 STEP 3: Dave runs to the Dock Trash holding the real file!
                    let trashCenter = self.resolveDockTrashLocation(screen: screen)
                    let dockTrashTarget = CGPoint(
                        x: max(screen.visibleFrame.minX, min(screen.visibleFrame.maxX - window.frame.width, trashCenter.x - (window.frame.width / 2))),
                        y: max(screen.frame.minY, trashCenter.y + 12)
                    )

                    PetManager.shared.isFacingLeft = (dockTrashTarget.x < window.frame.origin.x)
                    PetManager.shared.speak("护送文件奔向 Dock 栏废纸篓！🚨", duration: 3.0)

                    self.smoothMove(window: window, from: window.frame.origin, to: dockTrashTarget, speed: 480) { [weak self] in
                        guard let self = self else { return }

                        // 🌟 STEP 4: Slam Dunk into Trash!
                        PetManager.shared.setState(.throwing)
                        PetManager.shared.isThrowingFile = true
                        SoundManager.shared.playDrop()
                        PetManager.shared.speak("空心投掷！精准入桶！🏀🗑️", duration: 2.5)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            PetManager.shared.carriedFileIcon = nil
                            PetManager.shared.carriedFileName = nil
                            PetManager.shared.isThrowingFile = false

                            // 🌟 STEP 5: Celebrate victory!
                            PetManager.shared.setState(.celebrating)
                            SoundManager.shared.playHero()
                            PetManager.shared.speak("「\(name)」已安全送达！清理完毕！🧹✨", duration: 3.5)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                                guard let self = self else { return }

                                // 🌟 STEP 6: Run back home
                                PetManager.shared.isFacingLeft = (homeOrigin.x < window.frame.origin.x)
                                PetManager.shared.setState(.running)

                                self.smoothMove(window: window, from: window.frame.origin, to: homeOrigin, speed: 520) { [weak self] in
                                    PetManager.shared.setState(.idle)
                                    PetManager.shared.isFacingLeft = false
                                    self?.isBusy = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Real Physical Drag-and-Drop Trash Mission:
    /// When a user drags a file directly onto Dave, Dave holds it, runs to Dock,
    /// and physically deletes the file ONLY when Dave throws it into the trash!
    public func performPhysicalTrashMission(fileURL: URL, name: String, icon: NSImage, at point: CGPoint) {
        guard !isBusy else { return }
        guard let window = PetManager.shared.window else { return }

        isBusy = true
        let homeOrigin = window.frame.origin
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!

        // Dave immediately catches the file
        PetManager.shared.carriedFileIcon = icon
        PetManager.shared.carriedFileName = name
        PetManager.shared.setState(.carrying)
        SoundManager.shared.playPop()
        PetManager.shared.speak("接住「\(name)」啦！我来帮你扔掉！📦", duration: 3.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }

            let trashCenter = self.resolveDockTrashLocation(screen: screen)
            let dockTrashTarget = CGPoint(
                x: max(screen.visibleFrame.minX, min(screen.visibleFrame.maxX - window.frame.width, trashCenter.x - (window.frame.width / 2))),
                y: max(screen.frame.minY, trashCenter.y + 12)
            )

            PetManager.shared.isFacingLeft = (dockTrashTarget.x < window.frame.origin.x)

            self.smoothMove(window: window, from: window.frame.origin, to: dockTrashTarget, speed: 480) { [weak self] in
                guard let self = self else { return }

                // Throw into Trash!
                PetManager.shared.setState(.throwing)
                PetManager.shared.isThrowingFile = true
                SoundManager.shared.playDrop()

                // Physically move the real file to macOS Trash at this exact moment!
                try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    PetManager.shared.carriedFileIcon = nil
                    PetManager.shared.carriedFileName = nil
                    PetManager.shared.isThrowingFile = false

                    PetManager.shared.setState(.celebrating)
                    SoundManager.shared.playHero()
                    PetManager.shared.speak("「\(name)」已扔进废纸篓！任务完成！🎉✨", duration: 3.5)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                        guard let self = self else { return }

                        PetManager.shared.isFacingLeft = (homeOrigin.x < window.frame.origin.x)
                        PetManager.shared.setState(.running)

                        self.smoothMove(window: window, from: window.frame.origin, to: homeOrigin, speed: 520) { [weak self] in
                            PetManager.shared.setState(.idle)
                            PetManager.shared.isFacingLeft = false
                            self?.isBusy = false
                        }
                    }
                }
            }
        }
    }

    /// Queries macOS System Events for the Trash icon in Dock, with reliable geometric fallback
    public func resolveDockTrashLocation(screen: NSScreen) -> CGPoint {
        if let cached = cachedTrashLocation {
            return cached
        }

        let script = """
        tell application "System Events"
            tell process "Dock"
                set trashList to (UI elements of list 1 whose subrole is "AXTrashDockItem" or name is "Trash" or name is "废纸篓")
                if (count of trashList) > 0 then
                    set trashItem to item 1 of trashList
                    set {px, py} to position of trashItem
                    set {sx, sy} to size of trashItem
                    return "" & px & "," & py & "," & sx & "," & sy
                end if
            end tell
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if error == nil, let str = result.stringValue {
                let parts = str.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                if parts.count == 4 {
                    let px = parts[0]
                    let py = parts[1]
                    let sx = parts[2]
                    let sy = parts[3]

                    let centerCarbonX = px + (sx / 2)
                    let centerCarbonY = py + (sy / 2)
                    let appKitX = centerCarbonX
                    let appKitY = screen.frame.height - centerCarbonY

                    let pt = CGPoint(x: appKitX, y: appKitY)
                    self.cachedTrashLocation = pt
                    return pt
                }
            }
        }

        // Fallback: Default bottom-right Dock trash position
        let fallback = CGPoint(
            x: screen.visibleFrame.maxX - 60,
            y: screen.frame.minY + 36
        )
        return fallback
    }

    private func smoothMove(window: NSWindow, from start: CGPoint, to target: CGPoint, speed: CGFloat, completion: @escaping () -> Void) {
        moveTimer?.invalidate()

        let dx = target.x - start.x
        let dy = target.y - start.y
        let distance = hypot(dx, dy)
        guard distance > 5 else {
            window.setFrameOrigin(target)
            completion()
            return
        }

        let duration = max(0.3, Double(distance / speed))
        let fps = 60.0
        let totalSteps = max(1, Int(duration * fps))
        var currentStep = 0

        moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] t in
            currentStep += 1
            let progress = min(1.0, Double(currentStep) / Double(totalSteps))

            let ease = progress * progress * (3.0 - 2.0 * progress)
            let curX = start.x + dx * ease
            let curY = start.y + dy * ease

            window.setFrameOrigin(CGPoint(x: curX, y: curY))

            if currentStep >= totalSteps {
                t.invalidate()
                self?.moveTimer = nil
                window.setFrameOrigin(target)
                completion()
            }
        }
    }

    public func cancel() {
        moveTimer?.invalidate()
        moveTimer = nil
        isBusy = false
        FileGhostWindow.shared.hide()
    }
}
