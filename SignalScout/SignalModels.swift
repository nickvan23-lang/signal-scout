import Foundation

struct NearbyDevice: Identifiable, Equatable {
    let id: UUID
    var rawRSSI: Int
    var smoothedRSSI: Double
    var lastSeen: Date
    var serviceCount: Int
    var identity = DeviceIdentity()

    var shortID: String { String(id.uuidString.prefix(8)) }
    var displayName: String { identity.name ?? "Unnamed device · \(String(shortID.suffix(4)))" }
    var manufacturerName: String {
        identity.companyID.map { BluetoothCompanyRegistry.name(for: $0) } ?? "Manufacturer not advertised"
    }

    // A strict ordering avoids cycles when three readings are within one dBm.
    static func strongestFirst(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.smoothedRSSI != rhs.smoothedRSSI {
            return lhs.smoothedRSSI > rhs.smoothedRSSI
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    var strengthLabel: String {
        if smoothedRSSI >= -50 { return "Very strong" }
        if smoothedRSSI >= -62 { return "Strong" }
        if smoothedRSSI >= -74 { return "Medium" }
        if smoothedRSSI >= -86 { return "Weak" }
        return "Very weak"
    }
}

enum BluetoothAvailability: Equatable {
    case starting
    case ready
    case poweredOff
    case unauthorized
    case unsupported
    case resetting

    var message: String {
        switch self {
        case .starting: return "Starting Bluetooth…"
        case .ready: return "Bluetooth is ready"
        case .poweredOff: return "Turn on Bluetooth to scan"
        case .unauthorized: return "Allow Bluetooth in Settings to scan"
        case .unsupported: return "Bluetooth LE is not supported on this device"
        case .resetting: return "Bluetooth is resetting…"
        }
    }
}

