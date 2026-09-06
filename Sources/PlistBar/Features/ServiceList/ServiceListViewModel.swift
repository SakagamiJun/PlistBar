import Foundation
import SwiftUI

enum ActionStatus: Equatable, Sendable {
    case inProgress(String)
    case success(String)
    case failure(String)
}

@MainActor @Observable
final class ServiceListViewModel {
    var services: [LaunchService] = []
    var selectedService: LaunchService?
    var searchText: String = ""
    var selectedScope: LaunchServiceScope? = .userAgents
    var statusFilter: LaunchRuntimeStatus?
    var isLoading = false
    var isWorking = false
    var actionStatus: ActionStatus?

    private var heartbeatTask: Task<Void, Never>?

    // MARK: - Heartbeat

    func startHeartbeat() {
        stopHeartbeat()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                self?.refreshRuntimeStatus()
            }
        }
    }

    func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Lightweight heartbeat refresh

    private func refreshRuntimeStatus() {
        guard !isWorking else { return }

        Task.detached { [weak self] in
            guard let self else { return }
            let currentServices = await self.services
            let domains = Set(currentServices.map { $0.scope.launchDomain })
            var disabledMap: [String: Set<String>] = [:]
            for domain in domains {
                disabledMap[domain] = LaunchctlService.disabledLabels(for: domain)
            }

            var updated: [LaunchService] = []
            for service in currentServices {
                let (status, pid) = LaunchctlService.runtimeStatus(label: service.label, scope: service.scope)
                let isDisabled = disabledMap[service.scope.launchDomain]?.contains(service.label) ?? false
                updated.append(LaunchService(
                    plistURL: service.plistURL,
                    scope: service.scope,
                    label: service.label,
                    kind: service.kind,
                    enabled: !isDisabled,
                    runtimeStatus: status,
                    pid: pid,
                    plistDictionary: service.plistDictionary
                ))
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.services = updated
                if let selected = self.selectedService,
                   let refreshed = updated.first(where: { $0.plistURL == selected.plistURL }) {
                    self.selectedService = refreshed
                }
            }
        }
    }

    // MARK: - Filtering

    var filteredServices: [LaunchService] {
        services.filter { service in
            if let selectedScope, service.scope != selectedScope {
                return false
            }

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !service.label.localizedCaseInsensitiveContains(searchText) {
                return false
            }

            if let statusFilter {
                if statusFilter == .stopped {
                    if service.runtimeStatus == .running { return false }
                } else if service.runtimeStatus != statusFilter {
                    return false
                }
            }

            return true
        }
    }

    // MARK: - Full refresh

    func refresh() {
        isLoading = true
        Task.detached { [weak self] in
            let result: Result<[LaunchService], Error>
            do {
                let discovered = try LaunchctlService.discoverServices()
                result = .success(discovered)
            } catch {
                result = .failure(error)
            }
            await self?.applyRefresh(result)
        }
    }

    private func applyRefresh(_ result: Result<[LaunchService], Error>) {
        isLoading = false
        switch result {
        case .success(let discovered):
            self.services = discovered
            if let selectedService,
               let updated = discovered.first(where: { $0.plistURL == selectedService.plistURL }) {
                self.selectedService = updated
            }
            if selectedService == nil {
                selectedService = filteredServices.first
            }
        case .failure(let error):
            self.actionStatus = .failure(error.localizedDescription)
        }
    }

    // MARK: - Actions

    func runAction(_ action: @escaping @Sendable (LaunchService) throws -> Void, label: String = "Processing") {
        guard let service = selectedService else { return }
        isWorking = true
        let localizedLabel = label
        actionStatus = .inProgress(l10n("status.action_in_progress", localizedLabel, service.label))

        Task.detached {
            let result: Result<Void, Error>
            do {
                try action(service)
                result = .success(())
            } catch {
                result = .failure(error)
            }
            await MainActor.run { [weak self] in
                self?.isWorking = false
                switch result {
                case .success:
                    self?.actionStatus = .success(l10n("status.action_completed", localizedLabel))
                    self?.refresh()
                case .failure(let error):
                    self?.actionStatus = .failure(error.localizedDescription)
                }
                let currentStatus = self?.actionStatus
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    if self?.actionStatus == currentStatus {
                        self?.actionStatus = nil
                    }
                }
            }
        }
    }
}
