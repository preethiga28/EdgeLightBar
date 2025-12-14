/*
 * File: ColorTemperature.swift
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

extension NSColor {
    /// Approximate black-body temperature (Kelvin) -> RGB.
    convenience init(kelvin: Double) {
        let k = max(1000.0, min(40000.0, kelvin))
        let temp = k / 100.0

        let red: Double
        let green: Double
        let blue: Double

        if temp <= 66 {
            red = 255
            green = 99.4708025861 * log(temp) - 161.1195681661
            blue = temp <= 19 ? 0 : (138.5177312231 * log(temp - 10) - 305.0447927307)
        } else {
            red = 329.698727446 * pow(temp - 60, -0.1332047592)
            green = 288.1221695283 * pow(temp - 60, -0.0755148492)
            blue = 255
        }

        func clamp8(_ x: Double) -> Double { max(0, min(255, x)) }
        let r = clamp8(red) / 255.0
        let g = clamp8(green) / 255.0
        let b = clamp8(blue) / 255.0

        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}

