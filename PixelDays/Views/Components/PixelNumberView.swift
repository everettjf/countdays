import SwiftUI

struct PixelNumberView: View {
    let value: Int
    var label: String = "Days"
    var color: Color = Color(hex: "#00E0A4")

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .foregroundColor(Color(.label))
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white.opacity(0.98))
            .overlay(
                LinearGradient(colors: [color.opacity(0.35), color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(color.opacity(0.65), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) { pixelCorner(x: -4, y: -4) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 4, y: 4) }
            .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 3)
    }

    private func pixelCorner(x: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .offset(x: x, y: y)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelNumberView(value: 421)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
