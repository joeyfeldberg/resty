import AppKit
import Combine
import SwiftUI

@MainActor
final class WindowControllers {
    private let coordinator: BreakCoordinator
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var countdownTrackingCancellable: AnyCancellable?
    private var reminderPanel: NSPanel?
    private var countdownPanel: NSPanel?
    private var breakWindow: NSWindow?

    init(coordinator: BreakCoordinator, settingsStore: SettingsStore) {
        self.coordinator = coordinator
        self.settingsStore = settingsStore

        coordinator.$session
            .combineLatest(coordinator.$now)
            .sink { [weak self] _, _ in
                self?.refreshSurfaces()
            }
            .store(in: &cancellables)
    }

    private func refreshSurfaces() {
        if coordinator.shouldShowReminderPanel {
            showReminderPanel()
        } else {
            reminderPanel?.orderOut(nil)
        }

        if coordinator.shouldShowFloatingCountdown {
            showCountdownPanel()
            startCountdownTrackingIfNeeded()
        } else {
            countdownPanel?.orderOut(nil)
            countdownTrackingCancellable = nil
        }

        if coordinator.shouldShowBreakOverlay {
            showBreakWindow()
        } else {
            breakWindow?.orderOut(nil)
        }
    }

    private func showReminderPanel() {
        let panel = reminderPanel ?? makePanel(size: NSSize(width: 740, height: 230))
        reminderPanel = panel
        if panel.contentViewController == nil {
            panel.contentViewController = NSHostingController(
                rootView: ReminderPanelView(coordinator: coordinator, settingsStore: settingsStore)
            )
        }

        if let screen = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: screen.minX + 48, y: screen.maxY - panel.frame.height - 48))
        }

        panel.orderFrontRegardless()
    }

    private func showCountdownPanel() {
        let panel = countdownPanel ?? makePanel(size: NSSize(width: 68, height: 68), level: .screenSaver)
        countdownPanel = panel
        panel.ignoresMouseEvents = true
        if panel.contentViewController == nil {
            panel.contentViewController = NSHostingController(
                rootView: FloatingCountdownView(coordinator: coordinator)
            )
        }

        positionCountdownPanel()
        panel.orderFrontRegardless()
    }

    private func showBreakWindow() {
        let window = breakWindow ?? makeBreakWindow()
        breakWindow = window
        if window.contentViewController == nil {
            window.contentViewController = NSHostingController(
                rootView: BreakOverlayView(coordinator: coordinator, settingsStore: settingsStore)
            )
        }

        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }

        window.orderFrontRegardless()
    }

    private func startCountdownTrackingIfNeeded() {
        guard countdownTrackingCancellable == nil else { return }
        countdownTrackingCancellable = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.positionCountdownPanel()
            }
    }

    private func positionCountdownPanel() {
        guard let panel = countdownPanel else { return }

        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            let safeFrame = screen.visibleFrame
            let targetX = min(max(mouse.x + 10, safeFrame.minX + 6), safeFrame.maxX - panel.frame.width - 6)
            let targetY = min(max(mouse.y - panel.frame.height - 10, safeFrame.minY + 6), safeFrame.maxY - panel.frame.height - 6)
            panel.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        }
    }

    private func makePanel(size: NSSize, level: NSWindow.Level = .statusBar) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = level
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        return panel
    }

    private func makeBreakWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }
}
