# Changelog

## 1.1.0 — 2026-10-26 (build 8)

- Publish Developer ID signed and Apple-notarized DMG and ZIP for direct distribution.
- Redesign the bilingual product homepage with a real notch-panel preview and a single primary download.

- Link the published privacy/support pages from the app and include the confirmed copyright owner.

- Throttle Widget snapshot writes and reload requests, recheck removed widgets, and mark stale snapshots instead of showing old metrics as live.
- Adopt modern widget container backgrounds while preserving macOS 11 compatibility.
- Serialize metric refreshes and verify history across independent sandbox process launches.

- Add a separate sandboxed Mac App Store scheme, privacy manifests, in-app privacy/support and local policy/support page drafts.
- Remove undocumented SMC and cross-process disk I/O sampling; unavailable throughput remains absent in history, aggregates and CSV rather than becoming zero.
- Use a team-prefixed shared group for Store builds and show a waiting state when Widget data is missing.
- Add clear-history control with confirmation; surface deletion failures.

- Replace the default status-bar item with a notch/top-edge panel: hover preview, pinned expansion, Escape and outside-click dismissal.
- Keep full dashboard, history, and settings in separate windows; reopen the app to recover its panel.
- Prefer the notched display, relocate after display changes/wake, and offer optional full-screen presentation.
- Configure personal Apple Development signing for all targets, preserve bundle and App Group identifiers, and require signed/public-notarized packaging paths.
- Supply complete Widget bundle metadata and use native Xcode copy/sign phases so nested updates are embedded correctly.
- Explicitly build and verify Universal 2 app/helper/Widget binaries; retain macOS 11 support.


## 1.0.3 - 2026-03-30

### Fixed

- Stopped the app from eagerly touching the shared widget App Group container at launch, which could repeatedly trigger the macOS prompt about accessing data from other apps on machines that had not configured the widget.

### Changed

- Bumped the app and packaging metadata to version 1.0.3.

## 1.0.2 - 2026-03-17

### Fixed

- Refined memory usage reporting so reclaimable cache no longer inflates the percentage toward 100% when the machine is still responsive.

### Changed

- Updated the release packaging defaults, website copy, download links, and release assets for version 1.0.2.
