#if DUO_DIAGNOSTICS
import Darwin
import Foundation
import SwiftUI
import UIKit

// This entire observer is absent from ordinary builds. The experimental build
// must also receive a valid session argument before it starts any diagnostics.
@available(iOS 27.1, *)
@MainActor
struct DuoHingeDiagnostics: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let arguments = ProcessInfo.processInfo.arguments
        let matches = arguments.indices.filter { arguments[$0] == "--duo-telemetry-session" }
        guard !DuoHingeTelemetryProcess.failedClosed,
              matches.count == 1, let index = matches.first,
              arguments.indices.contains(index + 1),
              UUID(uuidString: arguments[index + 1]) != nil else {
            let placeholder = UIView(frame: .zero)
            placeholder.isUserInteractionEnabled = false
            placeholder.isAccessibilityElement = false
            placeholder.accessibilityElementsHidden = true
            return placeholder
        }
        // Preserve the host's spelling: UUID.uuidString would uppercase it.
        return DuoHingeTelemetryView(sessionID: arguments[index + 1])
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        (uiView as? DuoHingeTelemetryView)?.shutdown()
    }
}

@available(iOS 27.1, *)
@MainActor
private enum DuoHingeTelemetryProcess {
    // A recreated view or a display handoff must never restart this sequence.
    static var eventSequence: UInt64 = 0
    static weak var owner: DuoHingeTelemetryView?
    static var failedClosed = false
}

@available(iOS 27.1, *)
@MainActor
private final class DuoHingeTelemetryView: UIView {
    private struct Request: Decodable {
        let sessionID: String
        let requestID: String
    }

    private struct Observation {
        let sequence: UInt64
        let time: TimeInterval
        let angleDegrees: Double?
        let status: String?
        let available: Bool
    }

    private let sessionID: String
    private let directoryURL: URL
    private let requestURL: URL
    private let snapshotURL: URL
    private var timer: Timer?
    private var notificationTokens: [NSObjectProtocol] = []
    private var request: Request?
    private var lastRequestUUID: UUID?
    private var observation: Observation?
    private var interaction: UIHingeInteraction?
    private var generation: UUID?
    private var lastSceneID = ""
    private var lifecycleSuspended = false
    private var stopped = false

