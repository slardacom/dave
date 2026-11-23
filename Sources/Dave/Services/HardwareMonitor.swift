import AppKit
import Darwin
import Foundation
import IOKit.ps

public final class HardwareMonitor: ObservableObject {
    public static let shared = HardwareMonitor()

    @Published public var cpuUsage: Double = 0.0
    @Published public var isHighCPULoad: Bool = false
    @Published public var batteryPercentage: Int = 100
    @Published public var isPowerConnected: Bool = true
    @Published public var isCharging: Bool = false
    @Published public var isLowBattery: Bool = false

    private var monitorTimer: Timer?
    private var previousCPUTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?
    private var consecutiveHighCPUCount: Int = 0
    private var consecutiveNormalCPUCount: Int = 0
    private var previousPowerConnected: Bool = true
    private var hasAlertedLowBattery: Bool = false
    private var stateBeforeHighCPU: PetState = .idle
    private var isSimulatingHighCPU: Bool = false

    private init() {}

    public func startMonitoring() {
        stopMonitoring()

        // Initial battery & CPU tick sampling
        previousCPUTicks = getCPUTicks()
        sampleBattery()

        // Unified 2.5s hardware sampling loop (microsecond native Mach & IOKit query)
        let timer = Timer(timeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.sampleCPU()
            self?.sampleBattery()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.monitorTimer = timer
    }

    public func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    // MARK: - Native Mach CPU Sampling (Sub-millisecond overhead)

    public func sampleCPU() {
        if isSimulatingHighCPU { return }

        guard let current = getCPUTicks() else { return }

        if let previous = previousCPUTicks {
            let userDiff = Double(current.user - previous.user)
            let sysDiff = Double(current.system - previous.system)
            let niceDiff = Double(current.nice - previous.nice)
            let idleDiff = Double(current.idle - previous.idle)
            let total = userDiff + sysDiff + niceDiff + idleDiff

            if total > 0 {
                let usage = ((userDiff + sysDiff + niceDiff) / total) * 100.0
                DispatchQueue.main.async { [weak self] in
                    self?.handleNewCPUUsage(usage)
                }
            }
        }
        previousCPUTicks = current
    }

    private func handleNewCPUUsage(_ usage: Double) {
        self.cpuUsage = usage

        let highThreshold: Double = 75.0
        let normalThreshold: Double = 60.0

        if usage >= highThreshold {
            consecutiveHighCPUCount += 1
            consecutiveNormalCPUCount = 0

            // Require 2 consecutive high samples to avoid momentary spikes
            if consecutiveHighCPUCount >= 2 && !isHighCPULoad {
                isHighCPULoad = true
                triggerHighCPUState()
            }
        } else if usage < normalThreshold {
            consecutiveNormalCPUCount += 1
            consecutiveHighCPUCount = 0

            if consecutiveNormalCPUCount >= 2 && isHighCPULoad {
                isHighCPULoad = false
                recoverFromHighCPUState()
            }
        }
    }

    private func triggerHighCPUState() {
        guard PetManager.shared.currentState != .dragged else { return }

        stateBeforeHighCPU = PetManager.shared.currentState
        PetManager.shared.setState(.sweating)
        SoundManager.shared.playTink()
    }

    private func recoverFromHighCPUState() {
        guard PetManager.shared.currentState == .sweating else { return }

        let target = (stateBeforeHighCPU == .sweating) ? .idle : stateBeforeHighCPU
        PetManager.shared.setState(target, speech: "呼～CPU 终于降温了，活着真好！🍃", showQuote: false)
        SoundManager.shared.playDrop()
    }

    private func getCPUTicks() -> (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)? {
        var count: natural_t = 0
        var array: processor_info_array_t?
        var arrayCount: mach_msg_type_number_t = 0

        let res = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &array, &arrayCount)
        guard res == KERN_SUCCESS, let info = array else { return nil }

        var user: UInt64 = 0
        var sys: UInt64 = 0
        var idle: UInt64 = 0
        var nice: UInt64 = 0

        for i in 0..<Int(count) {
            let base = i * Int(CPU_STATE_MAX)
            user += UInt64(info[base + Int(CPU_STATE_USER)])
            sys += UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            idle += UInt64(info[base + Int(CPU_STATE_IDLE)])
            nice += UInt64(info[base + Int(CPU_STATE_NICE)])
        }

        let size = vm_size_t(arrayCount) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        return (user, sys, idle, nice)
    }

    // MARK: - Native IOKit Battery & Power Source

    public func sampleBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { continue }

            let powerState = desc[kIOPSPowerSourceStateKey] as? String ?? ""
            let isConnected = (powerState == (kIOPSACPowerValue as String))
            let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let currentCap = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCap = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let percent = maxCap > 0 ? Int((Double(currentCap) / Double(maxCap)) * 100.0) : 100

            DispatchQueue.main.async { [weak self] in
                self?.handleBatteryUpdate(percent: percent, isConnected: isConnected, isCharging: charging)
            }
            break
        }
    }

    private func handleBatteryUpdate(percent: Int, isConnected: Bool, isCharging: Bool) {
        self.batteryPercentage = percent
        self.isPowerConnected = isConnected
        self.isCharging = isCharging

        // 1. Detect plug-in event (MagSafe / USB-C charging)
        if !previousPowerConnected && isConnected {
            SoundManager.shared.playHero()
            PetManager.shared.triggerBounce()
            PetManager.shared.speak("⚡️ 充上电了！瞬间满血复活！🚀", duration: 4.5)
            hasAlertedLowBattery = false
        }

        // 2. Detect low battery state (< 20% and running on battery)
        if !isConnected && percent <= 20 {
            self.isLowBattery = true
            if !hasAlertedLowBattery {
                hasAlertedLowBattery = true
                SoundManager.shared.playPurr()
                PetManager.shared.speak("电量只剩 \(percent)% 啦！快帮我插上 MagSafe ⚡️🔋", duration: 5.5)
            }
        } else if isConnected || percent > 25 {
            self.isLowBattery = false
            hasAlertedLowBattery = false
        }

        self.previousPowerConnected = isConnected
    }

    // MARK: - Manual Testing Simulators

    /// Allows the user to simulate an intense CPU spike to preview the sweating animation and quote
    public func simulateHighCPU(duration: TimeInterval = 6.0) {
        isSimulatingHighCPU = true
        self.cpuUsage = 88.5
        self.isHighCPULoad = true
        triggerHighCPUState()

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.isSimulatingHighCPU = false
            self.sampleCPU()
            self.isHighCPULoad = false
            self.recoverFromHighCPUState()
        }
    }

    /// Simulates MagSafe plug-in recharge animation and sound
    public func simulatePlugIn() {
        previousPowerConnected = false
        handleBatteryUpdate(percent: self.batteryPercentage, isConnected: true, isCharging: true)
    }

    /// Simulates low battery warning
    public func simulateLowBattery() {
        previousPowerConnected = false
        handleBatteryUpdate(percent: 15, isConnected: false, isCharging: false)
    }
}
