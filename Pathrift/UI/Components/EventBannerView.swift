import SwiftUI

struct EventBannerView: View {
    let message: String
    let color: Color

    var body: some View {
        Text(message.uppercased())
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .kerning(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(8)
            .shadow(color: color.opacity(0.3), radius: 8)
            .padding(.top, 8)
    }
}
