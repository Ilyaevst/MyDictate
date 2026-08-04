import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppStore: ObservableObject {
    @Published var selectedSection: AppSection = .overview
    @Published var history: [HistoryItem] = []
    @Published var vocabulary: [VocabularyEntry] = []
    @Published var modes: [DictationMode] = AppStore.defaultModes
    @Published var activeModeID: String = "prompt"
    @Published var rules: [AppRule] = []
    @Published var toastMessage: String?
    @Published var showOnboarding = false
    @Published var dictationPreviewState: DictationPreviewState = .idle

    let dataDirectory: URL
    private let dataFile: URL
    private var toastTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDirectory = base.appendingPathComponent("New MyDictate Dev", isDirectory: true)
        dataFile = dataDirectory.appendingPathComponent("UserData.json")
        prepareDirectory()
        load()
    }

    var activeMode: DictationMode {
        modes.first(where: { $0.id == activeModeID }) ?? modes[0]
    }

    var issueCount: Int {
        history.filter { $0.kind == .issue }.count
    }

    func selectMode(_ id: String) {
        guard modes.contains(where: { $0.id == id }) else { return }
        activeModeID = id
        save()
        showToast("Режим «\(activeMode.name)» включён")
    }

    func addMode(name: String, detail: String, apps: String) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanDetail.isEmpty else {
            showToast("Заполните название и назначение режима")
            return false
        }
        let id = "custom-\(UUID().uuidString.lowercased())"
        modes.append(
            DictationMode(
                id: id,
                name: cleanName,
                detail: cleanDetail,
                apps: apps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "По выбору пользователя" : apps,
                symbol: "slider.horizontal.3",
                tone: .orange
            )
        )
        activeModeID = id
        save()
        showToast("Новый режим создан и включён")
        return true
    }

    func addVocabulary(spoken: String, written: String, group: String = "Мои термины") -> Bool {
        let cleanSpoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWritten = written.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSpoken.isEmpty, !cleanWritten.isEmpty else {
            showToast("Заполните произношение и результат")
            return false
        }
        vocabulary.insert(
            VocabularyEntry(id: UUID(), spoken: cleanSpoken, written: cleanWritten, group: group),
            at: 0
        )
        save()
        showToast("Термин добавлен")
        return true
    }

    func removeVocabulary(_ entry: VocabularyEntry) {
        vocabulary.removeAll { $0.id == entry.id }
        save()
        showToast("Термин удалён")
    }

    func importVocabulary(from url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            var imported = 0
            for line in lines {
                let columns = line.split(separator: ",", maxSplits: 2).map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard columns.count >= 2, !columns[0].isEmpty, !columns[1].isEmpty else { continue }
                let group = columns.count > 2 && !columns[2].isEmpty ? columns[2] : "Импорт"
                vocabulary.append(VocabularyEntry(id: UUID(), spoken: columns[0], written: columns[1], group: group))
                imported += 1
            }
            save()
            showToast(imported == 0 ? "В файле не найдено пар значений" : "Импортировано терминов: \(imported)")
        } catch {
            showToast("Не удалось прочитать файл")
        }
    }

    func updateRule(_ rule: AppRule, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].enabled = enabled
        save()
    }

    func removeHistory(_ item: HistoryItem) {
        history.removeAll { $0.id == item.id }
        if let relative = item.audioRelativePath {
            let target = dataDirectory.appendingPathComponent(relative)
            try? FileManager.default.removeItem(at: target)
        }
        save()
        showToast("Запись удалена")
    }

    func updateHistoryText(_ item: HistoryItem, text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty,
              let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        history[index].text = cleanText
        save()
        showToast("Текст изменён")
    }

    func importAudio(from url: URL) {
        let audioDirectory = dataDirectory.appendingPathComponent("Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        let destinationName = "\(UUID().uuidString).\(url.pathExtension.isEmpty ? "m4a" : url.pathExtension)"
        let destination = audioDirectory.appendingPathComponent(destinationName)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            let player = try? AVAudioPlayer(contentsOf: destination)
            let item = HistoryItem(
                id: UUID(),
                title: url.deletingPathExtension().lastPathComponent,
                text: "Аудиозапись импортирована. Локальное распознавание подключим к этой оболочке на следующем этапе.",
                date: Date(),
                duration: player?.duration ?? 0,
                modeID: activeModeID,
                kind: .audio,
                audioRelativePath: "Audio/\(destinationName)"
            )
            history.insert(item, at: 0)
            save()
            showToast("Аудио добавлено в историю")
        } catch {
            showToast("Не удалось импортировать аудио")
        }
    }

    func absoluteAudioURL(for item: HistoryItem) -> URL? {
        guard let relative = item.audioRelativePath else { return nil }
        let url = dataDirectory.appendingPathComponent(relative)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func beginDictationPreview() {
        guard dictationPreviewState == .idle else { return }
        previewTask?.cancel()
        previewTask = Task { @MainActor in
            dictationPreviewState = .recording
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            dictationPreviewState = .processing
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            dictationPreviewState = .done
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            dictationPreviewState = .idle
            showToast("Демонстрация индикатора завершена")
        }
    }

    func cancelDictationPreview() {
        previewTask?.cancel()
        dictationPreviewState = .idle
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }

    private func prepareDirectory() {
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        } catch {
            assertionFailure("Unable to create isolated data directory: \(error)")
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: dataFile),
           let decoded = try? JSONDecoder().decode(PersistedUserData.self, from: data) {
            history = decoded.history
            vocabulary = decoded.vocabulary
            modes = decoded.modes.isEmpty ? Self.defaultModes : decoded.modes
            activeModeID = decoded.activeModeID
            rules = decoded.rules
            return
        }
        history = Self.sampleHistory
        vocabulary = Self.sampleVocabulary
        rules = Self.sampleRules
        save()
    }

    private func save() {
        let payload = PersistedUserData(
            history: history,
            vocabulary: vocabulary,
            modes: modes,
            activeModeID: activeModeID,
            rules: rules
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: dataFile, options: .atomic)
    }

    static let defaultModes: [DictationMode] = [
        DictationMode(
            id: "exact",
            name: "Точный текст",
            detail: "Минимальная обработка: пунктуация и точные исправления из словаря.",
            apps: "Любое приложение",
            symbol: "doc.text",
            tone: .blue
        ),
        DictationMode(
            id: "prompt",
            name: "Промпт для AI",
            detail: "Сохраняет детали, оформляет задачу и отделяет контекст от результата.",
            apps: "Codex · Claude · ChatGPT",
            symbol: "wand.and.stars",
            tone: .orange
        ),
        DictationMode(
            id: "work",
            name: "Рабочий текст",
            detail: "Убирает повторы и превращает речь в короткое понятное сообщение.",
            apps: "Mail · Slack · Telegram",
            symbol: "bolt",
            tone: .violet
        ),
        DictationMode(
            id: "note",
            name: "Заметка",
            detail: "Разбивает длинную мысль на абзацы, действия и вопросы.",
            apps: "Notes · Obsidian · Notion",
            symbol: "book.pages",
            tone: .green
        ),
    ]

    private static let sampleHistory: [HistoryItem] = [
        HistoryItem(
            id: UUID(),
            title: "Промпт для аудита интерфейса",
            text: "Проверь экран настроек: найди перегруженные блоки, повторяющиеся действия и предложи более ясную структуру. Сначала дай список проблем, затем приоритетный план изменений.",
            date: Date().addingTimeInterval(-620),
            duration: 18,
            modeID: "prompt",
            kind: .text,
            audioRelativePath: nil
        ),
        HistoryItem(
            id: UUID(),
            title: "Комментарий к pull request",
            text: "Здесь лучше отделить загрузку модели от инициализации интерфейса, чтобы окно открывалось сразу, а состояние загрузки было видно пользователю.",
            date: Date().addingTimeInterval(-6_300),
            duration: 11,
            modeID: "work",
            kind: .text,
            audioRelativePath: nil
        ),
        HistoryItem(
            id: UUID(),
            title: "Черновик заметки о релизе",
            text: "В этой версии мы переработали навигацию настроек и сделали управление моделью понятнее. Перед публикацией нужно проверить первый запуск и историю диктовок.",
            date: Date().addingTimeInterval(-10_800),
            duration: 23,
            modeID: "note",
            kind: .audio,
            audioRelativePath: nil
        ),
        HistoryItem(
            id: UUID(),
            title: "Не удалось распознать",
            text: "Аудиозапись сохранена локально. Повторите распознавание, когда модель будет готова.",
            date: Date().addingTimeInterval(-68_400),
            duration: 8,
            modeID: "exact",
            kind: .issue,
            audioRelativePath: nil
        ),
        HistoryItem(
            id: UUID(),
            title: "Ответ команде",
            text: "Да, беру задачу. Сначала воспроизведу проблему на чистой установке, затем проверю исправление на последней сборке.",
            date: Date().addingTimeInterval(-76_000),
            duration: 9,
            modeID: "work",
            kind: .text,
            audioRelativePath: nil
        ),
    ]

    private static let sampleVocabulary: [VocabularyEntry] = [
        VocabularyEntry(id: UUID(), spoken: "кодекс", written: "Codex", group: "AI-инструменты"),
        VocabularyEntry(id: UUID(), spoken: "клоуд", written: "Claude", group: "AI-инструменты"),
        VocabularyEntry(id: UUID(), spoken: "постгрес", written: "PostgreSQL", group: "Разработка"),
        VocabularyEntry(id: UUID(), spoken: "гитхаб экшенс", written: "GitHub Actions", group: "Разработка"),
        VocabularyEntry(id: UUID(), spoken: "нью май диктейт", written: "New MyDictate", group: "Проекты"),
    ]

    private static let sampleRules: [AppRule] = [
        AppRule(
            id: UUID(),
            applications: "Codex, Claude и ChatGPT",
            detail: "При начале диктовки",
            modeID: "prompt",
            monogram: "AI",
            enabled: true
        ),
        AppRule(
            id: UUID(),
            applications: "Mail, Slack и Telegram",
            detail: "При начале диктовки",
            modeID: "work",
            monogram: "M",
            enabled: true
        ),
    ]
}

enum DictationPreviewState: Equatable {
    case idle
    case recording
    case processing
    case done
}
