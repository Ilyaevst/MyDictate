import AppKit
import SwiftUI

struct HelpView: View {
    @EnvironmentObject private var store: AppStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Помощь", subtitle: "Быстро проверить настройку или найти ответ.")

                HStack(alignment: .top, spacing: 17) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 50, height: 50)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.07), radius: 7, y: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Проведём первый запуск ещё раз?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Проверим модель, изоляцию данных и демонстрационный индикатор. Настройки не будут сброшены.")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                        PrimaryActionButton(title: "Открыть мастер настройки", symbol: "arrow.right") {
                            store.showOnboarding = true
                        }
                        .padding(.top, 6)
                    }
                    Spacer()
                }
                .padding(22)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent.opacity(0.11), AppTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.62), lineWidth: 1)
                }
                .padding(.top, 22)

                LazyVGrid(columns: columns, spacing: 10) {
                    HelpActionCard(
                        symbol: "mic",
                        title: "Проверить индикатор",
                        detail: "Запустить безопасную демонстрацию"
                    ) {
                        store.beginDictationPreview()
                    }

                    HelpActionCard(
                        symbol: "waveform.path.ecg",
                        title: "Диагностика",
                        detail: "Проверить оболочку и хранилище"
                    ) {
                        store.showToast("Оболочка и изолированное хранилище работают")
                    }

                    HelpActionCard(
                        symbol: "checkmark.shield",
                        title: "Разрешения macOS",
                        detail: "Понадобятся при подключении диктовки"
                    ) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                    HelpActionCard(
                        symbol: "folder",
                        title: "Открыть данные",
                        detail: "Только папка New MyDictate Dev"
                    ) {
                        NSWorkspace.shared.open(store.dataDirectory)
                    }
                }
                .padding(.top, 15)

                HStack(spacing: 8) {
                    Text("New MyDictate 0.1.0")
                    Circle().frame(width: 3, height: 3)
                    Text("Bundle: com.local.newmydictate.dev")
                    Circle().frame(width: 3, height: 3)
                    Text("Основной MyDictate не изменяется")
                }
                .font(.system(size: 8.5))
                .foregroundStyle(.tertiary)
                .padding(.top, 20)
            }
            .padding(30)
        }
        .background(AppTheme.window)
    }
}

private struct HelpActionCard: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 76)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .productCard(cornerRadius: 11)
    }
}
