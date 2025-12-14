/*
 * File: OverlayManager.swift
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2025-2026 Cmalf-Labs
 *
 * This file is part of EdgeLightBar.
 *
 * EdgeLightBar is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EdgeLightBar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import AppKit

final class OverlayManager {

    private let settings: SettingsStore
    private var windowsByDisplayID: [CGDirectDisplayID: EdgeLightWindow] = [:]

    init(settings: SettingsStore) {
        self.settings = settings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    func applyCurrentSettings(animated: Bool) {
        if settings.isLightOn {
            rebuildWindows(animated: animated)
        } else {
            teardownAll()
        }
    }

    func teardownAll() {
        for (_, win) in windowsByDisplayID { win.orderOut(nil) }
        windowsByDisplayID.removeAll()
    }

    @objc private func screenParametersChanged() {
        guard settings.isLightOn else { return }
        rebuildWindows(animated: false)
    }

    private func rebuildWindows(animated: Bool) {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        let targetScreens: [NSScreen]
        if settings.useAllMonitors {
            targetScreens = screens
        } else {
            let idx = min(max(settings.currentMonitorIndex, 0), screens.count - 1)
            targetScreens = [screens[idx]]
        }

        let targetIDs = Set(targetScreens.compactMap { $0.displayID })
        for (id, win) in windowsByDisplayID where !targetIDs.contains(id) {
            win.orderOut(nil)
            windowsByDisplayID[id] = nil
        }

        for screen in targetScreens {
            guard let displayID = screen.displayID else { continue }

            let layout = OverlayGeometry.layoutUnderMenuBarCoverDock(for: screen, bleed: 150)
            let rect = layout.windowRect

            let win: EdgeLightWindow
            if let existing = windowsByDisplayID[displayID] {
                win = existing
                win.setFrame(rect, display: true)
            } else {
                win = EdgeLightWindow(frame: rect)
                windowsByDisplayID[displayID] = win
            }

            win.update(contentInsets: layout.contentInsets)
            win.apply(
                brightness: settings.brightness,
                temperatureK: settings.colorTemperature,
                neonEnabled: settings.neonEnabled,
                neonPreset: settings.neonPreset,
                neonMode: settings.neonMode,
                excludeFromCapture: settings.excludeFromCapture,
                animated: animated
            )

            win.orderFrontRegardless()
        }
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map { CGDirectDisplayID($0.uint32Value) }
    }
}
