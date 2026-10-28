import Foundation

enum SearchGuidance: String, Equatable {
    case calibrating
    case warmer
    case colder
    case steady
    case signalLost

    var title: String {
        switch self {
        case .calibrating: return "Calibrating"
        case .warmer: return "Getting warmer"
        case .colder: return "Getting colder"
        case .steady: return "About the same"
        case .signalLost: return "Signal lost"
        }
    }

    var instruction: String {
        switch self {
        case .calibrating:
            return "Hold the phone naturally for a moment, then walk slowly."
        case .warmer:
            return "The signal is strengthening. Move slowly and compare again."
        case .colder:
            return "The signal is weakening. Compare with your previous position."
        case .steady:
            return "Move several more steps; small RSSI changes are just radio noise."
        case .signalLost:
            return "The device stopped advertising or moved out of range."
        }
    }
}

struct SignalSample: Equatable {
    let time: TimeInterval
    let rawRSSI: Int
    let smoothedRSSI: Double
}

struct SignalAssessment: Equatable {
    let smoothedRSSI: Double
    let guidance: SearchGuidance
    let trendDB: Double
    let confidence: Double
    let sampleCount: Int
}

struct SignalTrendAnalyzer {
    private(set) var samples: [SignalSample] = []
    private var smoothedRSSI: Double?

    private let maximumSamples = 60
    // Preserve a useful time span even when duplicate advertisements arrive rapidly.
    private let minimumSampleInterval: TimeInterval = 0.1
    private let maximumSampleGap: TimeInterval = 5
    private let smoothingAlpha = 0.24
    private let comparisonWindow: TimeInterval = 2.4
    private let minimumSamplesPerWindow = 3
    private let trendThreshold = 2.2

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
        smoothedRSSI = nil
    }

    mutating func add(rawRSSI: Int, at time: TimeInterval) -> SignalAssessment? {
        guard (-110 ... -15).contains(rawRSSI), time.isFinite else { return currentAssessment }

        if let last = samples.last {
            let elapsed = time - last.time
            if elapsed > maximumSampleGap || elapsed < 0 {
                // A recovered signal (or a changed system clock) needs a fresh baseline.
                reset()
            } else if elapsed < minimumSampleInterval {
                return currentAssessment
            }
        }

        let filteredInput = median(of: Array(samples.suffix(4).map(\.rawRSSI)) + [rawRSSI])
        let nextSmoothed: Double
        if let prior = smoothedRSSI {
            nextSmoothed = prior + smoothingAlpha * (Double(filteredInput) - prior)
        } else {
            nextSmoothed = Double(filteredInput)
        }
        smoothedRSSI = nextSmoothed
        samples.append(SignalSample(time: time, rawRSSI: rawRSSI, smoothedRSSI: nextSmoothed))
        if samples.count > maximumSamples {
            samples.removeFirst(samples.count - maximumSamples)
        }
        return makeAssessment(now: time)
    }

    var currentAssessment: SignalAssessment? {
        guard let last = samples.last else { return nil }
        return makeAssessment(now: last.time)
    }

    private func makeAssessment(now: TimeInterval) -> SignalAssessment? {
        guard let current = smoothedRSSI else { return nil }

        // Slower advertisers still need three observations in each comparison window.
        // Use recent cadence so a rate change does not leave the whole history calibrating.
        let cadenceSamples = samples.suffix(minimumSamplesPerWindow * 2 + 1)
        let intervals = zip(cadenceSamples, cadenceSamples.dropFirst())
            .map { earlier, later in later.time - earlier.time }.sorted()
        let typicalInterval = intervals.isEmpty ? 0 : intervals[intervals.count / 2]
        // Allow a little timing jitter without dropping back into calibration at every boundary.
        let window = max(comparisonWindow, typicalInterval * (Double(minimumSamplesPerWindow) + 0.5))
        let recentStart = now - window
        let priorStart = now - window * 2
        let recent = samples.filter { $0.time > recentStart }
        let prior = samples.filter { $0.time > priorStart && $0.time <= recentStart }

        guard recent.count >= minimumSamplesPerWindow,
              prior.count >= minimumSamplesPerWindow else {
            return SignalAssessment(
                smoothedRSSI: current,
                guidance: .calibrating,
                trendDB: 0,
                confidence: 0,
                sampleCount: samples.count
            )
        }

        let recentAverage = recent.map(\.smoothedRSSI).reduce(0, +) / Double(recent.count)
        let priorAverage = prior.map(\.smoothedRSSI).reduce(0, +) / Double(prior.count)
        let delta = recentAverage - priorAverage
        let guidance: SearchGuidance
        if delta >= trendThreshold {
            guidance = .warmer
        } else if delta <= -trendThreshold {
            guidance = .colder
        } else {
            guidance = .steady
        }

        return SignalAssessment(
            smoothedRSSI: current,
            guidance: guidance,
            trendDB: delta,
            confidence: min(1, abs(delta) / 7),
            sampleCount: samples.count
        )
    }

    private func median(of values: [Int]) -> Int {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return -100 }
        return sorted[sorted.count / 2]
    }
}
