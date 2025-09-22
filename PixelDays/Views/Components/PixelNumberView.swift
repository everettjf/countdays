import SwiftUI

struct PixelNumberView: View {
    let value: Int
    var label: String = "Days"
    var color: Color = Color(hex: "#00E0A4")

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 54, weight: .heavy, design: .monospaced))
                .tracking(3)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 0, x: 1, y: 1)
            Text(label.uppercased())
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(color.opacity(0.9))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.6), lineWidth: 2)
                )
        )
    }
}

#Preview {
    PixelNumberView(value: 421)
        .padding()
        .background(Color(hex: "#0B0F14"))
        .previewLayout(.sizeThatFits)
}
