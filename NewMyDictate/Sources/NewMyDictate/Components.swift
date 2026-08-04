import SwiftUI

struct ScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: () -> Trailing

    init(title: String, subtitle: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.55)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 20)
            trailing()
        }
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 13)
                .frame(height: 34)
                .foregroundStyle(.white)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: AppTheme.accent.opacity(0.22), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let symbol: String?
    let action: () -> Void

    init(_ title: String, symbol: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
            }
            .font(.system(size: 10.5, weight: .semibold))
            .padding(.horizontal, 12)
            .frame(height: 33)
            .foregroundStyle(.primary)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.controlBorder.opacity(0.76), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TextActionButton: View {
    let title: String
    let symbol: String?
    let action: () -> Void

    init(_ title: String, symbol: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                if let symbol {
                    Image(systemName: symbol)
                }
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppTheme.accent)
        }
        .buttonStyle(.plain)
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 10.5))
                .foregroundStyle(.primary)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(AppTheme.subtleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.controlBorder.opacity(0.70), lineWidth: 1)
        }
    }
}

struct ModeIcon: View {
    let mode: DictationMode
    var size: CGFloat = 34

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let tint = ModeTint.tint(for: mode.tone, scheme: colorScheme)
        Image(systemName: mode.symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(tint.foreground)
            .frame(width: size, height: size)
            .background(tint.background)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WaveformView: View {
    var color: Color = AppTheme.accent
    var barCount = 36
    var activeFraction: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 2
            let width = max(1, (proxy.size.width - CGFloat(barCount - 1) * spacing) / CGFloat(barCount))
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        index: index,
                        count: barCount,
                        width: width,
                        activeFraction: activeFraction,
                        color: color
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

private struct WaveformBar: View {
    let index: Int
    let count: Int
    let width: CGFloat
    let activeFraction: Double
    let color: Color

    private var normalizedPosition: Double {
        Double(index) / Double(max(1, count - 1))
    }

    private var barHeight: CGFloat {
        CGFloat(7 + ((index * 17 + index * index * 3) % 23))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(normalizedPosition <= activeFraction ? color : AppTheme.tertiaryText.opacity(0.26))
            .frame(width: width, height: barHeight)
    }
}

struct SettingsRow<Control: View>: View {
    let symbol: String
    let title: String
    let detail: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(AppTheme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 8.5))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            control()
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 63)
    }
}

struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .productCard(cornerRadius: 11)
    }
}

struct RowDivider: View {
    var leading: CGFloat = 53

    var body: some View {
        Divider().padding(.leading, leading)
    }
}
