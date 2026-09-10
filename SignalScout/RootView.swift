import SwiftUI

enum ScoutPalette {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.075)
    static let panel = Color(red: 0.075, green: 0.105, blue: 0.135)
    static let cyan = Color(red: 0.12, green: 0.86, blue: 0.78)
    static let amber = Color(red: 1.0, green: 0.65, blue: 0.18)
    static let red = Color(red: 1.0, green: 0.32, blue: 0.30)
    static let secondary = Color.white.opacity(0.66)
}

private enum ScannerPresentation: String, CaseIterable, Identifiable {
    case map = "Live Map"
    case list = "Device List"

    var id: Self { self }
}

struct RootView: View {
    @EnvironmentObject private var subscription: SubscriptionManager

    var body: some View {
        Group {
            switch subscription.access {
            case .loading:
                ZStack {
                    ScoutPalette.background.ignoresSafeArea()
                    ProgressView("Checking App Store…")
                        .tint(ScoutPalette.cyan)
                        .foregroundStyle(ScoutPalette.secondary)
                }
            case .preview, .subscribed:
                ScoutFeatureView()
            case .previewAvailable, .locked:
                SubscriptionPaywallView()
            }
        }
        .task {
            await subscription.prepare()
        }
    }
}

private struct ScoutFeatureView: View {
    @StateObject private var scanner = BluetoothScanner()

    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SignalScoutFullScreenScreenshotMode") {
            FullScreenSignalMap()
                .environmentObject(scanner)
        } else {
            navigationContent
        }
#else
        navigationContent
