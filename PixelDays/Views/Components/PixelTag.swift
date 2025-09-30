import SwiftUI

struct PixelTag: View {
    let text: String
    var tint: Color = Color(hex: "#00E5FF")

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .kerning(1.3)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .foregroundColor(textColor)
            .background(tagBackground)
    }

    private var tagBackground: some View {
        Capsule(style: .continuous)
            .fill(backgroundGradient)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderGradient, lineWidth: 1.1)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(highlightGradient, lineWidth: 0.9)
                    .blur(radius: 0.6)
                    .opacity(0.55)
            )
            .shadow(color: tint.opacity(0.12), radius: 8, x: 0, y: 3)
    }

    private var textColor: Color {
        Color.black.opacity(0.82)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.28),
                tint.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.55),
                tint.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.4),
                tint.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelTag(text: "Cumulative")
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
