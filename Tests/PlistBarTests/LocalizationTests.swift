import Foundation
import Testing
@testable import PlistBar

@Suite("Localization Tests")
struct LocalizationTests {
    @Test("English string resolution")
    @MainActor
    func englishLocalization() {
        let manager = LocalizationManager.shared
        manager.setLanguage(.english)

        #expect(l10n("action.cancel") == "Cancel")
        #expect(l10n("action.save") == "Save")
        #expect(l10n("list.search_placeholder") == "Search by label...")
        #expect(l10n("settings.title") == "Settings")
    }

    @Test("Simplified Chinese string resolution")
    @MainActor
    func simplifiedChineseLocalization() {
        let manager = LocalizationManager.shared
        manager.setLanguage(.simplifiedChinese)

        #expect(l10n("action.cancel") == "取消")
        #expect(l10n("action.save") == "保存")
        #expect(l10n("list.search_placeholder") == "按服务名搜索...")
        #expect(l10n("settings.title") == "设置")
        #expect(l10n("scope.user_agents") == "用户 Agents")
        #expect(l10n("status.running") == "运行中")
    }

    @Test("Parameterized string formatting")
    @MainActor
    func formattedStrings() {
        let manager = LocalizationManager.shared

        manager.setLanguage(.english)
        let enCount = l10n("list.service_count", 5)
        #expect(enCount == "5 services")

        manager.setLanguage(.simplifiedChinese)
        let zhCount = l10n("list.service_count", 5)
        #expect(zhCount == "5 个服务")

        let zhProgress = l10n("status.action_in_progress", "启动中", "com.test.service")
        #expect(zhProgress == "启动中 com.test.service...")
    }

    @Test("Key fallback when string key is missing")
    @MainActor
    func fallback() {
        let missingKey = "non_existent_key_12345"
        #expect(l10n(missingKey) == missingKey)
    }
}
