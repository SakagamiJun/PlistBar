import SwiftUI

struct ServiceEditorView: View {
    @Bindable var viewModel: EditorViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Content
            if viewModel.isRawXMLMode {
                rawXMLEditor
            } else {
                formEditor
            }

            // Error banner
            if let error = viewModel.errorMessage {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .menuRowPadding(vertical: LayoutTokens.space4)
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Text("Edit Plist")
                .font(.appSubhead)
                .fontWeight(.semibold)

            Spacer()

            Button {
                viewModel.isRawXMLMode.toggle()
                if viewModel.isRawXMLMode {
                    refreshRawXML()
                }
            } label: {
                Text(viewModel.isRawXMLMode ? "Form" : "Source")
                    .font(.appCaption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Cancel") { onCancel() }
                .buttonStyle(.bordered)
                .controlSize(.small)

            Button("Save") { onSave() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .menuRowPadding()
    }

    // MARK: - Form Editor

    private var formEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                // Basic section
                section("Basic") {
                    fieldRow("Label", text: $viewModel.draft.label)
                    fieldRow("Program", text: $viewModel.draft.program)
                    multilineFieldRow("Program Arguments", text: $viewModel.draft.programArgumentsText)
                }

                // Behavior section
                section("Behavior") {
                    toggleRow("Run At Load", isOn: Binding(
                        get: { viewModel.draft.runAtLoad },
                        set: { viewModel.draft.runAtLoad = $0 }
                    ))
                    toggleRow("Keep Alive", isOn: Binding(
                        get: { viewModel.draft.keepAlive },
                        set: { viewModel.draft.keepAlive = $0 }
                    ))
                }

                // Paths section
                section("Paths") {
                    fieldRow("Working Directory", text: $viewModel.draft.workingDirectory)
                    fieldRow("Standard Out Path", text: $viewModel.draft.standardOutPath)
                    fieldRow("Standard Error Path", text: $viewModel.draft.standardErrorPath)
                }

                // Schedule section
                section("Schedule") {
                    toggleRow("Enable Schedule", isOn: $viewModel.draft.hasSchedule)

                    if viewModel.draft.hasSchedule {
                        Picker("Mode", selection: $viewModel.draft.scheduleMode) {
                            ForEach(LaunchPlistDraft.ScheduleMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch viewModel.draft.scheduleMode {
                        case .interval:
                            HStack {
                                Text("Interval (seconds)")
                                    .font(.appCaption)
                                Spacer()
                                TextField("", value: Binding(
                                    get: { viewModel.draft.intervalSeconds },
                                    set: { viewModel.draft.intervalSeconds = max($0, 1) }
                                ), format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            }
                        case .calendar:
                            Text("Calendar entries: \(viewModel.draft.calendarEntries.count)")
                                .font(.appCaption)
                        }
                    }
                }
            }
            .padding(LayoutTokens.space8)
        }
    }

    // MARK: - Raw XML Editor

    private var rawXMLEditor: some View {
        TextEditor(text: $viewModel.rawXMLText)
            .font(.app(size: LayoutTokens.FontSize.body))
            .scrollContentBackground(.hidden)
            .padding(LayoutTokens.space4)
    }

    // MARK: - Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(title)
                .font(.appCaption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(LayoutTokens.space6)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func fieldRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .frame(width: 100, alignment: .trailing)
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .font(.appBody)
        }
    }

    private func multilineFieldRow(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.appCaption)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextEditor(text: text)
                .font(.appBody)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.appBody)
        }
    }

    private func refreshRawXML() {
        do {
            let dict = try viewModel.draft.toDictionary()
            viewModel.rawXMLText = try PlistEditorService.xmlString(from: dict)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
