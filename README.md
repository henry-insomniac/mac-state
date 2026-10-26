# mac-state

`mac-state` is a native macOS notch and top-edge system monitor focused on being lightweight, compact, and pleasant to use.

[Download mac-state 1.1.0 for Mac](https://github.com/henry-insomniac/mac-state/releases/download/v1.1.0/mac-state-1.1.0-build-8-developer-id.dmg) · [Website](https://henry-insomniac.github.io/mac-state/) · [Release notes & ZIP](https://github.com/henry-insomniac/mac-state/releases/tag/v1.1.0)

Free and open source. Developer ID signed and notarized by Apple. Open the DMG and drag the app into Applications. macOS 11+, Intel and Apple Silicon.

## Goals

- Native `macOS 11+` app
- `Universal 2` support for `Intel` and `Apple Silicon`
- SwiftUI for feature UI with AppKit for macOS shell integration
- Low-overhead notch / top-edge experience
- Extensible architecture for metrics, history, alerts, widgets, and sensor helpers

## Repository layout

- [docs](docs)
  Product analysis, technical decisions, and the implementation roadmap.
- [docs/branding](docs/branding)
  Logo source files, preview exports, and macOS icon bundle output.
- `App/MacStateApp`
  Native macOS application target and shell code.
- `Packages/MacStateFoundation`
  Platform and compatibility primitives.
- `Packages/MacStateMetrics`
  Metrics domain models and sampler contracts.
- `Packages/MacStateStorage`
  Persistence primitives and settings storage.
- `Packages/MacStateUI`
  Reusable SwiftUI components and theme tokens.

## Requirements

- Xcode `26.2` or later
- Swift `6.2` or later
- macOS `11.0` SDK deployment target for the app

## Getting started

1. Open `MacState.xcworkspace` in Xcode.
2. Build the `MacStateApp` target.
3. Run the app and hover over the small handle below the camera housing (or at the top center on other displays). Click to pin the panel; use Details for the full dashboard.
4. Open `docs/index.html` through GitHub Pages or any local static server to preview the product site.

## Current status

This repository currently contains a working MVP foundation:

- macOS app shell with a nonactivating notch panel; no status-bar item is created
- hover preview, click-to-expand, Escape / outside-click dismissal, and independent dashboard/history/settings windows
- built-in notched display preferred, with top-center fallback and display-change/wake repositioning
- optional full-screen visibility (off by default)
- macOS Widget extension backed by an App Group snapshot shared from the main app
- live CPU, per-core CPU, memory, disk, network, battery, and running app metrics
- public macOS thermal state; temperature/fan telemetry and cross-process disk throughput are unavailable
- configurable dashboard modules with persisted visibility, ordering, and default expansion behavior
- live history window with recent raw samples, 24-hour minute-level aggregates, CSV export and clear-history control
- configurable local alerts for CPU, memory, and battery
- launch-at-login control across macOS 11+, using `SMAppService` on macOS 13+ and a bundled helper on macOS 11-12
- English / Simplified Chinese language switching for the main app experience
- settings window for compact mode, language selection, and alert thresholds
- local Swift packages with tests
- project documentation and repository scaffolding

## Testing

- Run `swift test` in each package under `Packages/`
- Build the app with:

```sh
xcodebuild -workspace MacState.xcworkspace -scheme MacStateApp -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## Packaging

- The project uses Apple development team `662TJCCT5J`, with automatic signing for the app, Widget, and login helper. Sign into the appropriate account in Xcode first.
- `MACSTATE_SIGNING_MODE=development scripts/package-release.sh 1.1.0` builds and verifies a Universal 2 development-signed ZIP for local use. It is not a notarized public release.
- Public distribution defaults to Developer ID. Set `MACSTATE_SIGNING_IDENTITY` to your Developer ID Application identity and `MACSTATE_NOTARY_PROFILE` to an existing notarytool Keychain profile, then run `scripts/package-release.sh 1.1.0`.
- Optionally set `MACSTATE_INSTALLER_IDENTITY` to a Developer ID Installer identity to also produce a signed, notarized PKG. No unsigned installer is emitted.
- Outputs and SHA-256 checksums are under `dist/release-<version>-<mode>/`. The script validates nested signatures, Team ID, and both architectures, and requires successful notarization/stapling for public distribution.
- See [notch and signing notes](docs/notch-and-signing.md) for behavior, compatibility, and verification boundaries.

## DMG packaging

`scripts/package-dmg.sh /absolute/path/MacStateApp.app development` creates a clearly labelled development DMG with an Applications shortcut and installation notes. It preserves the app signature and checks nested signatures and Universal 2 binaries. Development signing is not suitable for general public distribution.

For public distribution, supply an already Developer ID-signed, hardened-runtime app, set `MACSTATE_SIGNING_IDENTITY` and `MACSTATE_NOTARY_PROFILE`, then run `scripts/package-dmg.sh /absolute/path/MacStateApp.app developer-id`. The script signs, notarizes, staples and assesses the disk image before producing the final file. Outputs and SHA-256 checksums are in `dist/dmg/`; an existing output is never overwritten. This route does not require Mac App Store submission, but does require Developer ID signing credentials.

## Mac App Store preparation

Use the shared `MacStateStore` scheme. `StoreDebug` and `StoreRelease` enable App Sandbox for the main app, Widget and login helper. Main app and Widget share `662TJCCT5J.mac-state`; the other configurations retain their original group. Build 6 includes throttled Widget delivery, stale-data handling, privacy manifests and in-app privacy/support information.

`scripts/archive-app-store.sh` creates an archive using Xcode automatic signing. App Store export re-signs it for distribution using `docs/app-store/ExportOptions.plist`. A development-signed archive is not an upload-ready product.

See [App Store readiness and evidence](docs/app-store/readiness.md), [privacy policy draft](docs/app-store/privacy.html), and [support page draft](docs/app-store/support.html). Public URLs, distribution signing and the remaining device acceptance checks are required before submission.

## License

MIT. See [LICENSE](/Users/Zhuanz/work-space/mac-state/LICENSE).
