import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.91, green: 0.33, blue: 0.12)
    static let success = Color(red: 0.19, green: 0.56, blue: 0.35)
    static let processing = Color(red: 0.22, green: 0.47, blue: 0.78)
    static let danger = Color(red: 0.78, green: 0.24, blue: 0.25)

    static let window = Color(nsColor: .windowBackgroundColor)
    static let content = Color(nsColor: .controlBackgroundColor)
    static let sidebar = Color(nsColor: .underPageBackgroundColor)
    static let surface = Color(nsColor: .textBackgroundColor)
    static let subtleSurface = Color(nsColor: .controlBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)
    static let controlBorder = Color(nsColor: .gridColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)

    static func accentSurface(for scheme: ColorScheme) -> Color {
        accent.opacity(scheme == .dark ? 0.20 : 0.085)
    }

    static func raisedShadow(for scheme: ColorScheme) -> Color {
        Color.black.opacity(scheme == .dark ? 0.20 : 0.07)
    }
}

extension View {
    func productCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(ProductCardModifier(cornerRadius: cornerRadius))
    }
}

private struct ProductCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.controlBorder.opacity(colorScheme == .dark ? 0.72 : 0.62), lineWidth: 1)
            }
            .shadow(color: AppTheme.raisedShadow(for: colorScheme), radius: 5, y: 2)
    }
}

struct ModeTint {
    let foreground: Color
    let background: Color

    static func tint(for tone: ModeTone, scheme: ColorScheme) -> ModeTint {
        switch tone {
        case .blue:
            ModeTint(foreground: .blue, background: Color.blue.opacity(scheme == .dark ? 0.20 : 0.09))
        case .orange:
            ModeTint(foreground: AppTheme.accent, background: AppTheme.accentSurface(for: scheme))
        case .violet:
            ModeTint(foreground: .purple, background: Color.purple.opacity(scheme == .dark ? 0.20 : 0.09))
        case .green:
            ModeTint(foreground: AppTheme.success, background: AppTheme.success.opacity(scheme == .dark ? 0.20 : 0.09))
        }
    }
}
