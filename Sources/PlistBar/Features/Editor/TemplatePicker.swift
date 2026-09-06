import SwiftUI

struct TemplatePicker: View {
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: (LaunchPlistDraft) -> Void
    let onCancel: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    fileprivate struct TemplateItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let tag: String
        let make: () -> LaunchPlistDraft
    }

    private var templates: [TemplateItem] {
        [
            TemplateItem(
                name: l10n("template.basic_agent.name"),
                description: l10n("template.basic_agent.desc"),
                icon: "play.circle.fill",
                tag: l10n("template.basic_agent.tag"),
                make: { .basicAgent(label: "com.user.myagent") }
            ),
            TemplateItem(
                name: l10n("template.interval_task.name"),
                description: l10n("template.interval_task.desc"),
                icon: "clock.fill",
                tag: l10n("template.interval_task.tag"),
                make: { .intervalTask(label: "com.user.intervaljob") }
            ),
            TemplateItem(
                name: l10n("template.calendar_task.name"),
                description: l10n("template.calendar_task.desc"),
                icon: "calendar",
                tag: l10n("template.calendar_task.tag"),
                make: { .calendarTask(label: "com.user.cronjob") }
            ),
            TemplateItem(
                name: l10n("template.watch_task.name"),
                description: l10n("template.watch_task.desc"),
                icon: "eye.fill",
                tag: l10n("template.watch_task.tag"),
                make: { .watchPathTask(label: "com.user.filewatcher") }
            ),
            TemplateItem(
                name: l10n("template.blank.name"),
                description: l10n("template.blank.desc"),
                icon: "doc.fill",
                tag: l10n("template.blank.tag"),
                make: { .blank() }
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(l10n("template.title"))
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                Spacer()

                Button(l10n("action.cancel")) { onCancel() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .menuRowPadding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: LayoutTokens.space6) {
                    Text(l10n("template.subtitle"))
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                        .padding(.top, LayoutTokens.space2)

                    ForEach(templates) { template in
                        TemplateRow(template: template) {
                            onSelect(template.make())
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text(l10n("template.safe_notice"))
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                    .padding(.top, LayoutTokens.space4)
                }
                .padding(LayoutTokens.space8)
            }
        }
    }
}

private struct TemplateRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let template: TemplatePicker.TemplateItem
    let action: () -> Void
    @State private var isHovered = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space6) {
                Image(systemName: template.icon)
                    .font(.title3)
                    .foregroundStyle(ColorTokens.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(template.name)
                            .font(.appBody)
                            .fontWeight(.medium)

                        Text(template.tag)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(ColorTokens.accent.opacity(LayoutTokens.Opacity.tint))
                            )
                            .foregroundStyle(ColorTokens.accent)
                    }

                    Text(template.description)
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            }
            .menuRowPadding()
            .hoverRowBackground(isHovered: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
