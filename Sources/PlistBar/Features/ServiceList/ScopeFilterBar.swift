import SwiftUI

struct ScopeFilterBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedScope: LaunchServiceScope?
    @Binding var statusFilter: LaunchRuntimeStatus?
    var scopeCounts: [LaunchServiceScope: Int] = [:]

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: LayoutTokens.space2) {
            // Scope buttons
            ForEach(LaunchServiceScope.allCases) { scope in
                scopeButton(scope)
            }

            Spacer()

            // Status filter menu
            statusFilterMenu
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    private func scopeButton(_ scope: LaunchServiceScope) -> some View {
        let isActive = selectedScope == scope
        let count = scopeCounts[scope] ?? 0
        let shortName: String = {
            switch scope {
            case .userAgents: return "User"
            case .globalAgents: return "Global"
            case .globalDaemons: return "System"
            }
        }()

        return Button {
            selectedScope = isActive ? nil : scope
        } label: {
            HStack(spacing: 2) {
                Text(shortName)
                    .font(.appCaption)
                    .fontWeight(isActive ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9))
                        .foregroundStyle(isActive ? ColorTokens.accent : ColorTokens.tertiaryLabel(isDark: isDark))
                }
            }
            .padding(.horizontal, LayoutTokens.space6)
            .padding(.vertical, LayoutTokens.space2)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                    .fill(isActive ? ColorTokens.accent.opacity(LayoutTokens.Opacity.tint) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                    .strokeBorder(
                        isActive ? ColorTokens.accent.opacity(0.4) : ColorTokens.separator(isDark: isDark),
                        lineWidth: LayoutTokens.stroke
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var statusFilterMenu: some View {
        Menu {
            Button {
                statusFilter = nil
            } label: {
                Label("All Statuses", systemImage: "line.3.horizontal.decrease.circle")
            }

            Divider()

            ForEach(LaunchRuntimeStatus.allCases) { status in
                Button {
                    statusFilter = status
                } label: {
                    Label(status.rawValue, systemImage: status.symbolName)
                }
            }
        } label: {
            HStack(spacing: 2) {
                if let status = statusFilter {
                    Circle()
                        .fill(status.color)
                        .frame(width: 6, height: 6)
                    Text(status.rawValue)
                        .font(.appCaption)
                        .fontWeight(.medium)
                } else {
                    Text("All")
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 7))
                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            }
            .padding(.horizontal, LayoutTokens.space4)
            .padding(.vertical, LayoutTokens.space2)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                    .fill(ColorTokens.controlFill(isDark: isDark))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
