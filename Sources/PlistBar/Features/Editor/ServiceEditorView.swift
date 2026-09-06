import SwiftUI

struct ServiceEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: EditorViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            // Header / Toolbar
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
                HStack(spacing: LayoutTokens.space4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ColorTokens.critical)
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.critical)
                        .lineLimit(2)
                    Spacer()
                }
                .menuRowPadding(vertical: LayoutTokens.space4)
                .background(ColorTokens.critical.opacity(0.1))
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

            Picker("", selection: $viewModel.isRawXMLMode) {
                Text("Form").tag(false)
                Text("XML").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
            .onChange(of: viewModel.isRawXMLMode) { _, isRaw in
                if isRaw {
                    refreshRawXML()
                } else {
                    applyRawXMLToDraft()
                }
            }

            Button("Cancel") { onCancel() }
                .buttonStyle(.bordered)
                .controlSize(.small)

            Button("Save") {
                if viewModel.isRawXMLMode {
                    applyRawXMLToDraft()
                }
                onSave()
            }
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
                section("Identity & Executable") {
                    fieldRow("Label", text: $viewModel.draft.label, placeholder: "com.user.task")
                    fieldRow("Program", text: $viewModel.draft.program, placeholder: "/usr/local/bin/mycmd")
                    multilineFieldRow("Arguments (one per line)", text: $viewModel.draft.programArgumentsText)
                }

                // Behavior section
                section("Process Behavior") {
                    toggleRow("Run At Load", isOn: Binding(
                        get: { viewModel.draft.runAtLoad },
                        set: { viewModel.draft.runAtLoad = $0 }
                    ))
                    toggleRow("Keep Alive", isOn: Binding(
                        get: { viewModel.draft.keepAlive },
                        set: { viewModel.draft.keepAlive = $0 }
                    ))
                }

                // Schedule section
                section("Scheduling") {
                    toggleRow("Enable Schedule", isOn: $viewModel.draft.hasSchedule)

                    if viewModel.draft.hasSchedule {
                        Picker("Mode", selection: $viewModel.draft.scheduleMode) {
                            ForEach(LaunchPlistDraft.ScheduleMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, LayoutTokens.space2)

                        switch viewModel.draft.scheduleMode {
                        case .interval:
                            intervalEditor
                        case .calendar:
                            calendarEditor
                        }
                    }
                }

                // Paths section
                section("Standard Paths") {
                    fieldRow("Working Dir", text: $viewModel.draft.workingDirectory, placeholder: "~/projects")
                    fieldRow("stdout", text: $viewModel.draft.standardOutPath, placeholder: "/tmp/myjob.stdout.log")
                    fieldRow("stderr", text: $viewModel.draft.standardErrorPath, placeholder: "/tmp/myjob.stderr.log")
                }

                // Environment & Watch section
                section("Advanced (Optional)") {
                    multilineFieldRow("Environment (KEY=VAL)", text: $viewModel.draft.environmentVariablesText)
                    multilineFieldRow("Watch Paths (one per line)", text: $viewModel.draft.watchPathsText)
                }
            }
            .padding(LayoutTokens.space8)
        }
    }

    // MARK: - Interval Editor

    private var intervalEditor: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            HStack {
                Text("Interval (seconds)")
                    .font(.appCaption)
                Spacer()
                TextField("", value: Binding(
                    get: { viewModel.draft.intervalSeconds },
                    set: { viewModel.draft.intervalSeconds = max($0, 1) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .font(.appBody)
                .frame(width: 80)
            }

            // Quick presets
            HStack(spacing: LayoutTokens.space4) {
                Text("Presets:")
                    .font(.system(size: 9))
                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                ForEach([(60, "1m"), (300, "5m"), (900, "15m"), (1800, "30m"), (3600, "1h"), (86400, "1d")], id: \.0) { sec, label in
                    Button(label) {
                        viewModel.draft.intervalSeconds = sec
                    }
                    .font(.system(size: 9))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
    }

    // MARK: - Calendar Editor

    private var calendarEditor: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            ForEach(Array(viewModel.draft.calendarEntries.enumerated()), id: \.element.id) { index, _ in
                calendarEntryRow(index: index)
            }

            Button {
                viewModel.draft.calendarEntries.append(
                    LaunchPlistDraft.CalendarEntry(minute: 0, hour: 9)
                )
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "plus.circle")
                    Text("Add Entry")
                }
                .font(.appCaption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ColorTokens.accent)
            .padding(.top, LayoutTokens.space2)
        }
    }

    private func calendarEntryRow(index: Int) -> some View {
        let entry = viewModel.draft.calendarEntries[index]
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Entry \(index + 1): \(entry.summary)")
                    .font(.appCaption)
                    .fontWeight(.medium)
                Spacer()
                Button {
                    viewModel.draft.calendarEntries.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(ColorTokens.critical)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: LayoutTokens.space4) {
                timeInputField(
                    label: "Hour",
                    value: Binding(
                        get: { viewModel.draft.calendarEntries[index].hour ?? 0 },
                        set: { viewModel.draft.calendarEntries[index].hour = min(23, max(0, $0)) }
                    )
                )
                timeInputField(
                    label: "Min",
                    value: Binding(
                        get: { viewModel.draft.calendarEntries[index].minute ?? 0 },
                        set: { viewModel.draft.calendarEntries[index].minute = min(59, max(0, $0)) }
                    )
                )
                timeInputField(
                    label: "Day",
                    value: Binding(
                        get: { viewModel.draft.calendarEntries[index].day ?? 1 },
                        set: { viewModel.draft.calendarEntries[index].day = min(31, max(1, $0)) }
                    )
                )
                timeInputField(
                    label: "Wkday",
                    value: Binding(
                        get: { viewModel.draft.calendarEntries[index].weekday ?? 1 },
                        set: { viewModel.draft.calendarEntries[index].weekday = min(7, max(1, $0)) }
                    )
                )
            }
        }
        .padding(LayoutTokens.space4)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(ColorTokens.controlFill(isDark: isDark))
        )
    }

    private func timeInputField(label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .font(.appCaption)
                .frame(width: 44)
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
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
            content()
        }
        .padding(LayoutTokens.space6)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius, style: .continuous)
                .fill(ColorTokens.controlFill(isDark: isDark))
        )
    }

    private func fieldRow(_ label: String, text: Binding<String>, placeholder: String = "") -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .frame(width: 90, alignment: .trailing)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.appBody)
        }
    }

    private func multilineFieldRow(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
            TextEditor(text: text)
                .font(.appBody)
                .frame(minHeight: 52)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(ColorTokens.separator(isDark: isDark), lineWidth: LayoutTokens.stroke)
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
            viewModel.errorMessage = nil
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func applyRawXMLToDraft() {
        do {
            let dict = try PlistEditorService.dictionary(fromRawXML: viewModel.rawXMLText)
            viewModel.draft = LaunchPlistDraft.from(dictionary: dict)
            viewModel.errorMessage = nil
        } catch {
            viewModel.errorMessage = "Invalid XML: \(error.localizedDescription)"
        }
    }
}
