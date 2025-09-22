import SwiftUI

struct PixelTag: View {
    let text: String
    var tint: Color = Color(hex: "#00E5FF")

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .kerning(1.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(Color(.label))
            .background(tagBackground)
    }

    private var tagBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white.opacity(0.95))
            .overlay(
                LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.55), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) { pixelSquare(x: -3, y: -3) }
            .overlay(alignment: .bottomTrailing) { pixelSquare(x: 3, y: 3) }
            .shadow(color: tint.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private func pixelSquare(x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(tint)
            .frame(width: 8, height: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
            )
            .offset(x: x, y: y)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelTag(text: "Cumulative")
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
