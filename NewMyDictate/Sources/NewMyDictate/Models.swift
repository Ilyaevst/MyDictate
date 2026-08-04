import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case overview
    case history
    case vocabulary
    case modes
    case settings
    case help

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Обзор"
        case .history: "История"
        case .vocabulary: "Словарь"
        case .modes: "Режимы"
        case .settings: "Настройки"
        case .help: "Помощь"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .history: "clock.arrow.circlepath"
        case .vocabulary: "book.closed"
        case .modes: "wand.and.stars"
        case .settings: "gearshape"
        case .help: "questionmark.circle"
        }
    }
}

enum HistoryKind: String, Codable, CaseIterable {
    case text
    case audio
    case issue

    var symbol: String {
        switch self {
        case .text: "doc.text"
        case .audio: "waveform"
        case .issue: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
}

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case text
    case audio
    case issues

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все"
        case .text: "Тексты"
        case .audio: "Аудио"
        case .issues: "Ошибки"
        }
    }
}

struct HistoryItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var text: String
    var date: Date
    var duration: Double
    var modeID: String
    var kind: HistoryKind
    var audioRelativePath: String?

    var durationLabel: String {
        let seconds = max(0, Int(duration.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var preview: String {
        text.replacingOccurrences(of: "\n", with: " ")
    }
}

struct VocabularyEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var spoken: String
    var written: String
    var group: String
}

struct DictationMode: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var detail: String
    var apps: String
    var symbol: String
    var tone: ModeTone
}

enum ModeTone: String, Codable {
    case blue
    case orange
    case violet
    case green
}

struct AppRule: Identifiable, Codable, Hashable {
    var id: UUID
    var applications: String
    var detail: String
    var modeID: String
    var monogram: String
    var enabled: Bool
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case dictation
    case shortcuts
    case feedback
    case storage
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Основные"
        case .dictation: "Диктовка"
        case .shortcuts: "Клавиши"
        case .feedback: "Звуки и индикатор"
        case .storage: "Хранение"
        case .advanced: "Дополнительно"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gauge.with.dots.needle.50percent"
        case .dictation: "mic"
        case .shortcuts: "keyboard"
        case .feedback: "speaker.wave.2"
        case .storage: "externaldrive"
        case .advanced: "slider.horizontal.3"
        }
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Как в системе"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}

struct PersistedUserData: Codable {
    var history: [HistoryItem]
    var vocabulary: [VocabularyEntry]
    var modes: [DictationMode]
    var activeModeID: String
    var rules: [AppRule]
}
