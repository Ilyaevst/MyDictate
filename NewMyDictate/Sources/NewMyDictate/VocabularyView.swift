import SwiftUI
import UniformTypeIdentifiers

struct VocabularyView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var search = ""
    @State private var spoken = ""
    @State private var written = ""
    @State private var showImporter = false

    private var filteredEntries: [VocabularyEntry] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return store.vocabulary }
        return store.vocabulary.filter {
            $0.spoken.lowercased().contains(query) ||
                $0.written.lowercased().contains(query) ||
                $0.group.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                title: "Словарь",
                subtitle: "Термины, имена и точные автоматические замены."
            ) {
                SecondaryActionButton("Импортировать", symbol: "square.and.arrow.down") {
                    showImporter = true
                }
            }

            explainer
                .padding(.top, 22)

            addRow
                .padding(.top, 16)

            HStack {
                SearchField(placeholder: "Поиск по словарю…", text: $search)
                    .frame(maxWidth: 330)
                Spacer()
                Text("\(filteredEntries.count) терминов")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            dictionaryTable
        }
        .padding(30)
        .background(AppTheme.window)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            let access = url.startAccessingSecurityScopedResource()
            store.importVocabulary(from: url)
            if access { url.stopAccessingSecurityScopedResource() }
        }
    }

    private var explainer: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 35, height: 35)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Особенно полезно для технического текста")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Научите New MyDictate правильно писать названия инструментов, библиотек и проектов. Замены выполняются локально и предсказуемо.")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            Spacer(minLength: 15)
            Text("Локально")
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(AppTheme.success)
                .padding(.horizontal, 9)
                .frame(height: 23)
                .background(AppTheme.success.opacity(colorScheme == .dark ? 0.19 : 0.09))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(AppTheme.accentSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(AppTheme.accent.opacity(colorScheme == .dark ? 0.38 : 0.22), lineWidth: 1)
        }
    }

    private var addRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            LabeledField(title: "Как произносите", placeholder: "например: кодекс", text: $spoken)

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)

            LabeledField(title: "Как написать", placeholder: "например: Codex", text: $written)

            PrimaryActionButton(title: "Добавить", symbol: "plus") {
                if store.addVocabulary(spoken: spoken, written: written) {
                    spoken = ""
                    written = ""
                }
            }
            .padding(.bottom, 1)
        }
        .onSubmit {
            if store.addVocabulary(spoken: spoken, written: written) {
                spoken = ""
                written = ""
            }
        }
    }

    @ViewBuilder
    private var dictionaryTable: some View {
        if filteredEntries.isEmpty {
            EmptyState(symbol: "book.closed", title: "Словарь пуст", detail: "Добавьте термин или измените поисковый запрос.")
                .productCard(cornerRadius: 10)
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("Произношение").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Результат").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Группа").frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(width: 30)
                }
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(AppTheme.subtleSurface)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEntries) { entry in
                            HStack(spacing: 12) {
                                Text(entry.spoken)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(entry.written)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(entry.group)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(role: .destructive) {
                                    store.removeVocabulary(entry)
                                } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.tertiary)
                                .help("Удалить термин")
                            }
                            .font(.system(size: 10))
                            .padding(.horizontal, 13)
                            .frame(height: 47)

                            if entry.id != filteredEntries.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .productCard(cornerRadius: 10)
        }
    }
}

private struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 10.5))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .frame(height: 35)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.78), lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity)
    }
}
