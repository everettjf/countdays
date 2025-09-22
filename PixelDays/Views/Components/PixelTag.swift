import SwiftUI

struct PixelTag: View {
    let text: String
    var tint: Color = Color(hex: "#00E5FF")

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .monospaced).weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(tint, lineWidth: 2)
                    )
            )
            .foregroundStyle(tint)
    }
}

#Preview {
    PixelTag(text: "Cumulative")
        .padding()
        .background(Color(hex: "#0B0F14"))
        .previewLayout(.sizeThatFits)
}
