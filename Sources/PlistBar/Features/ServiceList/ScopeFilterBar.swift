import SwiftUI

struct ScopeFilterBar: View {
    @Binding var selectedScope: LaunchServiceScope?
    @Binding var statusFilter: LaunchRuntimeStatus?

    var body: some View {
        HStack(spacing: LayoutTokens.space2) {
            // Scope buttons
            ForEach(LaunchServiceScope.allCases) { scope in
                scopeButton(scope)
            }

            Spacer()

            // Status filter
            Menu {
                Button("All Statuses") { statusFilter = nil }
                ForEach(LaunchRuntimeStatus.allCases) { status in
                    Button(status.rawValue) { statusFilter = status }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(statusFilter?.rawValue ?? "All")
                        .font(.appCaption)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    private func scopeButton(_ scope: LaunchServiceScope) -> some View {
        let isActive = selectedScope == scope
        return Button {
            selectedScope = isActive ? nil : scope
        } label: {
            Text(scope.displayName)
                .font(.appCaption)
                .fontWeight(isActive ? .semibold : .regular)
                .padding(.horizontal, LayoutTokens.space6)
                .padding(.vertical, LayoutTokens.space2)
                .background(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                        .fill(isActive ? Color.accentColor.opacity(LayoutTokens.Opacity.tint) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                        .strokeBorder(
                            isActive ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.2),
                            lineWidth: LayoutTokens.stroke
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
