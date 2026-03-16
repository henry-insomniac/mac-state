# mac-state

`mac-state` is a native macOS menu bar system monitor focused on being lightweight, compact, and pleasant to use.

## Goals

- Native `macOS 11+` app
- `Universal 2` support for `Intel` and `Apple Silicon`
- SwiftUI for feature UI with AppKit for macOS shell integration
- Low-overhead menu bar experience
- Extensible architecture for metrics, history, alerts, widgets, and sensor helpers

## Repository layout

- [docs](/Users/Zhuanz/work-space/mac-state/docs)
  Product analysis, technical decisions, and the implementation roadmap.
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
3. Run the app and use the menu bar item to open the dashboard popover.

## Current status

This repository currently contains a working MVP foundation:

- macOS app shell with menu bar controller and popover host
- customizable menu bar indicators for CPU, memory, network, disk, and battery
- macOS Widget extension backed by an App Group snapshot shared from the main app
- live CPU, per-core CPU, memory, disk, network, battery, and running app metrics
- thermal state, battery temperature, and low-level CPU/GPU/fan sensor bridging where available
- configurable dashboard modules with persisted visibility, ordering, and default expansion behavior
- live history window with recent raw samples, 24-hour minute-level aggregates, and CSV export
- configurable local alerts for CPU, memory, battery, and disk activity
- launch-at-login control across macOS 11+, using `SMAppService` on macOS 13+ and a bundled helper on macOS 11-12
- English / Simplified Chinese language switching for the main app experience
- settings window for compact mode, language selection, and alert thresholds
- local Swift packages with tests
- project documentation and repository scaffolding

## Testing

- Run `swift test` in each package under `Packages/`
- Build the app with:

```sh
xcodebuild -project App/MacStateApp/MacStateApp.xcodeproj -target MacStateApp -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## License

No license file has been added yet. Add one before publishing releases or accepting external contributions.
