# Repository Guidelines

## Language
- Use English for all documentation and user-facing text.

## Project Structure & Module Organization
- `CountMyDays/`: main Swift/SwiftUI source.
- `CountMyDays/Views/`: UI screens and reusable view components.
- `CountMyDays/Models/`: data models (`Entry`, `EntryType`, etc.).
- `CountMyDays/Services/`: app services (day counting, import/export, notifications).
- `CountMyDays/Store/`: persistence and data store logic.
- `CountMyDays/Utilities/`: helpers, formatters, extensions.
- `CountMyDays/Assets.xcassets/` and `CountMyDays/Resources/`: assets and bundled data.
- `CountMyDays.xcodeproj/`: Xcode project metadata.

## Build, Test, and Development Commands
- Build (CLI):
  ```sh
  xcodebuild -project CountMyDays.xcodeproj -scheme CountMyDays -sdk iphonesimulator build
  ```
  Builds the app for the simulator.
- Run: open `CountMyDays.xcodeproj` in Xcode and select a simulator/device.

## Coding Style & Naming Conventions
- Swift/SwiftUI with standard 4-space indentation.
- Types and protocols: `UpperCamelCase` (e.g., `EntryStore`).
- Properties/functions: `lowerCamelCase` (e.g., `startDate`).
- Prefer SwiftUI view files grouped by feature under `Views/`.
- No lint/format tooling detected; keep formatting consistent with existing files.

## Documentation
- Keep `README.md` accurate when behavior, build steps, or features change.
- Document any data model changes or migrations.

## Testing Guidelines
- No tests currently in the repository.
- If adding tests, use XCTest and place targets under a `CountMyDaysTests/` folder.
- Name test classes `SomethingTests` and methods `testSomethingBehavior()`.

## Commit & Pull Request Guidelines
- Recent commits use short, lowercase subjects (e.g., `fix export and import`).
- Keep commit messages concise and action-oriented.
- PRs should include:
  - A brief description of the change and affected screens/flows.
  - Screenshots or screen recordings for UI changes.
  - Notes on any data model changes or migrations.

## Configuration & Data Notes
- Time zone handling is centralized in `CountMyDays/Services/DayCounter.swift`.
- Import/export formats are defined in `CountMyDays/Services/ImportService.swift` and `CountMyDays/Services/ExportService.swift`.

## Current Product Priorities

- Establish a `CountMyDaysTests` target before broad feature work.
- Prioritize deterministic coverage for time zones, daylight-saving transitions, leap days, month-end/year-end repeat rules, inclusive day counting, and archived/pinned ordering.
- Treat the exported JSON shape as a versioned compatibility contract. Imports must validate first and must not partially overwrite existing data after an error.
- Measure notification rescheduling and launch-time store loading when the dataset grows; avoid recomputing all derived day counts on unrelated view updates.
