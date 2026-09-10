import XCTest
@testable import SignalScout

final class SignalTrendAnalyzerTests: XCTestCase {
    func testRejectsInvalidRSSI() {
        var analyzer = SignalTrendAnalyzer()
        XCTAssertNil(analyzer.add(rawRSSI: 127, at: 0))
        XCTAssertEqual(analyzer.samples.count, 0)
    }

    func testStrengtheningSignalBecomesWarmer() {
        var analyzer = SignalTrendAnalyzer()
        let readings = [-82, -82, -81, -80, -79, -73, -70, -68, -66, -64, -62, -60]
        var assessment: SignalAssessment?
        for (index, value) in readings.enumerated() {
            assessment = analyzer.add(rawRSSI: value, at: Double(index) * 0.65)
        }
        XCTAssertEqual(assessment?.guidance, .warmer)
        XCTAssertGreaterThan(assessment?.trendDB ?? 0, 2.2)
    }

    func testWeakeningSignalBecomesColder() {
        var analyzer = SignalTrendAnalyzer()
        let readings = [-55, -55, -56, -57, -58, -64, -67, -70, -72, -74, -76, -78]
        var assessment: SignalAssessment?
        for (index, value) in readings.enumerated() {
            assessment = analyzer.add(rawRSSI: value, at: Double(index) * 0.65)
        }
        XCTAssertEqual(assessment?.guidance, .colder)
        XCTAssertLessThan(assessment?.trendDB ?? 0, -2.2)
    }

    func testSmallJitterStaysSteady() {
        var analyzer = SignalTrendAnalyzer()
        let readings = [-68, -69, -67, -69, -68, -67, -69, -68, -67, -68, -69, -68]
        var assessment: SignalAssessment?
        for (index, value) in readings.enumerated() {
            assessment = analyzer.add(rawRSSI: value, at: Double(index) * 0.65)
        }
        XCTAssertEqual(assessment?.guidance, .steady)
    }

    func testResetClearsCalibration() {
        var analyzer = SignalTrendAnalyzer()
        _ = analyzer.add(rawRSSI: -70, at: 0)
        analyzer.reset()
        XCTAssertTrue(analyzer.samples.isEmpty)
        XCTAssertNil(analyzer.currentAssessment)
    }

    func testStrongSignalsMapCloserToPhoneThanWeakSignals() {
        let strong = SignalMapLayout.normalizedRadius(for: -45)
        let medium = SignalMapLayout.normalizedRadius(for: -70)
        let weak = SignalMapLayout.normalizedRadius(for: -95)
        XCTAssertLessThan(strong, medium)
        XCTAssertLessThan(medium, weak)
    }

    func testSignalMapRadiusClampsExtremeRSSIValues() {
        XCTAssertEqual(
            SignalMapLayout.normalizedRadius(for: -10),
            SignalMapLayout.normalizedRadius(for: -35),
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            SignalMapLayout.normalizedRadius(for: -120),
            SignalMapLayout.normalizedRadius(for: -100),
            accuracy: 0.000_001
        )
    }

    func testSignalMapAngleIsStableAndInRange() {
        let id = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let first = SignalMapLayout.stableAngle(for: id)
        let second = SignalMapLayout.stableAngle(for: id)
        XCTAssertEqual(first, second, accuracy: 0.000_001)
        XCTAssertGreaterThanOrEqual(first, 0)
        XCTAssertLessThan(first, 2 * Double.pi)
    }

    func testSignalMapCoordinateCombinesRadiusAndStableAngle() {
        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let coordinate = SignalMapLayout.coordinate(id: id, rssi: -70)
        XCTAssertEqual(coordinate.normalizedRadius, SignalMapLayout.normalizedRadius(for: -70))
        XCTAssertEqual(coordinate.angleRadians, SignalMapLayout.stableAngle(for: id))
    }

    func testDeviceUsesAnonymousSignalLabel() {
        let device = NearbyDevice(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            rawRSSI: -61,
            smoothedRSSI: -62,
            lastSeen: Date(timeIntervalSince1970: 1_000),
            serviceCount: 2
        )
        XCTAssertEqual(device.anonymousLabel, "Signal 5678")
    }

    func testPreviewClockStartsAtSixtySeconds() {
        XCTAssertEqual(
            SubscriptionManager.remainingPreviewSeconds(startedAt: 1_000, now: 1_000),
            60
        )
    }

    func testPreviewClockDoesNotResetAcrossElapsedTime() {
        XCTAssertEqual(
            SubscriptionManager.remainingPreviewSeconds(startedAt: 1_000, now: 1_059.2),
            1
        )
        XCTAssertEqual(
            SubscriptionManager.remainingPreviewSeconds(startedAt: 1_000, now: 1_061),
            0
        )
    }
}
