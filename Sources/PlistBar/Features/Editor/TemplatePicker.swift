import SwiftUI

struct TemplatePicker: View {
    let onSelect: (LaunchPlistDraft) -> Void

    private struct TemplateItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let make: () -> LaunchPlistDraft
    }

    private var templates: [TemplateItem] {
        [
            TemplateItem(
                name: "Basic Agent",
                description: "Simple agent that runs at load",
                icon: "play.circle",
                make: { .basicAgent(label: "com.example.agent") }
            ),
            TemplateItem(
                name: "Interval Task",
                description: "Runs periodically (default 1h)",
                icon: "clock",
                make: { .intervalTask(label: "com.example.interval") }
            ),
            TemplateItem(
                name: "Calendar Task",
                description: "Runs at scheduled times",
                icon: "calendar",
                make: { .calendarTask(label: "com.example.calendar") }
            ),
            TemplateItem(
                name: "Watch Path",
                description: "Triggers on file changes",
                icon: "eye",
                make: { .watchPathTask(label: "com.example.watch") }
            ),
            TemplateItem(
                name: "Blank",
                description: "Start from scratch",
                icon: "doc",
                make: { .blank() }
            ),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space6) {
            Text("Choose a Template")
                .font(.appSubhead)
                .fontWeight(.semibold)

            ForEach(templates) { template in
                Button {
                    onSelect(template.make())
                } label: {
                    HStack(spacing: LayoutTokens.space6) {
                        Image(systemName: template.icon)
                            .font(.appSubhead)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(template.name)
                                .font(.appBody)
                                .fontWeight(.medium)
                            Text(template.description)
                                .font(.appCaption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.appCaption)
                            .foregroundStyle(.tertiary)
                    }
                    .menuRowPadding()
                    .background(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(LayoutTokens.space8)
    }
}
