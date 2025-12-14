/*
 * File: AppDelegate.swift
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

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = SettingsStore()
    private lazy var overlayManager = OverlayManager(settings: settings)
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar-only
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController(settings: settings, overlayManager: overlayManager)
        overlayManager.applyCurrentSettings(animated: false)
        statusBarController.refreshMenuState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        settings.save()
        overlayManager.teardownAll()
    }
}
