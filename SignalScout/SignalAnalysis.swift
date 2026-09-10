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
        case .signalLost: return "Signal paused"
        }
    }

    var instruction: String {
        switch self {
        case .calibrating:
            return "Hold the phone naturally for a moment, then walk slowly."
        case .warmer:
            return "Keep moving this way while the trend stays stronger."
        case .colder:
            return "Return to your last spot and try a different direction."
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
    private let smoothingAlpha = 0.24
    private let comparisonWindow: TimeInterval = 2.4
    private let minimumSamplesPerWindow = 3
    private let trendThreshold = 2.2

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
        smoothedRSSI = nil
    }

    mutating func add(rawRSSI: Int, at time: TimeInterval) -> SignalAssessment? {
        guard (-110 ... -15).contains(rawRSSI) else { return currentAssessment }

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

        let recentStart = now - comparisonWindow
        let priorStart = now - comparisonWindow * 2
        let recent = samples.filter { $0.time > recentStart }
        let prior = samples.filter { $0.time > priorStart && $0.time <= recentStart }

        guard recent.count >= minimumSamplesPerWindow,
              prior.count >= minimumSamplesPerWindow else {
            return SignalAssessment(
                smoothedRSSI: current,
                guidance: .calibrating,
                trendDB: 0,
                confidence: min(1, Double(samples.count) / 10),
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
