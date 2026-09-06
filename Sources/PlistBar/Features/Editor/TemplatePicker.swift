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
                name: "Basic Agent",
                description: "Daemon-style agent, runs on login",
                icon: "play.circle.fill",
                tag: "Agent",
                make: { .basicAgent(label: "com.user.myagent") }
            ),
            TemplateItem(
                name: "Interval Task",
                description: "Runs periodically (e.g. every 1 hour)",
                icon: "clock.fill",
                tag: "Interval",
                make: { .intervalTask(label: "com.user.intervaljob") }
            ),
            TemplateItem(
                name: "Calendar Task",
                description: "Runs at specific times like cron",
                icon: "calendar",
                tag: "Calendar",
                make: { .calendarTask(label: "com.user.cronjob") }
            ),
            TemplateItem(
                name: "Directory Watcher",
                description: "Runs whenever files in a path change",
                icon: "eye.fill",
                tag: "Watch",
                make: { .watchPathTask(label: "com.user.filewatcher") }
            ),
            TemplateItem(
                name: "Blank Plist",
                description: "Empty draft, customize all properties",
                icon: "doc.fill",
                tag: "Custom",
                make: { .blank() }
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Launch Agent")
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .menuRowPadding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: LayoutTokens.space6) {
                    Text("Select a starter template:")
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
                        Text("New services are safely created in ~/Library/LaunchAgents")
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
