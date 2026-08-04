import Foundation
import Testing
@testable import NewMyDictate

@Test
func historyDurationFormatting() {
    let item = HistoryItem(
        id: UUID(),
        title: "Test",
        text: "Text",
        date: Date(),
        duration: 65,
        modeID: "exact",
        kind: .audio,
        audioRelativePath: nil
    )

    #expect(item.durationLabel == "1:05")
}

@Test @MainActor
func defaultModesHaveStableUniqueIdentifiers() {
    let modes = AppStore.defaultModes
    #expect(modes.count == 4)
    #expect(Set(modes.map(\.id)).count == modes.count)
    #expect(modes.contains(where: { $0.id == "prompt" && $0.name == "Промпт для AI" }))
}

@Test
func appearancePreferencesHaveVisibleLabels() {
    for appearance in AppearancePreference.allCases {
        #expect(!appearance.title.isEmpty)
        #expect(!appearance.symbol.isEmpty)
    }
}
