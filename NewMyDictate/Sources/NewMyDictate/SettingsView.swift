import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedSection: SettingsSection = .general

    @AppStorage("appearance") private var appearance = AppearancePreference.system.rawValue
    @AppStorage("interfaceLanguage") private var interfaceLanguage = "Русский"
    @AppStorage("speechModel") private var speechModel = "Whisper Small"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("microphone") private var microphone = "Системный"
    @AppStorage("recognitionLanguages") private var recognitionLanguages = "RU + EN"
    @AppStorage("autoPaste") private var autoPaste = true
    @AppStorage("pasteSuffix") private var pasteSuffix = "Пробел"
    @AppStorage("sounds") private var sounds = true
    @AppStorage("waveform") private var waveform = true
    @AppStorage("indicatorPosition") private var indicatorPosition = "Снизу"
    @AppStorage("resultDuration") private var resultDuration = "1,5 сек"
    @AppStorage("saveAudio") private var saveAudio = true
    @AppStorage("retention") private var retention = "7 дней"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                title: "Настройки",
                subtitle: "Изменения сохраняются сразу. Перезапуск потребуется только для модели."
            ) {
                Label("Все изменения сохранены", systemImage: "checkmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.success)
            }
            .padding(.horizontal, 30)
            .padding(.top, 28)

            HStack(alignment: .top, spacing: 22) {
                settingsNavigation
                    .frame(width: 185)

                Divider()

                ScrollView {
                    settingsContent
                        .frame(maxWidth: 650, alignment: .leading)
                        .padding(.trailing, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 30)
            .padding(.top, 21)
            .padding(.bottom, 25)
        }
        .background(AppTheme.window)
    }

    private var settingsNavigation: some View {
        VStack(spacing: 3) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: section.symbol)
                            .frame(width: 17)
                        Text(section.title)
                        Spacer()
                        if selectedSection == section {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                    }
                    .font(.system(size: 10.5, weight: selectedSection == section ? .semibold : .medium))
                    .foregroundStyle(selectedSection == section ? AppTheme.accent : Color.secondary)
                    .padding(.horizontal, 10)
                    .frame(height: 38)
                    .background(selectedSection == section ? AppTheme.accent.opacity(0.10) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            switch selectedSection {
            case .general:
                sectionTitle("Основные", "Поведение приложения, язык и оформление.")
                generalSettings
            case .dictation:
                sectionTitle("Диктовка", "Как записывать, распознавать и вставлять текст.")
                dictationSettings
            case .shortcuts:
                sectionTitle("Клавиши", "Сочетания будут независимы от установленного MyDictate.")
                shortcutSettings
            case .feedback:
                sectionTitle("Звуки и индикатор", "Обратная связь во время диктовки.")
                feedbackSettings
            case .storage:
                sectionTitle("Хранение", "История, аудио и локальные данные dev-версии.")
                storageSettings
            case .advanced:
                sectionTitle("Дополнительно", "Диагностика и параметры разработки.")
                advancedSettings
            }
        }
    }

    private func sectionTitle(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text(detail)
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 11) {
            SettingsGroup {
                SettingsRow(symbol: "globe", title: "Язык интерфейса", detail: "Язык меню и настроек") {
                    Picker("", selection: $interfaceLanguage) {
                        Text("Русский").tag("Русский")
                        Text("English").tag("English")
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                RowDivider()
                SettingsRow(symbol: "circle.lefthalf.filled", title: "Оформление", detail: "Системная, светлая или тёмная тема") {
                    Picker("", selection: $appearance) {
                        ForEach(AppearancePreference.allCases) { item in
                            Text(item.title).tag(item.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 145)
                }
                RowDivider()
                SettingsRow(symbol: "waveform.badge.mic", title: "Модель распознавания", detail: "Движок будет подключён после утверждения интерфейса") {
                    Picker("", selection: $speechModel) {
                        Text("Whisper Small").tag("Whisper Small")
                        Text("Whisper Large").tag("Whisper Large")
                        Text("Parakeet TDT").tag("Parakeet TDT")
                    }
                    .labelsHidden()
                    .frame(width: 145)
                }
                RowDivider()
                SettingsRow(symbol: "power", title: "Запускать при входе", detail: "Пока выключено для безопасной dev-сборки") {
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                        .disabled(true)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Смена модели применится после перезапуска службы")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Остальные параметры применяются без перезапуска.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 8.5))
            .foregroundStyle(AppTheme.processing)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.processing.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var dictationSettings: some View {
        SettingsGroup {
            SettingsRow(symbol: "mic", title: "Микрофон", detail: "Устройство записи по умолчанию") {
                Picker("", selection: $microphone) {
                    Text("Системный").tag("Системный")
                    Text("MacBook Microphone").tag("MacBook Microphone")
                }
                .labelsHidden()
                .frame(width: 150)
            }
            RowDivider()
            SettingsRow(symbol: "character.bubble", title: "Языки распознавания", detail: "Автоматически определять русский и английский") {
                Picker("", selection: $recognitionLanguages) {
                    Text("RU + EN").tag("RU + EN")
                    Text("Русский").tag("Русский")
                    Text("English").tag("English")
                }
                .labelsHidden()
                .frame(width: 120)
            }
            RowDivider()
            SettingsRow(symbol: "doc.on.clipboard", title: "Вставлять результат", detail: "Автоматически вставлять текст в активное поле") {
                Toggle("", isOn: $autoPaste)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(AppTheme.accent)
            }
            RowDivider()
            SettingsRow(symbol: "text.append", title: "После вставки", detail: "Что добавить после продиктованного фрагмента") {
                Picker("", selection: $pasteSuffix) {
                    Text("Пробел").tag("Пробел")
                    Text("Ничего").tag("Ничего")
                    Text("Новая строка").tag("Новая строка")
                }
                .labelsHidden()
                .frame(width: 120)
            }
        }
    }

    private var shortcutSettings: some View {
        VStack(alignment: .leading, spacing: 11) {
            VStack(spacing: 0) {
                ShortcutRow(title: "Начать или закончить диктовку", detail: "Отдельное сочетание dev-версии", keys: "⌃⌥ Space")
                RowDivider(leading: 13)
                ShortcutRow(title: "Удерживать для разговора", detail: "Push-to-talk", keys: "⌃⌥ Space")
                RowDivider(leading: 13)
                ShortcutRow(title: "Отменить запись", detail: "Не вставлять результат", keys: "Esc")
                RowDivider(leading: 13)
                ShortcutRow(title: "Скопировать последний текст", detail: "Восстановить последнюю диктовку", keys: "⌃⌥⇧ V")
            }
            .productCard(cornerRadius: 11)

            HStack(spacing: 7) {
                Image(systemName: "checkmark.shield")
                Text("⌃⌥ Space не конфликтует с сочетанием установленного MyDictate.")
            }
            .font(.system(size: 8.8, weight: .medium))
            .foregroundStyle(AppTheme.success)
        }
    }

    private var feedbackSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsGroup {
                SettingsRow(symbol: "speaker.wave.2", title: "Звуки", detail: "Начало, завершение и ошибка") {
                    Toggle("", isOn: $sounds)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                }
                RowDivider()
                SettingsRow(symbol: "waveform", title: "Анимация волны", detail: "Показывать реакцию на громкость речи") {
                    Toggle("", isOn: $waveform)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                }
                RowDivider()
                SettingsRow(symbol: "rectangle.bottomthird.inset.filled", title: "Положение индикатора", detail: "На активном экране") {
                    Picker("", selection: $indicatorPosition) {
                        Text("Снизу").tag("Снизу")
                        Text("Сверху").tag("Сверху")
                        Text("У курсора").tag("У курсора")
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                RowDivider()
                SettingsRow(symbol: "clock", title: "Показывать результат", detail: "Перед автоматическим скрытием") {
                    Picker("", selection: $resultDuration) {
                        Text("1,0 сек").tag("1,0 сек")
                        Text("1,5 сек").tag("1,5 сек")
                        Text("2,5 сек").tag("2,5 сек")
                    }
                    .labelsHidden()
                    .frame(width: 110)
                }
            }

            SecondaryActionButton("Показать индикатор", symbol: "play") {
                store.beginDictationPreview()
            }
        }
    }

    private var storageSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsGroup {
                SettingsRow(symbol: "folder", title: "Папка данных", detail: "New MyDictate Dev — не используется основным приложением") {
                    SecondaryActionButton("Открыть") {
                        NSWorkspace.shared.open(store.dataDirectory)
                    }
                }
                RowDivider()
                SettingsRow(symbol: "waveform", title: "Сохранять аудио", detail: "Позволяет воспроизвести и повторить распознавание") {
                    Toggle("", isOn: $saveAudio)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                }
                RowDivider()
                SettingsRow(symbol: "clock.arrow.circlepath", title: "Срок хранения аудио", detail: "После этого записи удаляются автоматически") {
                    Picker("", selection: $retention) {
                        Text("1 день").tag("1 день")
                        Text("7 дней").tag("7 дней")
                        Text("30 дней").tag("30 дней")
                        Text("Всегда").tag("Всегда")
                    }
                    .labelsHidden()
                    .frame(width: 105)
                }
            }

            HStack(spacing: 13) {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Небольшой объём")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text("Только демонстрационные данные и импортированные файлы")
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SecondaryActionButton("Очистить…") {
                    store.showToast("Очистка будет добавлена с отдельным подтверждением")
                }
            }
            .padding(13)
            .productCard(cornerRadius: 10)
        }
    }

    private var advancedSettings: some View {
        SettingsGroup {
            SettingsRow(symbol: "bolt.horizontal.circle", title: "Производительность", detail: "Нет фонового опроса истории по таймеру") {
                Label("Оптимально", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.success)
            }
            RowDivider()
            SettingsRow(symbol: "doc.text", title: "Журнал диагностики", detail: "Не содержит текст демонстрационных записей") {
                SecondaryActionButton("Открыть") {
                    store.showToast("Журнал будет подключён вместе с движком")
                }
            }
            RowDivider()
            SettingsRow(symbol: "arrow.clockwise", title: "Перезапустить службу", detail: "Служба появится после интеграции движка") {
                SecondaryActionButton("Перезапустить") {
                    store.showToast("Движок пока не подключён")
                }
            }
        }
    }
}

private struct ShortcutRow: View {
    let title: String
    let detail: String
    let keys: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 8.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(AppTheme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.72), lineWidth: 1)
                }
        }
        .padding(.horizontal, 13)
        .frame(height: 61)
    }
}
