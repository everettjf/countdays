import SwiftUI

struct PixelNumberView: View {
    let value: Int
    var label: String = "Days"
    var color: Color = Color(hex: "#00E0A4")

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundColor(Color(.label))
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.95))
            .overlay(
                LinearGradient(colors: [color.opacity(0.18), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) { pixelCorner(x: -4, y: -4) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 4, y: 4) }
            .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func pixelCorner(x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 0.8)
            )
            .offset(x: x, y: y)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelNumberView(value: 421)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
