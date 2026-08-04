import SwiftUI

struct ModesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showNewMode = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(
                    title: "Режимы",
                    subtitle: "Разные правила для промпта, сообщения, заметки или точного текста."
                ) {
                    PrimaryActionButton(title: "Новый режим", symbol: "plus") {
                        showNewMode = true
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.modes) { mode in
                        ModeCard(mode: mode, selected: mode.id == store.activeModeID)
                    }
                }
                .padding(.top, 22)

                rulesPanel
                    .padding(.top, 16)
            }
            .padding(30)
        }
        .background(AppTheme.window)
        .sheet(isPresented: $showNewMode) {
            NewModeSheet()
                .environmentObject(store)
        }
    }

    private var rulesPanel: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Автовыбор по приложению")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("New MyDictate будет сам включать подходящий режим.")
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TextActionButton("Добавить правило", symbol: "plus") {
                    store.showToast("Редактор правил будет подключён следующим экраном")
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 51)
            .background(AppTheme.subtleSurface)

            Divider()

            ForEach(Array(store.rules.enumerated()), id: \.element.id) { index, rule in
                RuleRow(rule: rule)
                if index < store.rules.count - 1 {
                    Divider().padding(.leading, 55)
                }
            }
        }
        .productCard(cornerRadius: 11)
    }
}

private struct ModeCard: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let mode: DictationMode
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ModeIcon(mode: mode, size: 36)
                Spacer()
                if selected {
                    Label("Активен", systemImage: "checkmark")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 8)
                        .frame(height: 23)
                        .background(AppTheme.accentSurface(for: colorScheme))
                        .clipShape(Capsule())
                } else {
                    Menu {
                        Button("Включить") { store.selectMode(mode.id) }
                        Button("Дублировать") { store.showToast("Копия режима будет доступна в редакторе") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 28, height: 28)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }
            }

            Text(mode.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.top, 12)

            Text(mode.detail)
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .lineLimit(3)
                .frame(minHeight: 42, alignment: .topLeading)
                .padding(.top, 5)

            Text(mode.apps)
                .font(.system(size: 8.5))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Divider().padding(.top, 12)

            HStack {
                SecondaryActionButton("Настроить", symbol: "slider.horizontal.3") {
                    store.showToast("Открыт редактор режима «\(mode.name)»")
                }
                Spacer()
                if !selected {
                    TextActionButton("Включить") {
                        store.selectMode(mode.id)
                    }
                }
            }
            .padding(.top, 11)
        }
        .padding(15)
        .background(selected ? AppTheme.accentSurface(for: colorScheme).opacity(colorScheme == .dark ? 0.72 : 0.52) : AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? AppTheme.accent.opacity(0.45) : AppTheme.controlBorder.opacity(0.66), lineWidth: 1)
        }
    }
}

private struct RuleRow: View {
    @EnvironmentObject private var store: AppStore
    let rule: AppRule

    private var modeName: String {
        store.modes.first(where: { $0.id == rule.modeID })?.name ?? "Режим"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(rule.monogram)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 31, height: 31)
                .background(rule.modeID == "prompt" ? Color(nsColor: .darkGray) : AppTheme.processing)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(rule.applications)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(rule.detail)
                    .font(.system(size: 8.5))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 14)

            Image(systemName: "arrow.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)

            Text(modeName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(minWidth: 105, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { store.updateRule(rule, enabled: $0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
            .tint(AppTheme.accent)
        }
        .padding(.horizontal, 13)
        .frame(height: 54)
    }
}

private struct NewModeSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var detail = ""
    @State private var apps = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Новый режим")
                    .font(.system(size: 20, weight: .bold))
                Text("Начните с понятного назначения. Сложные инструкции можно добавить позже.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Название").font(.system(size: 9)).foregroundStyle(.secondary)
                TextField("Например: Техническое описание", text: $name)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Что должен делать режим").font(.system(size: 9)).foregroundStyle(.secondary)
                TextField("Коротко опишите ожидаемый результат", text: $detail, axis: .vertical)
                    .lineLimit(3...5)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Подходящие приложения").font(.system(size: 9)).foregroundStyle(.secondary)
                TextField("Например: Xcode · Codex", text: $apps)
            }

            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Создать") {
                    if store.addMode(name: name, detail: detail, apps: apps) {
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(23)
        .frame(width: 490)
        .background(AppTheme.window)
    }
}
