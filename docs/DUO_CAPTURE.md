# Experimental Duo capture

The Duo workflow builds an unsigned Debug simulator candidate from its own checkout. It includes the repaired app logic and an experiment-only hinge observer. It does not produce an App Store archive or validate physical Bluetooth reception.

## Supported hinge readback

The previous readback command, `devicectl device motion hinge-angle`, is rejected by the inspected Xcode 27.1 CLI. The capture now obtains hinge observations inside the running app through Apple's public `UIHingeInteraction` API. The native diagnostic for the rejected command is [run 40706423363](https://github.com/nickvan23-lang/signal-scout/actions/runs/40706423363).

The observer requires both the `DUO_DIAGNOSTICS` compilation condition and a valid `--duo-telemetry-session <UUID>` launch argument. Its types and root-view attachment are excluded when that compilation condition is absent. The workflow explicitly records `DEBUG DUO_DIAGNOSTICS` in its source and build receipts. It also records the experimental removal of `UIRequiresFullScreen`.

The host writes an atomic request under the app's data container at `Library/Caches/SignalScout-Duo/request.json`. The request identifies the capture session and one observation request. A real UIKit callback writes `snapshot.json` with that correlation, the app process and scene, the observed angle and status, and a callback sequence and timestamp.

Only a real callback advances the observation sequence and time. Scene loss, an unavailable hinge, or an unknown hinge status invalidates the angle. A file rewrite or heartbeat never makes an old reading fresh. Retired observer generations cannot answer newer requests.

The host accepts a pose only after validating the snapshot schema, session and request identifiers, process identity and liveness, callback sequence, active scene, finite angle, and reported status. The angle must meet the existing one-degree tolerance. Display identity and orientation are checked separately. Requested angles are control inputs, never observations.

## Running and reviewing

Use the `Signal Scout Duo fold capture` workflow on the experimental branch with the matching Xcode 27.1 and iOS 27.1 Duo runner. The workflow runs portable capture regressions, records source hashes, builds the instrumented candidate, waits for simulator boot readiness within a bounded deadline, installs that candidate, and captures the poses.

The artifact preserves source/build receipts, screenshots, pose evidence, and failure diagnostics. A successful app build or installation does not itself establish a verified pose. Missing, invalid, stale, or unavailable readback fails the capture with its recorded reason.

Run the portable subprocess and snapshot checks from the repository root with:

```sh
python3 tools/test_duo_capture.py
```

## API contracts

Apple documents an initial state followed by subsequent updates for [`UIHingeInteraction.init(updateHandler:)`](https://developer.apple.com/documentation/uikit/uihingeinteraction/init(updatehandler:)). Re-enabling [`isEnabled`](https://developer.apple.com/documentation/uikit/uihingeinteraction/isenabled) provides current state when available; disabled updates are not queued. Leaving a supplying hierarchy yields a nil hinge.

[`UIHinge.angle`](https://developer.apple.com/documentation/uikit/uihinge/angle) is expressed in radians and is converted to degrees in the receipt. Apple leaves update frequency and precision to system policy, so the capture uses bounded waits, an explicit tolerance, and reported categorical status. These hinge APIs require iOS 27.1 and an SDK declaring the symbols.
