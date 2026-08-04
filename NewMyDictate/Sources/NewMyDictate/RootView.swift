import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearance") private var appearanceRaw = AppearancePreference.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                SidebarView()
                    .frame(width: 220)

                Divider()

                Group {
                    switch store.selectedSection {
                    case .overview:
                        OverviewView()
                    case .history:
                        HistoryView()
                    case .vocabulary:
                        VocabularyView()
                    case .modes:
                        ModesView()
                    case .settings:
                        SettingsView()
                    case .help:
                        HelpView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.window)
            }

            if let toast = store.toastMessage {
                ToastView(message: toast)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(4)
            }

            if store.dictationPreviewState != .idle {
                VStack {
                    Spacer()
                    DictationHUD(state: store.dictationPreviewState)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }
        }
        .animation(.snappy(duration: 0.24), value: store.toastMessage)
        .animation(.snappy(duration: 0.24), value: store.dictationPreviewState)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.beginDictationPreview()
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 7, height: 7)
                            .shadow(color: AppTheme.success.opacity(0.35), radius: 3)
                        Text("Готов к диктовке")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Показать демонстрацию индикатора")

                Menu {
                    Picker("Оформление", selection: $appearanceRaw) {
                        ForEach(AppearancePreference.allCases) { appearance in
                            Label(appearance.title, systemImage: appearance.symbol)
                                .tag(appearance.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                }
                .help("Оформление")
            }
        }
        .sheet(isPresented: $store.showOnboarding) {
            OnboardingView()
                .environmentObject(store)
        }
    }
}

private struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            Text(message)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color(nsColor: .white))
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(Color(nsColor: .black).opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
    }
}
