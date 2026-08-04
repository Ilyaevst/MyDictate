import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var model = "Whisper Small"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AppTheme.accent : AppTheme.controlBorder.opacity(0.55))
                        .frame(height: 3)
                }
                Spacer().frame(width: 145)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Group {
                switch step {
                case 0: welcomeStep
                case 1: modelStep
                case 2: isolationStep
                default: finishStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Button("Назад") {
                    step = max(0, step - 1)
                }
                .disabled(step == 0)
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Spacer()

                Button(step == 3 ? "Готово" : "Продолжить") {
                    if step == 3 {
                        dismiss()
                        store.showToast("Мастер настройки завершён")
                    } else {
                        step += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 16)
        }
        .padding(28)
        .frame(width: 520, height: 520)
        .background(AppTheme.window)
    }

    private var welcomeStep: some View {
        OnboardingStepContainer(
            symbol: "mic.fill",
            eyebrow: "ШАГ 1 ИЗ 4",
            title: "Новая версия MyDictate",
            detail: "Это отдельное приложение для поэтапной проверки нового продукта. Оно не читает настройки и историю установленного MyDictate."
        ) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(AppTheme.success)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Полностью изолировано")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Другой bundle ID, другая папка данных и другое имя процесса.")
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .productCard(cornerRadius: 10)
        }
    }

    private var modelStep: some View {
        OnboardingStepContainer(
            symbol: "gauge.with.dots.needle.50percent",
            eyebrow: "ШАГ 2 ИЗ 4",
            title: "Выберите будущую модель",
            detail: "Пока это выбор интерфейса. Загрузка и реальная диктовка появятся после утверждения оболочки."
        ) {
            VStack(spacing: 8) {
                ModelChoice(
                    title: "Whisper Small",
                    detail: "Рекомендуется · быстро · 488 МБ",
                    selected: model == "Whisper Small"
                ) { model = "Whisper Small" }
                ModelChoice(
                    title: "Whisper Large",
                    detail: "Выше точность · 1,6 ГБ",
                    selected: model == "Whisper Large"
                ) { model = "Whisper Large" }
            }
        }
    }

    private var isolationStep: some View {
        OnboardingStepContainer(
            symbol: "checkmark.shield.fill",
            eyebrow: "ШАГ 3 ИЗ 4",
            title: "Безопасная параллельная работа",
            detail: "До подключения движка dev-версия не просит микрофон и не регистрирует глобальную горячую клавишу."
        ) {
            VStack(spacing: 0) {
                IsolationRow(symbol: "app.badge", title: "Отдельное приложение", detail: "com.local.newmydictate.dev")
                Divider().padding(.leading, 47)
                IsolationRow(symbol: "externaldrive", title: "Отдельные данные", detail: "Application Support/New MyDictate Dev")
                Divider().padding(.leading, 47)
                IsolationRow(symbol: "keyboard", title: "Без конфликта клавиш", detail: "Будущее сочетание: ⌃⌥ Space")
            }
            .productCard(cornerRadius: 10)
        }
    }

    private var finishStep: some View {
        OnboardingStepContainer(
            symbol: "checkmark.circle.fill",
            eyebrow: "ШАГ 4 ИЗ 4",
            title: "Оболочка готова к просмотру",
            detail: "Переключайте темы, изменяйте размер окна, проверяйте историю, словарь, режимы и настройки."
        ) {
            Button {
                store.beginDictationPreview()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Показать индикатор диктовки")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Без доступа к микрофону — только интерфейс")
                            .font(.system(size: 8.5))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(AppTheme.accent)
                .padding(13)
                .background(AppTheme.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.30), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct OnboardingStepContainer<Content: View>: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let detail: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 60, height: 60)
                .background(AppTheme.accent.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(eyebrow)
                .font(.system(size: 8.5, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 16)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .tracking(-0.35)
                .foregroundStyle(.primary)
                .padding(.top, 6)

            Text(detail)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
                .padding(.top, 8)

            content()
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ModelChoice: View {
    let title: String
    let detail: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.tertiaryText)
            }
            .padding(10)
            .background(selected ? AppTheme.accent.opacity(0.10) : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? AppTheme.accent.opacity(0.38) : AppTheme.controlBorder.opacity(0.65), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct IsolationRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(AppTheme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 8.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.success)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
    }
}
