import AppKit
import Foundation
import SwiftUI

public final class TrashDutyService: ObservableObject {
    public static let shared = TrashDutyService()

    @Published public var isBusy: Bool = false
    private var moveTimer: Timer?
    private var cachedTrashLocation: CGPoint?

    private init() {}

    /// Main entry point: Performs the full "Run to file -> Pick up -> Run to Dock -> Dunk into Trash -> Celebrate -> Return" sequence
    public func performTrashMission(from sourcePoint: CGPoint? = nil, filename: String? = nil) {
        guard !isBusy else { return }
        guard let window = PetManager.shared.window else { return }

        isBusy = true
        let homeOrigin = window.frame.origin
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!

        // Determine source point (where the file is)
        let fileLocation: CGPoint
        if let pt = sourcePoint, pt != .zero {
            fileLocation = pt
        } else {
            // Default to mouse position or a point on desktop
            let mouse = NSEvent.mouseLocation
            if mouse != .zero {
                fileLocation = mouse
            } else {
                fileLocation = CGPoint(x: screen.visibleFrame.midX - 100, y: screen.visibleFrame.midY + 100)
            }
        }

        // 1. Target beside the file
        let pickupTarget = CGPoint(
            x: max(screen.visibleFrame.minX, min(screen.visibleFrame.maxX - window.frame.width, fileLocation.x - (window.frame.width / 2))),
            y: max(screen.visibleFrame.minY, min(screen.visibleFrame.maxY - window.frame.height, fileLocation.y - 40))
        )

        // Step 1: Sprint to the file!
        PetManager.shared.isFacingLeft = (pickupTarget.x < window.frame.origin.x)
        PetManager.shared.setState(.running)
        if let name = filename {
            PetManager.shared.speak("发现待删文件「\(name)」！看我飞奔过去！🏃‍♂️💨", duration: 3.0)
        } else {
            PetManager.shared.speak("发现目标文件！看我飞奔过去！🏃‍♂️💨", duration: 3.0)
        }
        SoundManager.shared.playPop()

        smoothMove(window: window, from: window.frame.origin, to: pickupTarget, speed: 580) { [weak self] in
            guard let self = self else { return }

            // Step 2: Pick up the file!
            PetManager.shared.setState(.carrying)
            SoundManager.shared.playPop()
            PetManager.shared.speak("抱紧文件！准备送往废纸篓！📦", duration: 3.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else { return }
                // Step 3: Run to Dock Trash!
                let trashCenter = self.resolveDockTrashLocation(screen: screen)
                let dockTrashTarget = CGPoint(
                    x: max(screen.visibleFrame.minX, min(screen.visibleFrame.maxX - window.frame.width, trashCenter.x - (window.frame.width / 2))),
                    y: max(screen.frame.minY, trashCenter.y + 15)
                )

                PetManager.shared.isFacingLeft = (dockTrashTarget.x < window.frame.origin.x)
                PetManager.shared.speak("护送垃圾文件奔向 Dock 栏！🚨", duration: 3.0)

                self.smoothMove(window: window, from: window.frame.origin, to: dockTrashTarget, speed: 480) { [weak self] in
                    guard let self = self else { return }

                    // Step 4: Throw into Trash! (Slam Dunk)
                    PetManager.shared.setState(.throwing)
                    SoundManager.shared.playDrop()
                    PetManager.shared.speak("空心三分！暴扣废纸篓！🏀🗑️", duration: 2.5)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        guard let self = self else { return }
                        // Step 5: Celebrate victory!
                        PetManager.shared.setState(.celebrating)
                        SoundManager.shared.playHero()
                        if let name = filename {
                            PetManager.shared.speak("「\(name)」已消灭！干净利落！🧹✨", duration: 3.5)
                        } else {
                            PetManager.shared.speak("文件已成功扔进废纸篓！一身轻松！🎉✨", duration: 3.5)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                            guard let self = self else { return }
                            // Step 6: Run back home
                            PetManager.shared.isFacingLeft = (homeOrigin.x < window.frame.origin.x)
                            PetManager.shared.setState(.running)

                            self.smoothMove(window: window, from: window.frame.origin, to: homeOrigin, speed: 500) { [weak self] in
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

                    // Convert from Carbon screen coordinates (top-left) to AppKit (bottom-left)
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

    /// Smoothly translates the window at a given speed in points per second using a high-precision timer
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

            // Smooth cubic ease-in-out
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
    }
}
