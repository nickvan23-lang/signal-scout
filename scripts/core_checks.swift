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
for interval in [1.0, 2.0, 4.0] {
    let cases: [([Int], SearchGuidance)] = [
        ([-82, -82, -81, -80, -79, -73, -70, -68, -66, -64, -62, -60], .warmer),
        ([-55, -55, -56, -57, -58, -64, -67, -70, -72, -74, -76, -78], .colder),
        (Array(repeating: -70, count: 12), .steady)
    ]
    for (readings, expected) in cases {
        var slow = SignalTrendAnalyzer()
        for (index, reading) in readings.enumerated() {
            _ = slow.add(rawRSSI: reading, at: Double(index) * interval)
        }
        check("\(interval)s advertisements become \(expected)", slow.currentAssessment?.guidance == expected)
    }
}
var fast = SignalTrendAnalyzer()
for intervals in [[1.0225], [0.97, 1.05, 1.02, 0.98, 0.99]] {
    for start in [0.0, 800_000_000.0] {
        var jittered = SignalTrendAnalyzer()
        var jitterTime: TimeInterval = start
        var jitterRemainsSteady = true
        for index in 0..<100 {
            jitterTime += intervals[index % intervals.count]
            let result = jittered.add(rawRSSI: -70, at: jitterTime)
            if index >= 20 { jitterRemainsSteady = jitterRemainsSteady && result?.guidance == .steady }
        }
        check("cadence \(intervals) at \(start) does not restart calibration", jitterRemainsSteady)
    }
}
for index in 0..<2_000 { _ = fast.add(rawRSSI: -70, at: Double(index) * 0.02) }
check("fast advertisements finish calibration", fast.currentAssessment?.guidance == .steady)
check("fast history remains bounded", fast.samples.count == 60)
check("fast history retains comparison time", fast.samples.last!.time - fast.samples.first!.time >= 4.8)
for sign in [-1, 1] {
    var fastTrend = SignalTrendAnalyzer()
    for index in 0..<500 {
        let reading = sign == 1 ? -90 + index / 10 : -35 - index / 10
        _ = fastTrend.add(rawRSSI: reading, at: Double(index) * 0.02)
    }
    check("fast advertisements detect \(sign == 1 ? "warmer" : "colder")", fastTrend.currentAssessment?.guidance == (sign == 1 ? .warmer : .colder))
}
var insufficient = SignalTrendAnalyzer()
for index in 0..<5 { _ = insufficient.add(rawRSSI: -80 + index * 5, at: Double(index) * 2) }
check("sparse evidence stays calibrating", insufficient.currentAssessment?.guidance == .calibrating)
check("sparse evidence is not confident", insufficient.currentAssessment?.confidence == 0)
var recovered = SignalTrendAnalyzer()
for index in 0..<20 { _ = recovered.add(rawRSSI: -50, at: Double(index) * 0.65) }
let firstRecovery = recovered.add(rawRSSI: -90, at: 100)
check("recovery uses current strength", firstRecovery?.smoothedRSSI == -90)
check("recovery resets calibration", firstRecovery?.guidance == .calibrating && firstRecovery?.sampleCount == 1)
for index in 1..<12 { _ = recovered.add(rawRSSI: -90, at: 100 + Double(index) * 0.65) }
check("stationary recovery does not invent motion", recovered.currentAssessment?.guidance == .steady)
var clockReset = SignalTrendAnalyzer()
_ = clockReset.add(rawRSSI: -50, at: 100)
let afterClockReset = clockReset.add(rawRSSI: -90, at: 99)
check("clock rollback resets baseline", afterClockReset?.smoothedRSSI == -90 && afterClockReset?.sampleCount == 1)
let unnamed = NearbyDevice(id: UUID(uuidString:"12345678-1234-1234-1234-123456789ABC")!, rawRSSI: -60, smoothedRSSI: -60, lastSeen: now, serviceCount: 0)
check("unnamed fallback distinct", unnamed.displayName == "Unnamed device · 5678")
check("missing manufacturer explicit", unnamed.manufacturerName == "Manufacturer not advertised")
print("\(passed) production-core checks passed; this is not iOS UI or physical BLE verification.")
