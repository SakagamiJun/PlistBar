import SwiftUI

struct ConfirmButton: View {
    let title: String
    let message: String
    let destructive: Bool
    let action: () -> Void

    @State private var showConfirm = false

    var body: some View {
        Button(title) {
            showConfirm = true
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .popover(isPresented: $showConfirm) {
            VStack(spacing: LayoutTokens.space6) {
                Text(message)
                    .font(.appBody)

                HStack {
                    Button("Cancel") {
                        showConfirm = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .keyboardShortcut(.cancelAction)

                    Button("Confirm") {
                        showConfirm = false
                        action()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .keyboardShortcut(.defaultAction)
                    .tint(destructive ? .red : nil)
                }
            }
            .padding(LayoutTokens.space8)
            .frame(width: 240)
        }
    }
}
