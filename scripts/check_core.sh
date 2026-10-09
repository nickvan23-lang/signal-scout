#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d /tmp/SignalScout-core-checks.XXXXXX)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/Checks.app/Contents/MacOS" "$work/Checks.app/Contents/Resources"
cp "$root/SignalScout/BluetoothCompanyIdentifiers.json" "$work/Checks.app/Contents/Resources/"
cat > "$work/Checks.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>Checks</string><key>CFBundleIdentifier</key><string>com.nicholas.signalscout.corechecks</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>
PLIST
cp "$root/scripts/core_checks.swift" "$work/main.swift"
xcrun swiftc "$root/SignalScout/DeviceIdentity.swift" "$root/SignalScout/SignalModels.swift" "$root/SignalScout/SignalAnalysis.swift" "$root/SignalScout/SignalMapLayout.swift" "$root/SignalScout/TrackingStatus.swift" "$work/main.swift" -o "$work/Checks.app/Contents/MacOS/Checks"
"$work/Checks.app/Contents/MacOS/Checks"
