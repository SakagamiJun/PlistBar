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

    @Test("Model displayNames localization")
    @MainActor
    func modelDisplayNames() {
        let manager = LocalizationManager.shared

        manager.setLanguage(.simplifiedChinese)
        #expect(LaunchServiceScope.userAgents.displayName == "用户 Agents")
        #expect(LaunchServiceScope.globalAgents.displayName == "全局 Agents")
        #expect(LaunchServiceScope.globalDaemons.displayName == "全局 Daemons (系统)")
        #expect(LaunchRuntimeStatus.running.displayName == "运行中")
        #expect(LaunchRuntimeStatus.loaded.displayName == "已加载")
        #expect(LaunchRuntimeStatus.stopped.displayName == "未运行")
        #expect(LaunchServiceKind.agent.displayName == "Agent (代理)")
        #expect(LaunchServiceKind.daemon.displayName == "Daemon (守护进程)")
        #expect(LogRule.Severity.error.displayName == "错误")
        #expect(LogRule.Severity.warning.displayName == "警告")
        #expect(LogRule.Severity.info.displayName == "信息")

        manager.setLanguage(.english)
        #expect(LaunchServiceScope.userAgents.displayName == "User Agents")
        #expect(LaunchRuntimeStatus.running.displayName == "Running")
        #expect(LogRule.Severity.error.displayName == "Error")
    }

    @Test("CalendarEntry summary localization")
    @MainActor
    func calendarEntrySummary() {
        let manager = LocalizationManager.shared

        let entry = LaunchPlistDraft.CalendarEntry(minute: 30, hour: 14, day: 15, weekday: 2, month: 10)

        manager.setLanguage(.simplifiedChinese)
        #expect(entry.summary.contains("10月"))
        #expect(entry.summary.contains("周一"))
        #expect(entry.summary.contains("15日"))
        #expect(entry.summary.contains("14:30"))

        manager.setLanguage(.english)
        #expect(entry.summary.contains("Month 10"))
        #expect(entry.summary.contains("Mon"))
        #expect(entry.summary.contains("Day 15"))
        #expect(entry.summary.contains("14:30"))
    }
}
