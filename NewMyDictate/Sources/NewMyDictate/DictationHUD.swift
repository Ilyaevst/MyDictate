import SwiftUI

struct DictationHUD: View {
    @EnvironmentObject private var store: AppStore
    let state: DictationPreviewState

    private var title: String {
        switch state {
        case .idle: ""
        case .recording: "Слушаю…"
        case .processing: "Распознаю…"
        case .done: "Готово"
        }
    }

    private var detail: String {
        switch state {
        case .idle: ""
        case .recording: "Демонстрация · Esc для отмены"
        case .processing: store.activeMode.name
        case .done: "Текст подготовлен"
        }
    }

    private var color: Color {
        switch state {
        case .idle, .recording: AppTheme.accent
        case .processing: AppTheme.processing
        case .done: AppTheme.success
        }
    }

    private var symbol: String {
        switch state {
        case .idle, .recording: "stop.fill"
        case .processing: "ellipsis"
        case .done: "checkmark"
        }
    }

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 8.5))
                    .foregroundStyle(Color.white.opacity(0.60))
            }
            .frame(minWidth: 148, alignment: .leading)

            if state == .recording {
                AnimatedWave()
                    .frame(width: 105, height: 28)
            } else if state == .processing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                    .frame(width: 105)
            } else {
                Spacer().frame(width: 105)
            }

            Button {
                store.cancelDictationPreview()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(width: 27, height: 27)
                    .background(Color.white.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .frame(height: 62)
        .background(Color(nsColor: .black).opacity(0.91))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.30), radius: 24, y: 10)
        .onExitCommand {
            store.cancelDictationPreview()
        }
    }
}

private struct AnimatedWave: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.98, green: 0.50, blue: 0.30))
                    .frame(width: 3, height: animating ? CGFloat(7 + (index * 13) % 20) : CGFloat(5 + (index * 7) % 11))
                    .animation(
                        .easeInOut(duration: 0.42 + Double(index % 3) * 0.08)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.035),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}
