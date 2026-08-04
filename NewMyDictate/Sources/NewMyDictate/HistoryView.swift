import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var player = HistoryAudioPlayer()
    @State private var search = ""
    @State private var filter: HistoryFilter = .all
    @State private var selectedID: UUID?
    @State private var showAudioImporter = false
    @State private var itemToDelete: HistoryItem?
    @State private var editingItem: HistoryItem?

    private var filteredItems: [HistoryItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.history.filter { item in
            let filterMatch: Bool
            switch filter {
            case .all: filterMatch = true
            case .text: filterMatch = item.kind == .text
            case .audio: filterMatch = item.kind == .audio
            case .issues: filterMatch = item.kind == .issue
            }
            let queryMatch = query.isEmpty || item.title.lowercased().contains(query) || item.text.lowercased().contains(query)
            return filterMatch && queryMatch
        }
    }

    private var selectedItem: HistoryItem? {
        if let selectedID, let item = store.history.first(where: { $0.id == selectedID }) {
            return item
        }
        return filteredItems.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                title: "История",
                subtitle: "\(store.history.count) записей · отдельное хранилище dev-версии"
            ) {
                SecondaryActionButton("Импорт аудио", symbol: "square.and.arrow.down") {
                    showAudioImporter = true
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 28)

            toolbar
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 12)

            HSplitView {
                historyList
                    .frame(minWidth: 290, idealWidth: 350, maxWidth: 430)
                historyDetail
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(AppTheme.controlBorder.opacity(0.66), lineWidth: 1)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 26)
        }
        .background(AppTheme.window)
        .fileImporter(
            isPresented: $showAudioImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            let access = url.startAccessingSecurityScopedResource()
            store.importAudio(from: url)
            if access { url.stopAccessingSecurityScopedResource() }
        }
        .alert("Удалить запись?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Отмена", role: .cancel) { itemToDelete = nil }
            Button("Удалить", role: .destructive) {
                if let itemToDelete {
                    if selectedID == itemToDelete.id { selectedID = nil }
                    player.stop()
                    store.removeHistory(itemToDelete)
                }
                itemToDelete = nil
            }
        } message: {
            Text("Текст и связанная аудиозапись будут удалены только из New MyDictate Dev.")
        }
        .sheet(item: $editingItem) { item in
            EditHistoryItemSheet(item: item) { newText in
                store.updateHistoryText(item, text: newText)
            }
        }
        .onAppear {
            if selectedID == nil { selectedID = filteredItems.first?.id }
        }
        .onChange(of: filter) { _, _ in
            if let selectedID, !filteredItems.contains(where: { $0.id == selectedID }) {
                self.selectedID = filteredItems.first?.id
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            SearchField(placeholder: "Найти в истории…", text: $search)
                .frame(maxWidth: 340)

            Picker("Фильтр", selection: $filter) {
                ForEach(HistoryFilter.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 290)

            Spacer()

            Text("Ошибок: \(store.issueCount)")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(store.issueCount > 0 ? AppTheme.danger : Color.secondary)
        }
    }

    private var historyList: some View {
        Group {
            if filteredItems.isEmpty {
                EmptyState(symbol: "magnifyingglass", title: "Ничего не найдено", detail: "Измените запрос или фильтр.")
                    .background(AppTheme.subtleSurface)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(filteredItems) { item in
                            HistoryListRow(item: item, selected: selectedItem?.id == item.id) {
                                selectedID = item.id
                            }
                        }
                    }
                    .padding(6)
                }
                .background(AppTheme.subtleSurface)
            }
        }
    }

    @ViewBuilder
    private var historyDetail: some View {
        if let item = selectedItem {
            HistoryDetailView(
                item: item,
                mode: store.modes.first(where: { $0.id == item.modeID }),
                audioURL: store.absoluteAudioURL(for: item),
                player: player,
                onCopy: { copy(item.text) },
                onEdit: { editingItem = item },
                onRetry: { store.showToast("Повторное распознавание будет подключено вместе с движком") },
                onDelete: { itemToDelete = item }
            )
        } else {
            EmptyState(symbol: "doc.text.magnifyingglass", title: "Выберите запись", detail: "Справа появятся текст, плеер и действия.")
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        store.showToast("Текст скопирован")
    }
}

