import Foundation
var passed = 0
var failed = 0
func check(_ name: String, _ condition: @autoclosure () -> Bool) {
    if condition() { passed += 1; print("PASS: \(name)") }
    else { failed += 1; print("FAIL: \(name)") }
}
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

print("RESULT: \(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
