# CountMyDays

CountMyDays is a SwiftUI iOS app for tracking countdowns and cumulative day counts. Create entries for important dates, track progress over time, and keep everything tidy with pinning, archiving, and export/import.


[!Screenshot](/screenshot.png)

## Features
- Countdown and cumulative (count up) trackers.
- Repeat rules for countdown targets (weekly, monthly, yearly).
- Optional date ranges with out-of-range behavior handling.
- Time zone aware day counting.
- Pin and archive entries for better organization.
- JSON import/export for backups or migration.
- Local notifications for countdown target days.

## Requirements
- Xcode with iOS Simulator support.

## Build
```sh
xcodebuild -project CountMyDays.xcodeproj -scheme CountMyDays -sdk iphonesimulator build
```

## Run
Open `CountMyDays.xcodeproj` in Xcode and select a simulator/device.

## Import/Export
- Exported files are JSON with ISO-8601 dates.
- Import accepts the same JSON schema and validates required fields.

## Project Structure
- `CountMyDays/`: main Swift/SwiftUI source.
- `CountMyDays/Views/`: UI screens and reusable view components.
- `CountMyDays/Models/`: data models (`Entry`, `EntryType`, etc.).
- `CountMyDays/Services/`: app services (day counting, import/export, notifications).
- `CountMyDays/Store/`: persistence and data store logic.
- `CountMyDays/Utilities/`: helpers, formatters, extensions.
- `CountMyDays/Assets.xcassets/` and `CountMyDays/Resources/`: assets and bundled data.
- `CountMyDays.xcodeproj/`: Xcode project metadata.

## Contributing
- Follow the guidelines in `AGENTS.md`.
- Keep changes focused and consistent with existing code style.
- Include screenshots or screen recordings for UI changes.

## Star History
[![Star History Chart](https://api.star-history.com/svg?repos=everettjf/CountMyDays&type=Date)](https://star-history.com/#everettjf/CountMyDays&Date)
