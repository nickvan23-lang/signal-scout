import Foundation

struct TrackingStatus {
    let title: String
    let instruction: String
    let guidance: SearchGuidance
    let isLive: Bool

    init(availability: BluetoothAvailability, isScanning: Bool, lastSeen: Date?, assessment: SignalAssessment?, now: Date = Date()) {
        if availability != .ready {
            title = availability.message
            instruction = "The reading below is the last received value. Restore Bluetooth access to continue comparing signals."
            guidance = .signalLost
            isLive = false
        } else if !isScanning {
            title = "Scanning paused"
            instruction = "Resume scanning to receive new readings. The last value is shown below."
            guidance = .steady
            isLive = false
        } else if let lastSeen, now.timeIntervalSince(lastSeen) > 5 {
            title = "Signal lost"
            instruction = "No recent advertisement. Wake your accessory or return toward your last position; the signal may appear again."
            guidance = .signalLost
            isLive = false
        } else {
            guidance = assessment?.guidance ?? .calibrating
            title = guidance.title
            instruction = guidance.instruction
            isLive = true
        }
    }
}

extension NearbyDevice {
    func freshnessLabel(now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(lastSeen)))
        return seconds <= 5 ? "Updated just now" : "Last seen \(seconds)s ago"
    }
}
