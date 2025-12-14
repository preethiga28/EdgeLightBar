/*
 * File: SettingsStore.swift
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

import Foundation

final class SettingsStore {

    struct Keys {
        static let isLightOn = "isLightOn"
        static let brightness = "brightness"
        static let colorTemperature = "colorTemperature"
        static let useAllMonitors = "useAllMonitors"
        static let currentMonitorIndex = "currentMonitorIndex"
        static let excludeFromCapture = "excludeFromCapture"

        // NeonLight Fun
        static let neonEnabled = "neonEnabled"
        static let neonPreset = "neonPreset"   // 0=blue,1=purple,2=gold
        static let neonMode = "neonMode"       // 0=static,1=blink,2=move
    }

    enum NeonPreset: Int {
        case blue = 0
        case purple = 1
        case gold = 2
    }

    enum NeonMode: Int {
        case `static` = 0
        case blink = 1
        case move = 2
    }

    private let defaults: UserDefaults

    var isLightOn: Bool { didSet { save() } }
    var brightness: Double { didSet { brightness = Self.clamp(brightness, 0.10, 1.00); save() } }
    var colorTemperature: Double { didSet { colorTemperature = Self.clamp(colorTemperature, 3000, 9000); save() } }
    var useAllMonitors: Bool { didSet { save() } }
    var currentMonitorIndex: Int { didSet { currentMonitorIndex = max(0, currentMonitorIndex); save() } }
    var excludeFromCapture: Bool { didSet { save() } }

    // NeonLight Fun
    var neonEnabled: Bool { didSet { save() } }
    var neonPresetRaw: Int { didSet { neonPresetRaw = max(0, min(neonPresetRaw, 2)); save() } }
    var neonModeRaw: Int { didSet { neonModeRaw = max(0, min(neonModeRaw, 2)); save() } }

    var neonPreset: NeonPreset {
        get { NeonPreset(rawValue: neonPresetRaw) ?? .blue }
        set { neonPresetRaw = newValue.rawValue }
    }

    var neonMode: NeonMode {
        get { NeonMode(rawValue: neonModeRaw) ?? .static }
        set { neonModeRaw = newValue.rawValue }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.isLightOn = defaults.object(forKey: Keys.isLightOn) as? Bool ?? false
        self.brightness = Self.clamp(defaults.object(forKey: Keys.brightness) as? Double ?? 0.55, 0.10, 1.00)
        self.colorTemperature = Self.clamp(defaults.object(forKey: Keys.colorTemperature) as? Double ?? 6500, 3000, 9000)
        self.useAllMonitors = defaults.object(forKey: Keys.useAllMonitors) as? Bool ?? false
        self.currentMonitorIndex = max(0, defaults.object(forKey: Keys.currentMonitorIndex) as? Int ?? 0)
        self.excludeFromCapture = defaults.object(forKey: Keys.excludeFromCapture) as? Bool ?? false

        // Neon defaults
        self.neonEnabled = defaults.object(forKey: Keys.neonEnabled) as? Bool ?? false
        self.neonPresetRaw = defaults.object(forKey: Keys.neonPreset) as? Int ?? 0
        self.neonModeRaw = defaults.object(forKey: Keys.neonMode) as? Int ?? 0
    }

    func save() {
        defaults.set(isLightOn, forKey: Keys.isLightOn)
        defaults.set(brightness, forKey: Keys.brightness)
        defaults.set(colorTemperature, forKey: Keys.colorTemperature)
        defaults.set(useAllMonitors, forKey: Keys.useAllMonitors)
        defaults.set(currentMonitorIndex, forKey: Keys.currentMonitorIndex)
        defaults.set(excludeFromCapture, forKey: Keys.excludeFromCapture)

        defaults.set(neonEnabled, forKey: Keys.neonEnabled)
        defaults.set(neonPresetRaw, forKey: Keys.neonPreset)
        defaults.set(neonModeRaw, forKey: Keys.neonMode)
    }

    private static func clamp<T: Comparable>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
        min(max(value, minValue), maxValue)
    }
}

