import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(
                    title: "Добрый день",
                    subtitle: "Новая версия работает отдельно и готова к проверке интерфейса."
                ) {
                    PrimaryActionButton(title: "Проверить индикатор", symbol: "mic") {
                        store.beginDictationPreview()
                    }
                }

                readinessCard
                    .padding(.top, 23)

                sectionHeader(
                    title: "Режимы работы",
                    detail: "Выберите, каким должен получиться текст.",
                    actionTitle: "Все режимы"
                ) {
                    store.selectedSection = .modes
                }
                .padding(.top, 24)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(store.modes.prefix(3)) { mode in
                        QuickModeCard(mode: mode, selected: mode.id == store.activeModeID) {
                            store.selectMode(mode.id)
                        }
                    }
                }
                .padding(.top, 11)

                sectionHeader(
                    title: "Недавнее",
                    detail: "Текст можно найти, исправить и скопировать повторно.",
                    actionTitle: "Открыть историю"
                ) {
                    store.selectedSection = .history
                }
                .padding(.top, 24)

                VStack(spacing: 0) {
                    ForEach(Array(store.history.prefix(3).enumerated()), id: \.element.id) { index, item in
                        RecentHistoryRow(item: item) {
                            store.selectedSection = .history
                        }
                        if index < min(2, store.history.count - 1) {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .productCard(cornerRadius: 11)
                .padding(.top, 11)

                HStack(spacing: 7) {
                    Image(systemName: "externaldrive.badge.checkmark")
                    Text("Данные этой версии хранятся отдельно: New MyDictate Dev")
                }
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(AppTheme.success)
                .padding(.top, 14)
            }
            .padding(32)
        }
        .background(AppTheme.window)
    }

    private var readinessCard: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(AppTheme.accent)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.20), lineWidth: 1)
                    .padding(-5)
                Image(systemName: "mic.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Label("Интерфейс готов", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(AppTheme.success)
                Text("Рабочий движок подключается следующим слоем")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Сейчас можно проверить всю оболочку, темы, историю, словарь и настройки.")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Divider().frame(height: 48)

            HStack(spacing: 21) {
                statusMetric(title: "Сборка", value: "Dev 0.1")
                statusMetric(title: "Хранилище", value: "Изолировано")
                statusMetric(title: "Режим", value: store.activeMode.name)
            }
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [AppTheme.subtleSurface, AppTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(AppTheme.controlBorder.opacity(colorScheme == .dark ? 0.78 : 0.60), lineWidth: 1)
        }
    }

    private func statusMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8.5))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(minWidth: 74, alignment: .leading)
    }

    private func sectionHeader(
        title: String,
        detail: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            TextActionButton(actionTitle, symbol: "arrow.right", action: action)
        }
    }
}

private struct QuickModeCard: View {
    let mode: DictationMode
    let selected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                ModeIcon(mode: mode, size: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.name)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(mode.detail)
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 77, alignment: .topLeading)
            .background(selected ? AppTheme.accentSurface(for: colorScheme) : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(selected ? AppTheme.accent.opacity(0.42) : AppTheme.controlBorder.opacity(0.65), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecentHistoryRow: View {
    let item: HistoryItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.kind.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(item.kind == .issue ? AppTheme.danger : Color.secondary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(item.preview)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 12)
                Text(item.date, format: .dateTime.hour().minute())
                    .font(.system(size: 8.5))
                    .foregroundStyle(.tertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
