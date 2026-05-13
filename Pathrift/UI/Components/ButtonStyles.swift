import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PathriftButton: View {
    enum Style {
        case primary, secondary, danger
    }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .kerning(1)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .pathriftBackground
        case .secondary: return .pathriftNeonBlue
        case .danger: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .pathriftNeonBlue
        case .secondary: return .pathriftNeonBlue.opacity(0.1)
        case .danger: return .pathriftDanger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return .pathriftNeonBlue.opacity(0.5)
        case .danger: return .pathriftDanger
        }
    }
}
