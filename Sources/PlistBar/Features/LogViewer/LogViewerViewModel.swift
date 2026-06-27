import Foundation

@MainActor @Observable
final class LogViewerViewModel {
    var stdoutText: String = ""
    var stderrText: String = ""
    var unifiedLogText: String = ""
    var isLoading: Bool = false
    var searchText: String = ""
    var selectedTab: LogTab = .stdout

    enum LogTab: String, CaseIterable, Identifiable {
        case stdout = "stdout"
        case stderr = "stderr"
        case unified = "unified"

        var id: String { rawValue }
    }

    func loadLogs(for service: LaunchService) {
        isLoading = true
        Task.detached {
            let result = LaunchctlService.loadLogsSplit(service: service)
            await MainActor.run { [weak self] in
                self?.stdoutText = result.stdout
                self?.stderrText = result.stderr
                self?.unifiedLogText = result.unified
                self?.isLoading = false
            }
        }
    }

    var currentLogText: String {
        switch selectedTab {
        case .stdout: return stdoutText
        case .stderr: return stderrText
        case .unified: return unifiedLogText
        }
    }

    var filteredLines: [String] {
        let lines = currentLogText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if searchText.isEmpty { return lines }
        return lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
