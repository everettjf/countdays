import Foundation

struct TrendingCardPalette: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: [String]

    var primaryHex: String {
        colors.first ?? "#FFFFFF"
    }

    init(name: String, colors: [String]) {
        self.name = name
        self.colors = colors.map { TrendingCardPalettes.normalize($0) }
        self.id = name.replacingOccurrences(of: " ", with: "-")
    }
}

enum TrendingCardPalettes {
    static let all: [TrendingCardPalette] = [
        TrendingCardPalette(name: "Olive Garden Feast", colors: ["#606C38", "#283618", "#FEFAE0", "#DDA15E", "#BC6C25"]),
        TrendingCardPalette(name: "Pastel Dreamland Adventure", colors: ["#D9B8FF", "#B88CFF", "#9A6BFF", "#6D8DFF", "#3F6FFF"]),
        TrendingCardPalette(name: "Fiery Ocean", colors: ["#780000", "#C1121F", "#FDF0D5", "#003049", "#669BBC"]),
        TrendingCardPalette(name: "Golden Summer Fields", colors: ["#CCD5AE", "#E9EDC9", "#FEFAE0", "#FAEDCD", "#D4A373"]),
        TrendingCardPalette(name: "Black & Gold Elegance", colors: ["#000000", "#14213D", "#FCA311", "#E5E5E5", "#FFFFFF"]),
        TrendingCardPalette(name: "Refreshing Summer Fun", colors: ["#8ECAE6", "#219EBC", "#023047", "#FFB703", "#FB8500"]),
        TrendingCardPalette(name: "Ocean Breeze", colors: ["#03045E", "#0077B6", "#00B4D8", "#90E0EF", "#CAF0F8"]),
        TrendingCardPalette(name: "Fiery Palette", colors: ["#5F0F40", "#9A031E", "#FB8B24", "#E36414", "#0F4C5C"]),
        TrendingCardPalette(name: "Soft Pastels", colors: ["#E9C1FF", "#CF96FF", "#A569FF", "#774BFF", "#4234C7"]),
        TrendingCardPalette(name: "Soft Pink Delight", colors: ["#FFC3D8", "#FF93BA", "#FF659F", "#F13D7B", "#C2265C"])
    ]

    static func palette(for hex: String) -> TrendingCardPalette? {
        let normalizedHex = normalize(hex)
        return all.first { normalize($0.primaryHex) == normalizedHex }
    }

    static var defaultHex: String {
        all.first?.primaryHex ?? "#606C38"
    }

    static func randomPrimaryHex() -> String {
        (all.randomElement()?.primaryHex).map(normalize) ?? defaultHex
    }

    static func normalize(_ value: String) -> String {
        var sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        return "#" + sanitized
    }
}
