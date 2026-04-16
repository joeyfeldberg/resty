import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsStore: SettingsStore?
    var permissionsManager: PermissionsManager?
    var coordinator: BreakCoordinator?
    var windowControllers: WindowControllers?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore()
        let permissionsManager = PermissionsManager()
        let coordinator = BreakCoordinator(settingsStore: settingsStore)
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        self.settingsStore = settingsStore
        self.permissionsManager = permissionsManager
        self.coordinator = coordinator
        self.statusItem = statusItem
        self.windowControllers = WindowControllers(coordinator: coordinator, settingsStore: settingsStore)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        coordinator.$session
            .combineLatest(coordinator.$now)
            .sink { [weak self] _, _ in
                self?.refreshMenu()
            }
            .store(in: &cancellables)

        refreshMenu()
    }

    private func refreshMenu() {
        guard let statusItem, let coordinator else { return }

        if let button = statusItem.button {
            button.image = coordinator.statusIcon.nsImage()
            button.imagePosition = .imageLeading
            button.imageScaling = .scaleProportionallyDown
            button.title = coordinator.statusText
            button.font = .systemFont(ofSize: 13, weight: .semibold)
        }

        let menu = NSMenu()
        menu.showsStateColumn = false
        menu.addItem(menuItem("Begin Break Now", action: #selector(startBreakNow)))
        menu.addItem(menuItem("-5 Minutes", action: #selector(subtractFiveMinutes)))
        menu.addItem(menuItem("-1 Minute", action: #selector(subtractMinute)))
        menu.addItem(menuItem("+1 Minute", action: #selector(addMinute)))
        menu.addItem(menuItem("+5 Minutes", action: #selector(addFiveMinutes)))
        menu.addItem(menuItem("Skip This Round", action: #selector(skipBreak)))
        menu.addItem(.separator())
        menu.addItem(menuItem(coordinator.session.state == .pausedManual ? "Resume Reminders" : "Pause Reminders", action: #selector(togglePause)))
        menu.addItem(menuItem("Settings", action: #selector(openSettings)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit Resty", action: #selector(quitApp)))

        statusItem.menu = menu
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = nil
        item.state = .off
        item.onStateImage = nil
        item.offStateImage = nil
        item.mixedStateImage = nil
        item.indentationLevel = 0
        return item
    }

    @objc private func startBreakNow() {
        coordinator?.startBreakNow()
    }

    @objc private func addMinute() {
        coordinator?.extend(by: 60)
    }

    @objc private func subtractMinute() {
        coordinator?.extend(by: -60)
    }

    @objc private func subtractFiveMinutes() {
        coordinator?.extend(by: -300)
    }

    @objc private func addFiveMinutes() {
        coordinator?.extend(by: 300)
    }

    @objc private func skipBreak() {
        coordinator?.skipBreak()
    }

    @objc private func togglePause() {
        coordinator?.toggleManualPause()
    }

    @objc private func openSettings(_ sender: Any? = nil) {
        guard let settingsStore, let permissionsManager else { return }
        permissionsManager.refreshStatuses()

        if settingsWindow == nil {
            let controller = NSHostingController(
                rootView: SettingsView(settingsStore: settingsStore, permissionsManager: permissionsManager)
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 660, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Resty Settings"
            window.contentViewController = controller
            window.center()
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.toolbarStyle = .unified
            window.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1)
            settingsWindow = window
        } else {
            settingsWindow?.contentViewController = NSHostingController(
                rootView: SettingsView(settingsStore: settingsStore, permissionsManager: permissionsManager)
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func handleDidBecomeActive() {
        permissionsManager?.refreshStatuses()
    }
}