#endif
    }

    private var navigationContent: some View {
        NavigationStack {
            Group {
                if scanner.selectedDevice != nil {
                    TrackingView()
                } else {
                    ScannerView()
                }
            }
            .background(ScoutPalette.background.ignoresSafeArea())
            .toolbarBackground(ScoutPalette.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(ScoutPalette.cyan)
        .environmentObject(scanner)
    }
}

private struct ScannerView: View {
    @EnvironmentObject private var scanner: BluetoothScanner
    @EnvironmentObject private var subscription: SubscriptionManager
    @State private var presentation: ScannerPresentation = .map
    @State private var isShowingFullScreenMap = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                header
                if let remaining = subscription.previewSecondsRemaining {
                    PreviewCountdownBanner(secondsRemaining: remaining)
                }
                statusCard

                Picker("Scanner presentation", selection: $presentation) {
                    ForEach(ScannerPresentation.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if scanner.devices.isEmpty {
                    emptyState
                } else if presentation == .map {
                    LiveSignalMap(
                        devices: scanner.devices,
                        isStale: { scanner.isStale($0) },
                        select: scanner.select,
                        expand: { isShowingFullScreenMap = true }
                    )
                } else {
                    ForEach(scanner.devices) { device in
                        Button {
                            scanner.select(device)
                        } label: {
                            DeviceRow(device: device, isStale: scanner.isStale(device))
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Tracks changes in this device's signal strength")
                    }
                }

                limitations
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
        .navigationTitle("Signal Scout")
        .fullScreenCover(isPresented: $isShowingFullScreenMap) {
            FullScreenSignalMap()
                .environmentObject(scanner)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(scanner.isScanning ? "Pause scanning" : "Resume scanning") {
                        scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
                    }
                    Button("Clear inactive devices") {
                        scanner.clearInactiveDevices()
                    }
                    Divider()
                    Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    Link("Privacy Policy", destination: URL(string: "https://nickvan23-lang.github.io/signal-scout/privacy.html")!)
                    Link("Support", destination: URL(string: "https://nickvan23-lang.github.io/signal-scout/support.html")!)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Scanner options")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find an advertising BLE device")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("Watch every live signal move by relative strength, or choose one for warmer-and-colder guidance.")
                .font(.subheadline)
                .foregroundStyle(ScoutPalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((scanner.availability == .ready ? ScoutPalette.cyan : ScoutPalette.amber).opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: scanner.isScanning ? "dot.radiowaves.left.and.right" : "pause.fill")
                    .foregroundStyle(scanner.availability == .ready ? ScoutPalette.cyan : ScoutPalette.amber)
                    .symbolEffect(.pulse, isActive: scanner.isScanning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(scanner.availability.message)
                    .font(.headline)
                Text(scanner.isScanning ? "Listening for advertisements" : "Scanner paused")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
            Spacer()
            Text("\(scanner.devices.count)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
        }
        .padding(16)
        .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(ScoutPalette.cyan)
                .scaleEffect(1.15)
            Text("Listening nearby…")
                .font(.headline)
            Text("Wake or move the item you want to find. Only devices currently broadcasting Bluetooth Low Energy advertisements can appear.")
                .font(.subheadline)
                .foregroundStyle(ScoutPalette.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 24)
        .background(ScoutPalette.panel.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var limitations: some View {
        Label {
            Text("Names and identifiers may be hidden or rotate. Signal strength is approximate and is not a precise distance or direction.")
        } icon: {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(ScoutPalette.cyan)
        }
        .font(.footnote)
        .foregroundStyle(ScoutPalette.secondary)
        .padding(.top, 6)
    }
}

private struct PreviewCountdownBanner: View {
    let secondsRemaining: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
            Text("Free preview")
                .font(.subheadline.bold())
            Spacer()
            Text("\(secondsRemaining)s")
                .font(.system(.headline, design: .monospaced, weight: .bold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(ScoutPalette.background)
        .padding(.horizontal, 15)
        .frame(minHeight: 48)
        .background(ScoutPalette.amber, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel("Free preview, \(secondsRemaining) seconds remaining")
    }
}

private struct LiveSignalMap: View {
    let devices: [NearbyDevice]
    let isStale: (NearbyDevice) -> Bool
    let select: (NearbyDevice) -> Void
    let expand: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live signal field")
                        .font(.headline)
                    Text("Center means stronger RSSI")
                        .font(.caption)
                        .foregroundStyle(ScoutPalette.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Label("Live", systemImage: "circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(ScoutPalette.cyan)
                    Button(action: expand) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Open full screen signal map")
                }
            }

            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                let usableRadius = max(0, side / 2 - 34)

                ZStack {
                    SignalMapGrid()

                    ForEach(devices) { device in
                        let coordinate = SignalMapLayout.coordinate(id: device.id, rssi: device.smoothedRSSI)
                        let radius = usableRadius * coordinate.normalizedRadius
                        let position = CGPoint(
                            x: center.x + CGFloat(cos(coordinate.angleRadians)) * radius,
                            y: center.y + CGFloat(sin(coordinate.angleRadians)) * radius
                        )

                        Button {
                            select(device)
                        } label: {
                            SignalMapDot(device: device, stale: isStale(device))
                        }
                        .buttonStyle(.plain)
                        .position(position)
                        .animation(.easeOut(duration: 0.48), value: Int(device.smoothedRSSI.rounded()))
                        .accessibilityHint("Tracks changes in this device's signal strength")
                    }

                    VStack(spacing: 3) {
                        Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                            .font(.system(size: 25, weight: .semibold))
                        Text("THIS PHONE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(ScoutPalette.background)
                    .frame(width: 68, height: 68)
                    .background(ScoutPalette.cyan, in: Circle())
                    .shadow(color: ScoutPalette.cyan.opacity(0.38), radius: 14)
                    .position(center)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("This iPhone, center of signal map")
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                MapLegendDot(color: ScoutPalette.cyan, text: "strong")
                MapLegendDot(color: ScoutPalette.amber, text: "medium")
                MapLegendDot(color: ScoutPalette.red, text: "weak")
                Spacer(minLength: 0)
                Text("Tap a dot to track")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }

            Label {
                Text("Dot angles are stable visual lanes, not measured directions. Only distance from the center reacts to signal strength.")
            } icon: {
                Image(systemName: "scope")
                    .foregroundStyle(ScoutPalette.cyan)
            }
            .font(.footnote)
            .foregroundStyle(ScoutPalette.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Live relative Bluetooth signal map with \(devices.count) devices")
    }
}

private struct FullScreenSignalMap: View {
    @EnvironmentObject private var scanner: BluetoothScanner
    @EnvironmentObject private var subscription: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 0.58
    @GestureState private var gestureScale: CGFloat = 1

    private var effectiveZoom: CGFloat {
        min(2.4, max(0.58, zoom * gestureScale))
    }

    var body: some View {
        ZStack {
            ScoutPalette.background.ignoresSafeArea()

            VStack(spacing: 10) {
                fullScreenHeader

                if scanner.devices.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(ScoutPalette.cyan)
                        Text("Listening for Bluetooth signals…")
                            .font(.headline)
                        Text("Advertising devices will appear on the field as they are discovered.")
                            .font(.subheadline)
                            .foregroundStyle(ScoutPalette.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)
                } else {
                    GeometryReader { proxy in
                        let canvasSide = max(proxy.size.width, proxy.size.height) * effectiveZoom

                        ScrollView([.horizontal, .vertical]) {
                            ExpandedSignalCanvas(
                                devices: scanner.devices,
                                isStale: { scanner.isStale($0) },
                                select: { device in
                                    scanner.select(device)
                                    dismiss()
                                }
                            )
                            .frame(width: canvasSide, height: canvasSide)
                        }
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.center)
                        .simultaneousGesture(
                            MagnifyGesture()
                                .updating($gestureScale) { value, state, _ in
                                    state = value.magnification
                                }
                                .onEnded { value in
                                    zoom = min(2.4, max(0.58, zoom * value.magnification))
                                }
                        )
                        .background(ScoutPalette.panel.opacity(0.38))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    fullScreenControls
                    interpretationNote
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .preferredColorScheme(.dark)
    }

    private var fullScreenHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.09), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel("Close full screen map")

            VStack(alignment: .leading, spacing: 2) {
                Text("Live Signal Field")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                if let remaining = subscription.previewSecondsRemaining {
                    Text("\(scanner.devices.count) signals · preview \(remaining)s")
                        .font(.caption)
                        .foregroundStyle(ScoutPalette.amber)
                } else {
                    Text("\(scanner.devices.count) visible BLE signals")
                        .font(.caption)
                        .foregroundStyle(ScoutPalette.secondary)
                }
            }

            Spacer()

            Button {
                scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
            } label: {
                Image(systemName: scanner.isScanning ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(ScoutPalette.cyan.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScoutPalette.cyan)
            .accessibilityLabel(scanner.isScanning ? "Pause scanning" : "Resume scanning")
        }
    }

    private var fullScreenControls: some View {
        HStack(spacing: 10) {
            Button {
                zoom = max(0.58, zoom - 0.2)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Zoom out")

            Button("Fit all") {
                zoom = 0.58
            }
            .font(.subheadline.bold())
            .frame(minHeight: 44)

            Text("\(Int((effectiveZoom * 100).rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(ScoutPalette.secondary)
                .frame(minWidth: 46)

            Button {
                zoom = min(2.4, zoom + 0.2)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Zoom in")

            Spacer()

            Label("Pan or pinch", systemImage: "hand.draw")
                .font(.caption)
                .foregroundStyle(ScoutPalette.secondary)
        }
        .buttonStyle(.bordered)
        .tint(ScoutPalette.cyan)
    }

    private var interpretationNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "scope")
                .foregroundStyle(ScoutPalette.cyan)
            Text("Radius is live signal strength. Angle is visual spacing, not direction. Tap any signal to track it.")
                .font(.caption)
                .foregroundStyle(ScoutPalette.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }
}

private struct ExpandedSignalCanvas: View {
    let devices: [NearbyDevice]
    let isStale: (NearbyDevice) -> Bool
    let select: (NearbyDevice) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let usableRadius = max(0, side / 2 - 48)

            ZStack {
                SignalMapGrid()

                ForEach(devices) { device in
                    let coordinate = SignalMapLayout.coordinate(id: device.id, rssi: device.smoothedRSSI)
                    let radius = usableRadius * coordinate.normalizedRadius
                    let position = CGPoint(
                        x: center.x + CGFloat(cos(coordinate.angleRadians)) * radius,
                        y: center.y + CGFloat(sin(coordinate.angleRadians)) * radius
                    )

                    Button {
                        select(device)
                    } label: {
                        SignalMapDot(device: device, stale: isStale(device))
                            .scaleEffect(1.12)
                    }
                    .buttonStyle(.plain)
                    .position(position)
                    .animation(.easeOut(duration: 0.48), value: Int(device.smoothedRSSI.rounded()))
                    .accessibilityHint("Closes the map and tracks this device")
                }

                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 30, weight: .semibold))
                    Text("THIS PHONE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
                .foregroundStyle(ScoutPalette.background)
                .frame(width: 82, height: 82)
                .background(ScoutPalette.cyan, in: Circle())
                .shadow(color: ScoutPalette.cyan.opacity(0.42), radius: 18)
                .position(center)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("This iPhone, center of signal map")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expanded relative Bluetooth signal map with \(devices.count) devices")
    }
}

private struct SignalMapGrid: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach([0.36, 0.64, 0.92], id: \.self) { scale in
                    Circle()
                        .stroke(Color.white.opacity(scale == 0.92 ? 0.14 : 0.09), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                        .scaleEffect(scale)
                }
                Path { path in
                    path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                }
                .stroke(Color.white.opacity(0.055), lineWidth: 1)
            }
        }
        .padding(3)
        .accessibilityHidden(true)
    }
}

private struct SignalMapDot: View {
    let device: NearbyDevice
    let stale: Bool

    private var color: Color {
        if stale { return ScoutPalette.secondary }
        if device.smoothedRSSI >= -62 { return ScoutPalette.cyan }
        if device.smoothedRSSI >= -78 { return ScoutPalette.amber }
        return ScoutPalette.red
    }

    private var compactName: String {
        device.anonymousLabel
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(color.opacity(stale ? 0.18 : 0.26))
                Circle()
                    .stroke(color, lineWidth: 2)
                Image(systemName: stale ? "pause.fill" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 40, height: 40)
            .shadow(color: color.opacity(stale ? 0 : 0.25), radius: 7)

            VStack(spacing: 0) {
                Text(compactName)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text("\(Int(device.smoothedRSSI.rounded()))")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
            }
            .foregroundStyle(stale ? ScoutPalette.secondary : Color.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(ScoutPalette.background.opacity(0.82), in: Capsule())
        }
        .frame(width: 62, height: 67)
        .contentShape(Rectangle())
        .opacity(stale ? 0.55 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(device.anonymousLabel), \(Int(device.smoothedRSSI.rounded())) decibels, \(stale ? "stale" : device.strengthLabel)")
    }
}

private struct MapLegendDot: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(ScoutPalette.secondary)
    }
}

private struct DeviceRow: View {
    let device: NearbyDevice
    let isStale: Bool

    var body: some View {
        HStack(spacing: 14) {
            SignalBars(rssi: device.smoothedRSSI)
                .frame(width: 42, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(device.anonymousLabel)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Anonymous app-scoped ID \(device.shortID)")
                .font(.caption.monospaced())
                .foregroundStyle(ScoutPalette.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(device.smoothedRSSI.rounded())) dBm")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(isStale ? ScoutPalette.secondary : .white)
                Text(isStale ? "stale" : device.strengthLabel)
                    .font(.caption)
                    .foregroundStyle(isStale ? ScoutPalette.amber : ScoutPalette.cyan)
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(ScoutPalette.secondary)
        }
        .padding(16)
        .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(isStale ? 0.64 : 1)
    }
}

private struct TrackingView: View {
    @EnvironmentObject private var scanner: BluetoothScanner

    private var device: NearbyDevice? { scanner.selectedDevice }
    private var guidance: SearchGuidance { scanner.assessment?.guidance ?? .calibrating }

    private var guidanceColor: Color {
        switch guidance {
        case .warmer: return ScoutPalette.cyan
        case .colder: return ScoutPalette.red
        case .steady: return ScoutPalette.amber
        case .calibrating: return Color.white.opacity(0.82)
        case .signalLost: return ScoutPalette.amber
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(device?.anonymousLabel ?? "Anonymous BLE signal")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .lineLimit(1)
                    Text(device.map { "ID \($0.shortID)" } ?? "")
                        .font(.caption.monospaced())
                        .foregroundStyle(ScoutPalette.secondary)
                }

                SignalGauge(
                    rssi: scanner.assessment?.smoothedRSSI ?? device?.smoothedRSSI ?? -100,
                    guidance: guidance,
                    color: guidanceColor
                )

                VStack(spacing: 8) {
                    Text(guidance.title)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(guidanceColor)
                    Text(guidance.instruction)
                        .font(.body)
                        .foregroundStyle(ScoutPalette.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 330)
                }
                .animation(.easeInOut(duration: 0.25), value: guidance)

                SignalChart(samples: scanner.selectedHistory, tint: guidanceColor)
                    .frame(height: 116)
                    .padding(14)
                    .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 12) {
                    Button {
                        scanner.resetDirection()
                    } label: {
                        Label("Try a new direction", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ScoutPalette.cyan)
                    .foregroundStyle(ScoutPalette.background)

                    Button(role: .cancel) {
                        scanner.stopTracking()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Stop tracking")
                }

                Text("Best results: hold the phone the same way, move 4–6 slow steps, and wait for a trend. Your body, walls, and device orientation can change the signal.")
                    .font(.footnote)
                    .foregroundStyle(ScoutPalette.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SignalGauge: View {
    let rssi: Double
    let guidance: SearchGuidance
    let color: Color

    private var normalized: Double {
        min(1, max(0.05, (rssi + 100) / 58))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 18)
            Circle()
                .trim(from: 0, to: normalized)
                .stroke(color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.38), radius: 15)
                .animation(.spring(response: 0.55, dampingFraction: 0.8), value: normalized)
            VStack(spacing: 2) {
                Image(systemName: guidance == .warmer ? "flame.fill" : guidance == .colder ? "snowflake" : "wave.3.right")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, isActive: guidance == .warmer)
                Text("\(Int(rssi.rounded()))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("dBm · relative signal")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Signal strength \(Int(rssi.rounded())) decibels, \(guidance.title)")
    }
}

private struct SignalBars: View {
    let rssi: Double

    private var activeBars: Int {
        if rssi >= -58 { return 4 }
        if rssi >= -70 { return 3 }
        if rssi >= -84 { return 2 }
        return 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(1...4, id: \.self) { index in
                Capsule()
                    .fill(index <= activeBars ? ScoutPalette.cyan : Color.white.opacity(0.11))
                    .frame(width: 7, height: CGFloat(7 + index * 6))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct SignalChart: View {
    let samples: [SignalSample]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Smoothed trend", systemImage: "chart.xyaxis.line")
                    .font(.subheadline.bold())
                Spacer()
                Text("stronger ↑")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
            Canvas { context, size in
                guard samples.count > 1 else { return }
                let values = samples.map(\.smoothedRSSI)
                let minimum = (values.min() ?? -100) - 2
                let maximum = (values.max() ?? -40) + 2
                let span = max(8, maximum - minimum)
                var path = Path()
                for (index, value) in values.enumerated() {
                    let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let y = size.height * CGFloat(1 - ((value - minimum) / span))
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .accessibilityLabel("Recent smoothed signal trend")
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SubscriptionManager())
}