private struct HistoryListRow: View {
    let item: HistoryItem
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: item.kind.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(item.kind == .issue ? AppTheme.danger : Color.secondary)
                    .frame(width: 29, height: 29)
                    .background(AppTheme.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.preview)
                        .font(.system(size: 8.8))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text(item.durationLabel)
                        Text("·")
                        Text(item.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                    }
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 4)
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 75, alignment: .topLeading)
            .contentShape(Rectangle())
            .background(selected ? AppTheme.surface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.65), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HistoryDetailView: View {
    let item: HistoryItem
    let mode: DictationMode?
    let audioURL: URL?
    @ObservedObject var player: HistoryAudioPlayer
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRetry: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.date, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.system(size: 8.5))
                        .foregroundStyle(.tertiary)
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Menu {
                    Button("Скопировать", action: onCopy)
                    Button("Изменить", action: onEdit)
                    Divider()
                    Button("Удалить", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }

            HStack(spacing: 6) {
                if let mode {
                    DetailBadge(symbol: "wand.and.stars", title: mode.name)
                }
                DetailBadge(symbol: "clock", title: item.durationLabel)
                if item.kind != .text {
                    DetailBadge(symbol: "waveform", title: audioURL == nil ? "Демо-аудио" : "Аудио сохранено")
                }
            }
            .padding(.top, 11)

            if item.kind != .text {
                AudioPlayerBar(item: item, url: audioURL, player: player)
                    .padding(.top, 13)
            }

            ScrollView {
                Text(item.text)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
            }
            .background(AppTheme.subtleSurface)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(AppTheme.controlBorder.opacity(0.60), lineWidth: 1)
            }
            .padding(.top, 13)

            HStack(spacing: 7) {
                PrimaryActionButton(title: "Скопировать", symbol: "doc.on.doc", action: onCopy)
                SecondaryActionButton("Изменить", symbol: "pencil", action: onEdit)
                SecondaryActionButton("Повторить", symbol: "arrow.clockwise", action: onRetry)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .frame(width: 31, height: 31)
                }
                .buttonStyle(.bordered)
                .help("Удалить запись")
            }
            .padding(.top, 11)

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "info.circle")
                Text("Плеер воспроизводит импортированный локальный файл. Демо-записи показывают состояние без доступа к данным основного MyDictate.")
            }
            .font(.system(size: 8.5))
            .foregroundStyle(.secondary)
            .padding(9)
            .background(AppTheme.subtleSurface)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.top, 10)
        }
        .padding(20)
        .background(AppTheme.surface)
    }
}

private struct DetailBadge: View {
    let symbol: String
    let title: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 8.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(AppTheme.subtleSurface)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(AppTheme.controlBorder.opacity(0.55), lineWidth: 1) }
    }
}

private struct AudioPlayerBar: View {
    let item: HistoryItem
    let url: URL?
    @ObservedObject var player: HistoryAudioPlayer

    private var isCurrent: Bool { player.itemID == item.id }

    var body: some View {
        HStack(spacing: 11) {
            Button {
                player.toggle(item: item, url: url)
            } label: {
                Image(systemName: isCurrent && player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 29, height: 29)
                    .background(AppTheme.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            WaveformView(
                color: AppTheme.accent,
                barCount: 40,
                activeFraction: isCurrent ? player.progress : 0
            )
            .frame(height: 28)

            Text(isCurrent ? player.timeLabel : item.durationLabel)
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 11)
        .frame(height: 47)
        .background(AppTheme.subtleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppTheme.controlBorder.opacity(0.60), lineWidth: 1)
        }
    }
}

@MainActor
final class HistoryAudioPlayer: ObservableObject {
    @Published private(set) var itemID: UUID?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var demoStartedAt: Date?

    var timeLabel: String {
        let seconds = max(0, Int(currentTime.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    func toggle(item: HistoryItem, url: URL?) {
        if itemID == item.id, isPlaying {
            pause()
            return
        }
        if itemID == item.id, !isPlaying {
            resume()
            return
        }
        stop()
        itemID = item.id
        duration = max(1, item.duration)
        if let url, let player = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer = player
            duration = max(1, player.duration)
            player.prepareToPlay()
            player.play()
        } else {
            demoStartedAt = Date()
        }
        isPlaying = true
        startUpdates()
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        itemID = nil
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        demoStartedAt = nil
    }

    private func pause() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func resume() {
        if let audioPlayer {
            audioPlayer.play()
        } else {
            demoStartedAt = Date().addingTimeInterval(-currentTime)
        }
        isPlaying = true
        startUpdates()
    }

    private func startUpdates() {
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            while let self, self.isPlaying, !Task.isCancelled {
                if let player = self.audioPlayer {
                    self.currentTime = player.currentTime
                    if !player.isPlaying && self.currentTime > 0 {
                        self.finishPlayback()
                        return
                    }
                } else if let started = self.demoStartedAt {
                    self.currentTime = Date().timeIntervalSince(started)
                    if self.currentTime >= self.duration {
                        self.finishPlayback()
                        return
                    }
                }
                self.progress = min(1, self.currentTime / max(1, self.duration))
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func finishPlayback() {
        isPlaying = false
        currentTime = duration
        progress = 1
        playbackTask?.cancel()
        playbackTask = nil
    }
}

private struct EditHistoryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: HistoryItem
    let onSave: (String) -> Void
    @State private var text: String

    init(item: HistoryItem, onSave: @escaping (String) -> Void) {
        self.item = item
        self.onSave = onSave
        _text = State(initialValue: item.text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Изменить текст")
                    .font(.system(size: 19, weight: .bold))
                Text(item.title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: $text)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(9)
                .background(AppTheme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.65), lineWidth: 1)
                }
            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Сохранить") {
                    onSave(text)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 540, height: 390)
        .background(AppTheme.window)
    }
}
