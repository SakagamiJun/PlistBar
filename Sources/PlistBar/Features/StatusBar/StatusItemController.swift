import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let panel: FloatingPanel
    private let popoverLayoutModel = PopoverLayoutModel()
    private let popoverFallbackMaxHeight: CGFloat = 640
    private let popoverScreenPadding: CGFloat = 10
    private let panelTopSpacing: CGFloat = 0
    private let panelHorizontalPadding: CGFloat = LayoutTokens.space8

    private var globalEventMonitor: Any?
    private var screenParametersObserver: Any?
    private var popoverHostingController: NSHostingController<AnyView>?

    let viewModel: ServiceListViewModel
    let alertViewModel: AlertViewModel

    init(viewModel: ServiceListViewModel, alertViewModel: AlertViewModel) {
        self.viewModel = viewModel
        self.alertViewModel = alertViewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.panel = FloatingPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: LayoutTokens.panelWidth,
                height: 460),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true)

        super.init()

        self.configurePanel()
        self.configureStatusItem()
        self.observeScreenParameterChanges()
        self.refreshPopoverMaximumHeight()

        self.alertViewModel.onAlertStateChanged = { [weak self] in
            self?.updateIconForAlertState()
        }
    }

    func shutdown() {
        self.stopGlobalMonitor()
        self.stopObservingScreenParameters()
        self.unloadPopoverContent()
        self.viewModel.stopHeartbeat()
        NSStatusBar.system.removeStatusItem(self.statusItem)
    }

    /// Update menu bar icon based on alert state (design.md §3.6 / llm-prompt §3.6)
    func updateIconForAlertState() {
        guard let button = statusItem.button else { return }

        if alertViewModel.hasError {
            button.image = NSImage(
                systemSymbolName: "exclamationmark.triangle.fill",
                accessibilityDescription: "PlistBar - \(l10n("severity.error"))"
            )
            button.image?.isTemplate = false
        } else if alertViewModel.hasWarning || alertViewModel.hasUnread {
            button.image = NSImage(
                systemSymbolName: "exclamationmark.triangle",
                accessibilityDescription: "PlistBar - \(l10n("severity.warning"))"
            )
            button.image?.isTemplate = false
        } else {
            button.image = NSImage(
                systemSymbolName: "list.bullet.rectangle",
                accessibilityDescription: "PlistBar"
            )
            button.image?.isTemplate = true
        }
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if self.panel.isVisible {
            self.closePopover(nil)
            return
        }

        self.ensurePopoverContent()
        self.refreshPopoverMaximumHeight()
        self.applyPopoverSize(preferredHeight: self.popoverLayoutModel.resolvedPanelHeight)
        self.placePanelRelativeToStatusButton(button)
        NSApp.activate(ignoringOtherApps: true)
        self.panel.makeKeyAndOrderFront(nil)
        self.placePanelRelativeToStatusButton(button)
        self.startGlobalMonitor()
        self.viewModel.startHeartbeat()
        self.viewModel.refresh()
    }

    @objc
    private func closePopover(_ sender: Any?) {
        self.panel.orderOut(sender)
        self.stopGlobalMonitor()
        self.unloadPopoverContent()
        self.viewModel.stopHeartbeat()
    }

    private func configurePanel() {
        self.panel.isReleasedWhenClosed = false
        self.panel.isOpaque = false
        self.panel.backgroundColor = .clear
        self.panel.hasShadow = true
        self.panel.acceptsMouseMovedEvents = true
        self.panel.becomesKeyOnlyIfNeeded = false
        self.panel.hidesOnDeactivate = false
        self.panel.level = .statusBar
        self.panel.collectionBehavior = [.transient, .moveToActiveSpace, .ignoresCycle]
        self.panel.contentViewController = nil
    }

    private func ensurePopoverContent() {
        if self.popoverHostingController == nil {
            let rootView = AnyView(
                ServiceListView(viewModel: self.viewModel, alertViewModel: self.alertViewModel)
                    .frame(width: LayoutTokens.panelWidth)
                    .background(
                        AppMaterialSurface.regularPanel()
                            .shadow(
                                color: Color(nsColor: .shadowColor).opacity(LayoutTokens.Shadow.standard.opacity),
                                radius: LayoutTokens.Shadow.standard.radius,
                                x: LayoutTokens.Shadow.standard.x,
                                y: LayoutTokens.Shadow.standard.y
                            )
                    )
            )
            let hc = NSHostingController(rootView: rootView)
            hc.sizingOptions = [.standardBounds]
            self.popoverHostingController = hc
        }
        self.panel.contentViewController = self.popoverHostingController
    }

    private func unloadPopoverContent() {
        self.panel.contentViewController = nil
        self.popoverHostingController = nil
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "list.bullet.rectangle",
            accessibilityDescription: "PlistBar"
        )
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(self.togglePopover(_:))
        button.sendAction(on: [.leftMouseUp])
    }

    private func startGlobalMonitor() {
        self.stopGlobalMonitor()
        self.globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
        ]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover(nil)
            }
        }
    }

    private func stopGlobalMonitor() {
        guard let globalEventMonitor else { return }
        NSEvent.removeMonitor(globalEventMonitor)
        self.globalEventMonitor = nil
    }

    private func observeScreenParameterChanges() {
        self.screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPopoverMaximumHeight()
            }
        }
    }

    private func stopObservingScreenParameters() {
        guard let screenParametersObserver else { return }
        NotificationCenter.default.removeObserver(screenParametersObserver)
        self.screenParametersObserver = nil
    }

    private func refreshPopoverMaximumHeight() {
        let maximumHeight = self.computeMaximumPopoverHeight()
        self.popoverLayoutModel.updateMaximumPanelHeight(maximumHeight)
    }

    private func computeMaximumPopoverHeight() -> CGFloat {
        guard let screen = statusItem.button?.window?.screen ?? NSScreen.main else {
            return self.popoverFallbackMaxHeight
        }
        let menuBarHeight = NSStatusBar.system.thickness
        let available = screen.visibleFrame.height - menuBarHeight - self.popoverScreenPadding - self.panelTopSpacing
        return max(280, available)
    }

    private func applyPopoverSize(preferredHeight: CGFloat) {
        let targetSize = NSSize(width: LayoutTokens.panelWidth, height: preferredHeight)

        let widthChanged = abs(panel.frame.width - targetSize.width) > 0.5
        let heightChanged = abs(panel.frame.height - targetSize.height) > 0.5
        guard widthChanged || heightChanged else { return }

        var newFrame = self.panel.frame
        newFrame.size = targetSize
        self.panel.setFrame(newFrame, display: true, animate: false)
    }

    private func placePanelRelativeToStatusButton(_ button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }

        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        let panelWidth = self.panel.frame.width
        let panelHeight = self.panel.frame.height

        var x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.minY - panelHeight - self.panelTopSpacing

        // Keep panel on screen
        if let screen = buttonWindow.screen {
            x = max(screen.visibleFrame.minX + self.panelHorizontalPadding,
                     min(x, screen.visibleFrame.maxX - panelWidth - self.panelHorizontalPadding))
        }

        self.panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
