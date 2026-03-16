# Contributing

Thanks for contributing to `mac-state`.

## Ground rules

- Follow the repository rules in [AGENTS.md](/Users/Zhuanz/work-space/mac-state/AGENTS.md).
- Keep the main app compatible with `macOS 11+`.
- Preserve support for both `Intel` and `Apple Silicon` unless the project support policy changes.
- Avoid adding third-party frameworks without prior discussion.

## Development workflow

1. Read the architecture and roadmap documents in [docs](/Users/Zhuanz/work-space/mac-state/docs).
2. Make focused changes with clear scope.
3. Add or update tests when core logic changes.
4. Verify changes locally before opening a pull request.

## Local verification

Run the package tests:

```sh
cd Packages/MacStateFoundation && swift test
cd Packages/MacStateMetrics && swift test
cd Packages/MacStateStorage && swift test
cd Packages/MacStateUI && swift test
```

Build the app:

```sh
xcodebuild -project App/MacStateApp/MacStateApp.xcodeproj -scheme MacStateApp -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## Commit style

- Prefer Conventional Commits.
- Keep commits focused and descriptive.
- Examples:
  - `feat: add cpu sampler`
  - `fix: preserve popover state during settings updates`
  - `chore: bootstrap macOS app project`

## Pull requests

- Describe user-visible changes and architectural impact.
- List verification steps that were run locally.
- Call out compatibility changes that affect `macOS 11+`, `Intel`, or `Apple Silicon`.
