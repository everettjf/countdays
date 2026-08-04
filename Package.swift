// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CountMyDaysCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CountMyDaysCore", targets: ["CountMyDaysCore"]),
    ],
    targets: [
        .target(
            name: "CountMyDaysCore",
            path: "CountMyDays",
            exclude: [
                "Assets.xcassets",
                "CountMyDaysApp.swift",
                "Info.plist",
                "Resources",
                "Services/ExportService.swift",
                "Services/ImportService.swift",
                "Services/NotificationService.swift",
                "Store",
                "Utilities/AppReviewManager.swift",
                "Utilities/Bundle+AppInfo.swift",
                "Utilities/Color+Hex.swift",
                "Utilities/DateFormatters.swift",
                "Utilities/DynamicTypeSize+Helpers.swift",
                "Utilities/TimeZone+List.swift",
                "Views",
            ],
            sources: [
                "Models/Entry.swift",
                "Models/EntryDraft.swift",
                "Models/EntrySnapshot.swift",
                "Models/EntryType.swift",
                "Models/OutOfRangeBehavior.swift",
                "Models/RepeatRule.swift",
                "Services/DayCounter.swift",
                "Utilities/TrendingCardPalettes.swift",
            ]
        ),
        .testTarget(
            name: "CountMyDaysCoreTests",
            dependencies: ["CountMyDaysCore"],
            path: "Tests/CountMyDaysCoreTests"
        ),
    ]
)
