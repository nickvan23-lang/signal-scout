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

    func testSlowAdvertisementsCanFinishCalibrationAndCompareSignals() {
        let cases: [([Int], SearchGuidance)] = [
            ([-82, -82, -81, -80, -79, -73, -70, -68, -66, -64, -62, -60], .warmer),
            ([-55, -55, -56, -57, -58, -64, -67, -70, -72, -74, -76, -78], .colder),
            (Array(repeating: -70, count: 12), .steady)
        ]
        for interval in [1.0, 2.0, 4.0] {
            for (readings, expected) in cases {
                var analyzer = SignalTrendAnalyzer()
                for (index, reading) in readings.enumerated() {
                    _ = analyzer.add(rawRSSI: reading, at: Double(index) * interval)
                }
                XCTAssertEqual(analyzer.currentAssessment?.guidance, expected,
                               "Failed at \(interval)-second advertisement intervals")
            }
        }
    }

    func testFastAdvertisementsRetainEnoughTimeForComparison() {
        var analyzer = SignalTrendAnalyzer()
        for index in 0..<2_000 {
            _ = analyzer.add(rawRSSI: -70, at: Double(index) * 0.02)
        }
        XCTAssertEqual(analyzer.samples.count, 60)
        XCTAssertEqual(analyzer.currentAssessment?.guidance, .steady)
        XCTAssertGreaterThanOrEqual(analyzer.samples.last!.time - analyzer.samples.first!.time, 4.8)
    }

    func testSlowAdvertisementJitterDoesNotRepeatedlyRestartCalibration() {
        for intervals in [[1.0225], [0.97, 1.05, 1.02, 0.98, 0.99]] {
            for start in [0.0, 800_000_000.0] {
                var analyzer = SignalTrendAnalyzer()
                var time: TimeInterval = start
                for index in 0..<100 {
                    time += intervals[index % intervals.count]
                    let assessment = analyzer.add(rawRSSI: -70, at: time)
                    if index >= 20 {
                        XCTAssertEqual(assessment?.guidance, .steady)
                    }
                }
            }
        }
    }

    func testFastAdvertisementsStillDetectChangingSignals() {
        for sign in [-1, 1] {
            var analyzer = SignalTrendAnalyzer()
            for index in 0..<500 {
                let reading = sign == 1 ? -90 + index / 10 : -35 - index / 10
                _ = analyzer.add(rawRSSI: reading, at: Double(index) * 0.02)
            }
            XCTAssertEqual(analyzer.currentAssessment?.guidance, sign == 1 ? .warmer : .colder)
        }
    }

    func testSlowAdvertisementsNeedEnoughEvidenceBeforeGivingDirection() {
        var analyzer = SignalTrendAnalyzer()
        for index in 0..<5 {
            let assessment = analyzer.add(rawRSSI: -80 + index * 5, at: Double(index) * 2)
            XCTAssertEqual(assessment?.guidance, .calibrating)
            XCTAssertEqual(assessment?.confidence, 0)
        }
    }

    func testLostSignalRecoveryDoesNotReuseOldStrengthOrTrend() {
        var analyzer = SignalTrendAnalyzer()
        for index in 0..<20 {
            _ = analyzer.add(rawRSSI: -50, at: Double(index) * 0.65)
        }
        let recovered = analyzer.add(rawRSSI: -90, at: 100)
        XCTAssertEqual(recovered?.smoothedRSSI, -90)
        XCTAssertEqual(recovered?.guidance, .calibrating)
        XCTAssertEqual(recovered?.sampleCount, 1)
        for index in 1..<12 {
            let assessment = analyzer.add(rawRSSI: -90, at: 100 + Double(index) * 0.65)
            XCTAssertNotEqual(assessment?.guidance, .warmer)
            XCTAssertNotEqual(assessment?.guidance, .colder)
        }
        XCTAssertEqual(analyzer.currentAssessment?.guidance, .steady)
    }

    func testClockMovingBackwardStartsANewBaseline() {
        var analyzer = SignalTrendAnalyzer()
        _ = analyzer.add(rawRSSI: -50, at: 100)
        let recovered = analyzer.add(rawRSSI: -90, at: 99)
        XCTAssertEqual(recovered?.smoothedRSSI, -90)
        XCTAssertEqual(recovered?.sampleCount, 1)
        XCTAssertEqual(recovered?.guidance, .calibrating)
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

    func testUnnamedDeviceHasDistinctFallback() {
        let device = NearbyDevice(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            rawRSSI: -61,
            smoothedRSSI: -62,
            lastSeen: Date(timeIntervalSince1970: 1_000),
            serviceCount: 2
        )
        XCTAssertEqual(device.displayName, "Unnamed device · 5678")
    }
    func testNearbyStrengthSortHasNoOneDBComparisonCycle() {
        let ids = ["00000001-0000-0000-0000-000000000001", "00000002-0000-0000-0000-000000000002", "00000003-0000-0000-0000-000000000003"]
        let devices = zip(ids, [-61.6, -60.8, -60.0]).map { id, rssi in
            NearbyDevice(id: UUID(uuidString: id)!, rawRSSI: Int(rssi), smoothedRSSI: rssi, lastSeen: Date(), serviceCount: 0)
        }
        for ordering in [devices, Array(devices.reversed()), [devices[1], devices[2], devices[0]]] {
            XCTAssertEqual(ordering.sorted(by: NearbyDevice.strongestFirst).map(\.smoothedRSSI), [-60.0, -60.8, -61.6])
        }
        XCTAssertFalse(NearbyDevice.strongestFirst(devices[0], devices[0]))
    }

    func testSignalHistoryStaysBoundedDuringLongScan() {
        var analyzer = SignalTrendAnalyzer()
        for index in 0..<10_000 {
            _ = analyzer.add(rawRSSI: -70, at: Double(index) * 0.1)
        }
        XCTAssertEqual(analyzer.samples.count, 60)
        XCTAssertEqual(analyzer.currentAssessment?.guidance, .steady)
    }

    func testDisplayedMapRadiusKeepsTargetsOutsidePhone() {
        for rssi in stride(from: -110.0, through: -15.0, by: 1) {
            let radius = SignalMapLayout.displayRadius(for: rssi, availableRadius: 140, centerClearance: 72)
            XCTAssertGreaterThanOrEqual(radius, 72)
            XCTAssertLessThanOrEqual(radius, 140)
        }
        XCTAssertLessThan(SignalMapLayout.displayRadius(for: -45, availableRadius: 140, centerClearance: 72), SignalMapLayout.displayRadius(for: -85, availableRadius: 140, centerClearance: 72))
        XCTAssertEqual(SignalMapLayout.displayRadius(for: -45, availableRadius: 0, centerClearance: 72), 0)
    }

    func testPausedAndLostReadingsNeverShowWarmer() {
        let now = Date(timeIntervalSince1970: 1000)
        let warmer = SignalAssessment(smoothedRSSI: -50, guidance: .warmer, trendDB: 4, confidence: 1, sampleCount: 20)
        let paused = TrackingStatus(availability: .ready, isScanning: false, lastSeen: now, assessment: warmer, now: now)
        XCTAssertEqual(paused.title, "Scanning paused")
        XCTAssertFalse(paused.isLive)
        let lost = TrackingStatus(availability: .ready, isScanning: true, lastSeen: now.addingTimeInterval(-6), assessment: warmer, now: now)
        XCTAssertEqual(lost.guidance, .signalLost)
        XCTAssertFalse(lost.isLive)
        let denied = TrackingStatus(availability: .unauthorized, isScanning: false, lastSeen: now, assessment: warmer, now: now)
        XCTAssertEqual(denied.title, BluetoothAvailability.unauthorized.message)
        XCTAssertFalse(denied.isLive)
        let live = TrackingStatus(availability: .ready, isScanning: true, lastSeen: now, assessment: warmer, now: now)
        XCTAssertEqual(live.guidance, .warmer)
        XCTAssertTrue(live.isLive)
    }

    func testAdvertisedNameAndManufacturerTakePrecedenceAndSurviveSparsePackets() {
        let identity = DeviceIdentity().merging(localName: "  Studio headphones  ", peripheralName: "Cached name", manufacturerData: Data([0x4C, 0x00, 0xAA]))
        XCTAssertEqual(identity.name, "Studio headphones")
        XCTAssertEqual(identity.companyID, 76)
        XCTAssertEqual(identity.merging(localName: nil, peripheralName: "Old cached name", manufacturerData: nil).name, "Studio headphones")
        XCTAssertEqual(identity.merging(localName: nil, peripheralName: nil, manufacturerData: nil), identity)
        let updated = identity.merging(localName: "Renamed headphones", peripheralName: nil, manufacturerData: Data([0x75, 0x00]))
        XCTAssertEqual(updated.name, "Renamed headphones")
        XCTAssertEqual(updated.companyID, 117)
    }

    func testIdentityHandlesMissingShortAndNonASCIIData() {
        XCTAssertNil(DeviceIdentity.companyIdentifier(from: Data([0x4C])))
        XCTAssertNil(DeviceIdentity.companyIdentifier(from: Data()))
        XCTAssertNil(DeviceIdentity.cleanedName(" \n\t"))
        XCTAssertEqual(DeviceIdentity.cleanedName("Café 🎧\nHeadphones"), "Café 🎧 Headphones")
        XCTAssertEqual(DeviceIdentity().merging(localName: nil, peripheralName: "Desk speaker", manufacturerData: nil).name, "Desk speaker")
    }

    func testBundledManufacturerRegistryResolvesKnownAndUnknownIdentifiers() {
        XCTAssertGreaterThan(BluetoothCompanyRegistry.names.count, 4000)
        XCTAssertTrue(BluetoothCompanyRegistry.name(for: 76).contains("Apple"))
        XCTAssertTrue(BluetoothCompanyRegistry.name(for: 117).contains("Samsung"))
        XCTAssertEqual(BluetoothCompanyRegistry.name(for: 65534), "Unknown manufacturer (0xFFFE)")
    }

}
