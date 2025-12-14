/*
 * File: OverlayGeometry.swift
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

enum OverlayGeometry {

    struct Layout {
        let windowRect: CGRect
        let contentInsets: NSEdgeInsets
    }

    static func layoutUnderMenuBarCoverDock(for screen: NSScreen,
                                            bleed: CGFloat = 150) -> Layout {
        let f = screen.frame
        let vf = screen.visibleFrame // exclude menu bar + dock
        let menuBarHeight = max(0, f.maxY - vf.maxY)

        // Area “target” yang diinginkan user: dari bawah layar sampai tepat di bawah menu bar
        let targetRect = CGRect(x: f.minX,
                                y: f.minY,
                                width: f.width,
                                height: f.height - menuBarHeight)

        // Window diperbesar agar glow tidak ke-clip
        // Top bleed dibatasi sampai puncak layar (melewati targetRect tapi tetap di screen).
        let topBleed = min(bleed, menuBarHeight)

        let windowRect = CGRect(
            x: targetRect.minX - bleed,
            y: targetRect.minY - bleed,
            width: targetRect.width + bleed * 2,
            height: targetRect.height + bleed + topBleed
        )

        // Insets: supaya EdgeLightView menggambar ring tepat di area targetRect
        let insets = NSEdgeInsets(top: topBleed,
                                  left: bleed,
                                  bottom: bleed,
                                  right: bleed)

        return Layout(windowRect: windowRect, contentInsets: insets)
    }
}


