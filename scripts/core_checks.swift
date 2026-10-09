import Foundation
var passed = 0
func check(_ name: String, _ condition: @autoclosure () -> Bool) {
    guard condition() else { fatalError("FAIL: \(name)") }
    passed += 1
    print("PASS: \(name)")
}
let known = DeviceIdentity().merging(localName: " Studio headphones ", peripheralName: "Cached", manufacturerData: Data([0x4C, 0x00, 0xAA]))
check("advertised name wins", known.name == "Studio headphones")
check("little endian company ID", known.companyID == 76)
check("cached system name does not replace advertised name", known.merging(localName: nil, peripheralName: "Stale cached name", manufacturerData: nil).name == "Studio headphones")
check("sparse packet preserves details", known.merging(localName: nil, peripheralName: nil, manufacturerData: nil) == known)
check("iOS name fallback", DeviceIdentity().merging(localName: nil, peripheralName: "Desk speaker", manufacturerData: nil).name == "Desk speaker")
check("short manufacturer data rejected", DeviceIdentity.companyIdentifier(from: Data([0x4C])) == nil)
check("blank name rejected", DeviceIdentity.cleanedName(" \n\t") == nil)
check("Unicode name retained", DeviceIdentity.cleanedName("Café 🎧\nHeadphones") == "Café 🎧 Headphones")
check("registry bundled", BluetoothCompanyRegistry.names.count > 4000)
check("Apple resolves", BluetoothCompanyRegistry.name(for: 76).contains("Apple"))
check("Samsung resolves", BluetoothCompanyRegistry.name(for: 117).contains("Samsung"))
check("unknown ID remains explicit", BluetoothCompanyRegistry.name(for: 65534) == "Unknown manufacturer (0xFFFE)")
let now = Date(timeIntervalSince1970: 1000)
let assessment = SignalAssessment(smoothedRSSI: -50, guidance: .warmer, trendDB: 4, confidence: 1, sampleCount: 20)
check("paused overrides warmer", TrackingStatus(availability: .ready, isScanning: false, lastSeen: now, assessment: assessment, now: now).title == "Scanning paused")
check("stale overrides warmer", TrackingStatus(availability: .ready, isScanning: true, lastSeen: now.addingTimeInterval(-6), assessment: assessment, now: now).guidance == .signalLost)
check("denied reading is not live", !TrackingStatus(availability: .unauthorized, isScanning: false, lastSeen: now, assessment: assessment, now: now).isLive)
check("fresh warmer preserved", TrackingStatus(availability: .ready, isScanning: true, lastSeen: now, assessment: assessment, now: now).guidance == .warmer)
let radii = stride(from: -110.0, through: -15.0, by: 1).map { SignalMapLayout.displayRadius(for: $0, availableRadius: 140, centerClearance: 96) }
check("dots respect center clearance", radii.allSatisfy { $0 >= 96 && $0 <= 140 })
check("strength radius remains monotonic", zip(radii, radii.dropFirst()).allSatisfy { $0 >= $1 })
var analyzer = SignalTrendAnalyzer()
for index in 0..<10000 { _ = analyzer.add(rawRSSI: -70, at: Double(index) * 0.1) }
check("history remains bounded", analyzer.samples.count == 60)
check("constant signal stays steady", analyzer.currentAssessment?.guidance == .steady)
let unnamed = NearbyDevice(id: UUID(uuidString:"12345678-1234-1234-1234-123456789ABC")!, rawRSSI: -60, smoothedRSSI: -60, lastSeen: now, serviceCount: 0)
check("unnamed fallback distinct", unnamed.displayName == "Unnamed device · 5678")
check("missing manufacturer explicit", unnamed.manufacturerName == "Manufacturer not advertised")
print("\(passed) production-core checks passed; this is not iOS UI or physical BLE verification.")
