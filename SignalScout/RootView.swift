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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScoutFeatureView()
            .transaction { if reduceMotion { $0.disablesAnimations = true } }
    }
}

private struct ScoutFeatureView: View {
    @StateObject private var scanner = BluetoothScanner()
#if DEBUG
    @State private var videoPhase = 0
#endif

    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SignalScoutVideoMode") {
            Group {
                if videoPhase == 1 {
                    FullScreenSignalMap().environmentObject(scanner)
                } else {
                    navigationContent
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("SIMULATED SIGNALS · APP DEMONSTRATION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(ScoutPalette.cyan)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(ScoutPalette.background)
            }
            .task {
                try? await Task.sleep(for: .seconds(9))
                guard !Task.isCancelled else { return }
                videoPhase = 1
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                if let device = scanner.devices.first(where: { $0.id.uuidString.hasPrefix("0001") }) {
                    scanner.select(device)
                }
                videoPhase = 2
            }
        } else if ProcessInfo.processInfo.arguments.contains("-SignalScoutFullScreenScreenshotMode") {
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
    @State private var presentation: ScannerPresentation = .list
    @State private var isShowingFullScreenMap = false
    @State private var isShowingHelp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                header
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
                        isScanning: scanner.isScanning,
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
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingHelp) { SearchHelpView() }
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
                    Toggle("Haptics for this session", isOn: $scanner.hapticsEnabled)
                    Button("How to search") { isShowingHelp = true }
                    Divider()
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
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
            Text("Find your signal")
                .padding(.trailing, 44)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("Choose your accessory by its Bluetooth name and advertised manufacturer, then compare its signal.")
                .font(.subheadline)
                .foregroundStyle(ScoutPalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .overlay(alignment: .topTrailing) {
            Button { isShowingHelp = true } label: { Image(systemName: "questionmark.circle").frame(width: 44, height: 44) }
                .accessibilityLabel("How to search")
                .offset(y: -12)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((scanner.availability == .ready ? ScoutPalette.cyan : ScoutPalette.amber).opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: scanner.isScanning ? "dot.radiowaves.left.and.right" : "pause.fill")
                    .foregroundStyle(scanner.availability == .ready ? ScoutPalette.cyan : ScoutPalette.amber)
                    .symbolEffect(.pulse, isActive: scanner.isScanning && !reduceMotion)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(scanner.availability.message)
                    .font(.headline)
                Text(scanner.isScanning ? "\(scanner.devices.filter { !scanner.isStale($0) }.count) recent signals · tap one to compare" : (scanner.availability == .ready ? "No new readings while paused" : "Waiting for Bluetooth access"))
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
            Spacer()
            if scanner.availability == .ready {
                Button { scanner.isScanning ? scanner.stopScanning() : scanner.startScanning() } label: {
                    Image(systemName: scanner.isScanning ? "pause.fill" : "play.fill")
                        .frame(width: 44, height: 44)
                        .background(ScoutPalette.cyan.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(ScoutPalette.cyan)
                .accessibilityLabel(scanner.isScanning ? "Pause scanning" : "Resume scanning")
            }
        }
        .padding(16)
        .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            if scanner.isScanning {
                ProgressView().tint(ScoutPalette.cyan).scaleEffect(1.15)
            } else {
                Image(systemName: scanner.availability == .unauthorized ? "lock.shield" : "antenna.radiowaves.left.and.right.slash")
                    .font(.largeTitle)
                    .foregroundStyle(ScoutPalette.amber)
            }
            Text(scanner.isScanning ? "Listening nearby…" : (scanner.availability == .ready ? "Scanning paused" : scanner.availability.message))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(emptyStateDetail)
                .font(.subheadline)
                .foregroundStyle(ScoutPalette.secondary)
                .multilineTextAlignment(.center)
            if scanner.availability == .unauthorized {
                Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                    .buttonStyle(.borderedProminent)
                    .tint(ScoutPalette.cyan)
                    .frame(minHeight: 44)
            } else if scanner.availability == .ready && !scanner.isScanning {
                Button("Resume scanning", action: scanner.startScanning)
                    .buttonStyle(.borderedProminent)
                    .tint(ScoutPalette.cyan)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 24)
        .background(ScoutPalette.panel.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyStateDetail: String {
        switch scanner.availability {
        case .unauthorized:
            return "Enable Bluetooth access for Signal Scout in Settings, then return here. No location permission is needed."
        case .poweredOff:
            return "Turn on Bluetooth in Settings to listen for nearby advertising accessories."
        case .unsupported:
            return "Scanning needs Bluetooth Low Energy hardware. Use a compatible physical iPhone to find nearby signals."
        case .starting, .resetting:
            return "The scanner will be ready when Bluetooth finishes starting."
        case .ready:
            return scanner.isScanning
                ? "Wake an accessory you own and bring it close. Only actively advertising Bluetooth Low Energy devices can appear; sleeping devices and closed charging cases may stay silent."
                : "Resume when you are ready to look for an accessory. No new signal readings are collected while paused."
        }
    }

    private var limitations: some View {
        Label {
            Text("Some accessories do not broadcast a name or manufacturer. Signal strength is approximate, not a measured distance or direction.")
        } icon: {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(ScoutPalette.cyan)
        }
        .font(.footnote)
        .foregroundStyle(ScoutPalette.secondary)
        .padding(.top, 6)
    }
}

private struct LiveSignalMap: View {
    let devices: [NearbyDevice]
    let isScanning: Bool
    let isStale: (NearbyDevice) -> Bool
    let select: (NearbyDevice) -> Void
    let expand: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live signal field")
                        .font(.headline)
                    Text("Center = stronger · angles are not directions")
                        .font(.caption)
                        .foregroundStyle(ScoutPalette.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Label(isScanning ? "Live" : "Paused", systemImage: isScanning ? "circle.fill" : "pause.circle.fill")
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
                        let radius = SignalMapLayout.displayRadius(for: device.smoothedRSSI, availableRadius: usableRadius, centerClearance: 96)
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
                        if scanner.isScanning {
                            ProgressView().tint(ScoutPalette.cyan)
                        } else {
                            Image(systemName: "pause.circle").font(.largeTitle).foregroundStyle(ScoutPalette.amber)
                        }
                        Text(scanner.isScanning ? "Listening for Bluetooth signals…" : (scanner.availability == .ready ? "Scanning paused" : scanner.availability.message))
                            .font(.headline)
                        Text(scanner.isScanning ? "Advertising accessories will appear as they are discovered." : "Resume when Bluetooth is ready to receive new readings.")
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
                Text("\(scanner.devices.count) visible BLE signals")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
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
                    let radius = SignalMapLayout.displayRadius(for: device.smoothedRSSI, availableRadius: usableRadius, centerClearance: 108)
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
        device.displayName
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
                    .lineLimit(2)
                Text("\(Int(device.smoothedRSSI.rounded()))")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
            }
            .foregroundStyle(stale ? ScoutPalette.secondary : Color.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(ScoutPalette.background.opacity(0.82), in: Capsule())
        }
        .frame(width: 94, height: 80)
        .contentShape(Rectangle())
        .opacity(stale ? 0.55 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(device.displayName), \(Int(device.smoothedRSSI.rounded())) decibels, \(stale ? "stale" : device.strengthLabel)")
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
                Text(device.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(device.manufacturerName)
                    .font(.caption).foregroundStyle(ScoutPalette.secondary).lineLimit(2)
                Text(device.freshnessLabel())
                .font(.caption.monospaced())
                .foregroundStyle(ScoutPalette.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(device.smoothedRSSI.rounded())) dBm")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(isStale ? ScoutPalette.secondary : .white)
                Text(isStale ? "No recent signal" : device.strengthLabel)
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
    @State private var isShowingHelp = false

    private var device: NearbyDevice? { scanner.selectedDevice }
    private var status: TrackingStatus {
        TrackingStatus(availability: scanner.availability, isScanning: scanner.isScanning,
                       lastSeen: device?.lastSeen, assessment: scanner.assessment)
    }
    private var guidanceColor: Color {
        guard status.isLive else { return ScoutPalette.amber }
        switch status.guidance {
        case .warmer: return ScoutPalette.cyan
        case .colder: return ScoutPalette.red
        case .steady: return ScoutPalette.amber
        case .calibrating: return Color.white.opacity(0.82)
        case .signalLost: return ScoutPalette.amber
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 5) {
                    Text(device?.displayName ?? "Nearby device")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(device?.manufacturerName ?? "Manufacturer not advertised")
                        .font(.subheadline).foregroundStyle(ScoutPalette.secondary)
                    Text(device?.freshnessLabel() ?? "Waiting for a reading")
                        .font(.caption).foregroundStyle(ScoutPalette.secondary)
                }
                VStack(spacing: 7) {
                    Text(status.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(guidanceColor)
                    Text(status.instruction).font(.subheadline)
                        .foregroundStyle(ScoutPalette.secondary)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
                SignalGauge(rssi: scanner.assessment?.smoothedRSSI ?? device?.smoothedRSSI ?? -100,
                            guidance: status.guidance, color: guidanceColor, isLive: status.isLive)
                SignalChart(samples: scanner.selectedHistory, tint: guidanceColor)
                    .frame(height: 100).padding(14)
                    .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 20))
                Label("Compare a few slow steps at a time. Stronger does not guarantee closer.", systemImage: "figure.walk")
                    .font(.footnote).foregroundStyle(ScoutPalette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18)
        }
        .safeAreaInset(edge: .bottom) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { trackingControls }
                VStack(spacing: 8) { trackingControls }
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(ScoutPalette.background)
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("Compare signal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { scanner.stopTracking() } label: { Label("Signals", systemImage: "chevron.left") }
                    .frame(minHeight: 44).accessibilityLabel("Stop tracking")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingHelp = true } label: { Image(systemName: "questionmark.circle").frame(width: 44, height: 44) }
                    .accessibilityLabel("How to search")
            }
        }
        .sheet(isPresented: $isShowingHelp) { SearchHelpView() }
    }

    @ViewBuilder private var trackingControls: some View {
        Button { scanner.resetDirection() } label: {
            Label("Reset comparison", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.borderedProminent).tint(ScoutPalette.cyan)
        .foregroundStyle(ScoutPalette.background)
        .disabled(!scanner.isScanning || scanner.availability != .ready)
        Button { scanner.isScanning ? scanner.stopScanning() : scanner.startScanning() } label: {
            Label(scanner.isScanning ? "Pause" : "Resume", systemImage: scanner.isScanning ? "pause.fill" : "play.fill")
                .frame(minWidth: 70, minHeight: 48)
        }
        .buttonStyle(.bordered).tint(ScoutPalette.cyan)
        .disabled(scanner.availability != .ready)
        .accessibilityLabel(scanner.isScanning ? "Pause scanning" : "Resume scanning")
    }
}

private struct SignalGauge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let rssi: Double
    let guidance: SearchGuidance
    let color: Color
    var isLive = true

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
                    .symbolEffect(.pulse, isActive: guidance == .warmer && isLive && !reduceMotion)
                Text("\(Int(rssi.rounded()))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(isLive ? "dBm · relative strength" : "dBm · last reading")
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Signal strength \(Int(rssi.rounded())) decibels, \(isLive ? guidance.title : "last reading, not live")")
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
            .accessibilityLabel("Recent signal readings")
            .accessibilityValue(samples.last.map { "\(samples.count) samples. Latest smoothed value \(Int($0.smoothedRSSI.rounded())) dBm." } ?? "Waiting for signal samples")
            if samples.count < 2 {
                Text("The chart appears after a few readings.").font(.caption).foregroundStyle(ScoutPalette.secondary)
            }
        }
    }
}

#Preview {
    RootView()
}
