import Combine
import CoreBluetooth
import Foundation
import UIKit

struct NearbyDevice: Identifiable, Equatable {
    let id: UUID
    var rawRSSI: Int
    var smoothedRSSI: Double
    var lastSeen: Date
    var serviceCount: Int

    var shortID: String { String(id.uuidString.prefix(8)) }
    var anonymousLabel: String { "Signal \(String(shortID.suffix(4)))" }

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

final class BluetoothScanner: NSObject, ObservableObject {
    @Published private(set) var devices: [NearbyDevice] = []
    @Published private(set) var availability: BluetoothAvailability = .starting
    @Published private(set) var isScanning = false
    @Published private(set) var selectedDevice: NearbyDevice?
    @Published private(set) var assessment: SignalAssessment?
    @Published private(set) var selectedHistory: [SignalSample] = []

    private var central: CBCentralManager?
    private var records: [UUID: NearbyDevice] = [:]
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var analyzers: [UUID: SignalTrendAnalyzer] = [:]
    private var lastGuidance: SearchGuidance?
    private var cleanupTimer: Timer?

    override init() {
        super.init()
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SignalScoutScreenshotMode") {
            availability = .ready
            isScanning = true
            seedScreenshotSignals()
            if ProcessInfo.processInfo.arguments.contains("-SignalScoutTrackingScreenshotMode") {
                seedScreenshotTracking()
            }
            return
        }
#endif
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshAges()
        }
    }

    deinit {
        central?.stopScan()
        cleanupTimer?.invalidate()
    }

    func startScanning() {
        guard let central, central.state == .poweredOn else { return }
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
    }

    func stopScanning() {
        central?.stopScan()
        isScanning = false
    }

    func clearInactiveDevices() {
        guard selectedDevice == nil else { return }
        let cutoff = Date().addingTimeInterval(-12)
        records = records.filter { $0.value.lastSeen >= cutoff }
        peripherals = peripherals.filter { records[$0.key] != nil }
        publishDevices()
    }

    func select(_ device: NearbyDevice) {
        var analyzer = SignalTrendAnalyzer()
        analyzer.reset()
        analyzers[device.id] = analyzer
        selectedDevice = records[device.id] ?? device
        assessment = nil
        selectedHistory = []
        lastGuidance = nil
        if !isScanning { startScanning() }
    }

    func resetDirection() {
        guard let id = selectedDevice?.id else { return }
        var analyzer = SignalTrendAnalyzer()
        analyzer.reset()
        analyzers[id] = analyzer
        assessment = nil
        selectedHistory = []
        lastGuidance = nil
    }

    func stopTracking() {
        selectedDevice = nil
        assessment = nil
        selectedHistory = []
        lastGuidance = nil
    }

    func isStale(_ device: NearbyDevice, now: Date = Date()) -> Bool {
        now.timeIntervalSince(device.lastSeen) > 5
    }

    private func refreshAges() {
        if let selectedDevice,
           let latest = records[selectedDevice.id] {
            self.selectedDevice = latest
            if isStale(latest) {
                let current = assessment?.smoothedRSSI ?? latest.smoothedRSSI
                assessment = SignalAssessment(
                    smoothedRSSI: current,
                    guidance: .signalLost,
                    trendDB: 0,
                    confidence: 0,
                    sampleCount: assessment?.sampleCount ?? 0
                )
            }
        }
        publishDevices()
    }

    private func publishDevices() {
        devices = records.values.sorted {
            if abs($0.smoothedRSSI - $1.smoothedRSSI) > 1 {
                return $0.smoothedRSSI > $1.smoothedRSSI
            }
            return $0.shortID < $1.shortID
        }
    }

    private func provideFeedback(for guidance: SearchGuidance) {
        guard guidance != lastGuidance else { return }
        defer { lastGuidance = guidance }
        switch guidance {
        case .warmer:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .colder:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        default:
            break
        }
    }

#if DEBUG
    private func seedScreenshotSignals() {
        let examples: [(String, Int)] = [
            ("0001C551-0000-0000-0000-000000000001", -45),
            ("0003565B-0000-0000-0000-000000000002", -58),
            ("0004BCF6-0000-0000-0000-000000000003", -69),
            ("000638F6-0000-0000-0000-000000000004", -77),
            ("0007E01E-0000-0000-0000-000000000005", -86),
            ("00096051-0000-0000-0000-000000000006", -94)
        ]
        let now = Date()
        for (uuidString, rssi) in examples {
            guard let id = UUID(uuidString: uuidString) else { continue }
            records[id] = NearbyDevice(
                id: id,
                rawRSSI: rssi,
                smoothedRSSI: Double(rssi),
                lastSeen: now,
                serviceCount: 1
            )
        }
        publishDevices()
    }

    private func seedScreenshotTracking() {
        guard let target = devices.first else { return }
        selectedDevice = target
        let values = [-67, -66, -65, -63, -61, -59, -56, -53, -49, -45]
        let start = Date().timeIntervalSinceReferenceDate - Double(values.count)
        selectedHistory = values.enumerated().map { index, rssi in
            SignalSample(time: start + Double(index), rawRSSI: rssi, smoothedRSSI: Double(rssi))
        }
        assessment = SignalAssessment(
            smoothedRSSI: target.smoothedRSSI,
            guidance: .warmer,
            trendDB: 8.4,
            confidence: 0.94,
            sampleCount: values.count
        )
    }
#endif
}

extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            availability = .ready
            startScanning()
        case .poweredOff:
            availability = .poweredOff
            isScanning = false
        case .unauthorized:
            availability = .unauthorized
            isScanning = false
        case .unsupported:
            availability = .unsupported
            isScanning = false
        case .resetting:
            availability = .resetting
            isScanning = false
        case .unknown:
            availability = .starting
            isScanning = false
        @unknown default:
            availability = .starting
            isScanning = false
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rawRSSI = RSSI.intValue
        guard (-110 ... -15).contains(rawRSSI) else { return }

        let id = peripheral.identifier
        let now = Date()
        peripherals[id] = peripheral

        var backgroundAnalyzer = analyzers[id] ?? SignalTrendAnalyzer()
        let update = backgroundAnalyzer.add(rawRSSI: rawRSSI, at: now.timeIntervalSinceReferenceDate)
        analyzers[id] = backgroundAnalyzer

        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.count ?? 0
        let smoothed = update?.smoothedRSSI ?? Double(rawRSSI)
        records[id] = NearbyDevice(
            id: id,
            rawRSSI: rawRSSI,
            smoothedRSSI: smoothed,
            lastSeen: now,
            serviceCount: services
        )
        publishDevices()

        guard selectedDevice?.id == id else { return }
        selectedDevice = records[id]
        assessment = update
        selectedHistory = Array(backgroundAnalyzer.samples.suffix(36))
        if let guidance = update?.guidance {
            provideFeedback(for: guidance)
        }
    }
}
