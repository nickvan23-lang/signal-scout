import Foundation

struct SignalMapCoordinate: Equatable {
    let normalizedRadius: Double
    let angleRadians: Double
}

enum SignalMapLayout {
    private static let innerRadius = 0.16
    private static let outerRadius = 0.91
    private static let strongestRSSI = -35.0
    private static let weakestRSSI = -100.0

    static func coordinate(id: UUID, rssi: Double) -> SignalMapCoordinate {
        SignalMapCoordinate(
            normalizedRadius: normalizedRadius(for: rssi),
            angleRadians: stableAngle(for: id)
        )
    }

    static func normalizedRadius(for rssi: Double) -> Double {
        let clamped = min(strongestRSSI, max(weakestRSSI, rssi))
        let strengthFraction = (clamped - weakestRSSI) / (strongestRSSI - weakestRSSI)
        return outerRadius - strengthFraction * (outerRadius - innerRadius)
    }

    /// Preserve strength order while keeping selectable dots outside the phone marker.
    static func displayRadius(for rssi: Double, availableRadius: Double, centerClearance: Double) -> Double {
        let outer = max(0, availableRadius)
        let inner = min(outer, max(0, centerClearance))
        let fraction = (normalizedRadius(for: rssi) - innerRadius) / (outerRadius - innerRadius)
        return inner + fraction * (outer - inner)
    }

    static func stableAngle(for id: UUID) -> Double {
        // Swift's Hashable seed changes between launches. FNV-1a keeps each
        // visual angle deterministic without treating that angle as a bearing.
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in id.uuidString.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let fraction = Double(hash % 1_000_000) / 1_000_000
        return fraction * 2 * Double.pi
    }
}