    init(sessionID: String) {
        self.sessionID = sessionID
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directoryURL = caches.appendingPathComponent("SignalScout-Duo", isDirectory: true)
        requestURL = directoryURL.appendingPathComponent("request.json")
        snapshotURL = directoryURL.appendingPathComponent("snapshot.json")
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        let names: [Notification.Name] = [
            UIScene.didActivateNotification,
            UIScene.willDeactivateNotification,
            UIScene.didEnterBackgroundNotification,
            UIScene.didDisconnectNotification
        ]
        notificationTokens = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                MainActor.assumeIsolated { self?.sceneNotification(note) }
            }
        }
        let pollTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer = pollTimer
        RunLoop.main.add(pollTimer, forMode: .common)
    }

    required init?(coder: NSCoder) { return nil }

    deinit {
        timer?.invalidate()
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !stopped else { return }
        if let scene = window?.windowScene {
            let sceneChanged = lastSceneID != scene.session.persistentIdentifier
            if sceneChanged { invalidate(sceneState: stateName(scene.activationState)) }
            lastSceneID = scene.session.persistentIdentifier
            lifecycleSuspended = scene.activationState != .foregroundActive
        } else {
            invalidate(sceneState: "unattached")
        }
        poll()
    }

    private var hasActiveWindow: Bool {
        !stopped && !DuoHingeTelemetryProcess.failedClosed && !lifecycleSuspended
            && window != nil && window?.isHidden == false
            && window?.windowScene?.activationState == .foregroundActive
    }

    private func sceneNotification(_ notification: Notification) {
        guard !stopped, let scene = notification.object as? UIWindowScene,
              scene === window?.windowScene else { return }
        switch notification.name {
        case UIScene.didActivateNotification:
            lifecycleSuspended = false
            poll()
        case UIScene.willDeactivateNotification:
            // This notification can precede activationState's transition.
            lifecycleSuspended = true
            invalidate(sceneState: "foregroundInactive")
        case UIScene.didEnterBackgroundNotification:
            lifecycleSuspended = true
            invalidate(sceneState: "background")
        case UIScene.didDisconnectNotification:
            lifecycleSuspended = true
            invalidate(sceneState: "unattached")
        default:
            break
        }
    }

    private func poll() {
        guard !stopped else { return }
        guard !DuoHingeTelemetryProcess.failedClosed else {
            stopWithoutWriting()
            return
        }
        guard hasActiveWindow else {
            if DuoHingeTelemetryProcess.owner === self {
                invalidate(sceneState: currentSceneState)
            }
            return
        }

        // Only one live hierarchy publishes this process's telemetry at a time.
        if let owner = DuoHingeTelemetryProcess.owner, owner !== self {
            guard !owner.hasActiveWindow else { return }
            owner.invalidate(sceneState: owner.currentSceneState)
        }
        DuoHingeTelemetryProcess.owner = self
        guard let data = try? Data(contentsOf: requestURL), data.count <= 4_096,
              let incoming = try? JSONDecoder().decode(Request.self, from: data),
              incoming.sessionID == sessionID,
              let requestUUID = UUID(uuidString: incoming.requestID) else { return }

        if requestUUID != lastRequestUUID {
            retireInteraction()
            lastRequestUUID = requestUUID
            request = incoming
            observation = nil
            // A new request never inherits the previous request's measurement.
            writeSnapshot(available: false)
        }
        if interaction == nil { beginObservation() }
    }

    private func beginObservation() {
        guard hasActiveWindow, DuoHingeTelemetryProcess.owner === self,
              let request else { return }
        let thisGeneration = UUID()
        generation = thisGeneration
        let observer = UIHingeInteraction { [weak self] observer, update in
            guard let self, self.generation == thisGeneration,
                  self.interaction === observer,
                  DuoHingeTelemetryProcess.owner === self,
                  self.request?.requestID == request.requestID else { return }
            self.receive(update, for: request)
        }
        // UIKit documents an initial/current callback when observation is enabled.
        // A new interaction generation prevents an old queued callback from being
        // labeled with a later request ID. No cached angle is used to answer it.
        observer.isEnabled = false
        interaction = observer
        addInteraction(observer)
        observer.isEnabled = true
    }

    private func receive(_ update: UIHingeInteraction.Update, for request: Request) {
        guard !stopped, !DuoHingeTelemetryProcess.failedClosed,
              self.request?.requestID == request.requestID else { return }
        DuoHingeTelemetryProcess.eventSequence += 1
        let sequence = DuoHingeTelemetryProcess.eventSequence
        let observedAt = Date().timeIntervalSince1970
        var angleDegrees: Double?
        var status: String?
        var available = false
        if let hinge = update.hinge {
            switch hinge.status {
            case .closed: status = "closed"
            case .partiallyOpen: status = "partiallyOpen"
            case .fullyOpen: status = "fullyOpen"
            case .unknown: status = "unknown"
            @unknown default: status = "unknown"
            }
            let degrees = Double(hinge.angle) * 180 / Double.pi
            if hasActiveWindow && degrees.isFinite && status != "unknown" {
                angleDegrees = degrees
                available = true
            }
        }
        observation = Observation(sequence: sequence, time: observedAt,
                                  angleDegrees: angleDegrees, status: status, available: available)
        writeSnapshot(available: available)
    }

    private func retireInteraction() {
        generation = nil
        if let observer = interaction {
            interaction = nil
            observer.isEnabled = false
            removeInteraction(observer)
        }
    }

    private func invalidate(sceneState: String) {
        let wasOwner = DuoHingeTelemetryProcess.owner === self
        retireInteraction()
        if wasOwner {
            // Lifecycle changes are not hinge measurements: keep the last
            // callback's sequence/time, but make its value unavailable.
            writeSnapshot(available: false, sceneState: sceneState)
            DuoHingeTelemetryProcess.owner = nil
        }
    }

    private var currentSceneState: String {
        guard let scene = window?.windowScene else { return "unattached" }
        if lifecycleSuspended && scene.activationState == .foregroundActive {
            return "foregroundInactive"
        }
        return stateName(scene.activationState)
    }

    private func stateName(_ state: UIScene.ActivationState) -> String {
        switch state {
        case .foregroundActive: return "foregroundActive"
        case .foregroundInactive: return "foregroundInactive"
        case .background: return "background"
        case .unattached: return "unattached"
        @unknown default: return "unknown"
        }
    }

    private func writeSnapshot(available: Bool, sceneState: String? = nil) {
        guard !DuoHingeTelemetryProcess.failedClosed, let request else { return }
        let isAvailable = available && hasActiveWindow && observation?.available == true
        let reportedStatus = isAvailable || observation?.status == "unknown" ? observation?.status : nil
        let payload: [String: Any] = [
            "schemaVersion": 1,
            "sessionID": sessionID,
            "requestID": request.requestID,
            "eventSequence": observation?.sequence ?? 0,
            "observedAtUnixSeconds": observation.map { $0.time as Any } ?? NSNull(),
            "processID": ProcessInfo.processInfo.processIdentifier,
            "sceneID": window?.windowScene?.session.persistentIdentifier ?? lastSceneID,
            "sceneState": sceneState ?? currentSceneState,
            "available": isAvailable,
            "angleDegrees": isAvailable ? (observation?.angleDegrees).map { $0 as Any } ?? NSNull() : NSNull(),
            "status": reportedStatus.map { $0 as Any } ?? NSNull()
        ]
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            try data.write(to: snapshotURL, options: [.atomic])
        } catch {
            failClosed(after: error)
        }
    }

    private func failClosed(after error: Error) {
        // A failed invalidation must not leave a previous successful response
        // readable as the current live result. Never attempt another JSON write.
        DuoHingeTelemetryProcess.failedClosed = true
        NSLog("[DuoHingeDiagnostics] Session %@ failed closed after snapshot write error: %@",
              sessionID, error.localizedDescription)
        stopWithoutWriting()
        do {
            try FileManager.default.removeItem(at: snapshotURL)
        } catch let removalError as CocoaError where removalError.code == .fileNoSuchFile {
            // No response file remains for the host to accept.
        } catch {
            NSLog("[DuoHingeDiagnostics] Cannot remove stale snapshot: %@. Terminating experimental process.",
                  error.localizedDescription)
            // This path exists only in the explicitly enabled diagnostic build.
            // A stale file cannot be accepted as a response from a live process.
            Darwin.exit(EXIT_FAILURE)
        }
    }

    func shutdown() {
        guard !stopped else { return }
        invalidate(sceneState: currentSceneState)
        stopWithoutWriting()
    }

    private func stopWithoutWriting() {
        guard !stopped else { return }
        stopped = true
        retireInteraction()
        if DuoHingeTelemetryProcess.owner === self { DuoHingeTelemetryProcess.owner = nil }
        timer?.invalidate()
        timer = nil
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
        notificationTokens.removeAll()
    }
}
#endif
