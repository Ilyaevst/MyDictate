import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    private let primarySections: [AppSection] = [.overview, .history, .vocabulary, .modes]
    private let secondarySections: [AppSection] = [.settings, .help]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 18)

            VStack(spacing: 4) {
                ForEach(primarySections) { section in
                    SidebarButton(
                        section: section,
                        selected: store.selectedSection == section,
                        badge: section == .history && store.issueCount > 0 ? "\(store.issueCount)" : nil
                    ) {
                        store.selectedSection = section
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 18)

            activeModeCard
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            VStack(spacing: 3) {
                ForEach(secondarySections) { section in
                    SidebarButton(
                        section: section,
                        selected: store.selectedSection == section,
                        badge: nil
                    ) {
                        store.selectedSection = section
                    }
                }
            }
            .padding(.horizontal, 10)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield")
                Text("Изолировано от MyDictate")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(AppTheme.success)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .background(colorScheme == .dark ? AppTheme.sidebar : AppTheme.window)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.47, blue: 0.24), AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.accent.opacity(colorScheme == .dark ? 0.20 : 0.28), radius: 8, y: 4)
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("New MyDictate")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Отдельная dev-версия")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeModeCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("АКТИВНЫЙ РЕЖИМ")
                .font(.system(size: 8.5, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(.tertiary)

            Menu {
                ForEach(store.modes) { mode in
                    Button {
                        store.selectMode(mode.id)
                    } label: {
                        if mode.id == store.activeModeID {
                            Label(mode.name, systemImage: "checkmark")
                        } else {
                            Text(mode.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: store.activeMode.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                    Text(store.activeMode.name)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(maxWidth: .infinity)
        }
        .padding(11)
        .frame(minHeight: 62)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.controlBorder.opacity(0.68), lineWidth: 1)
        }
    }
}

private struct SidebarButton: View {
    let section: AppSection
    let selected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbol)
                    .font(.system(size: 15, weight: selected ? .semibold : .regular))
                    .frame(width: 18)
                Text(section.title)
                    .font(.system(size: 11.5, weight: selected ? .semibold : .medium))
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(selected ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .frame(height: 37)
            .contentShape(Rectangle())
            .background(selected ? AppTheme.surface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.controlBorder.opacity(0.68), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
