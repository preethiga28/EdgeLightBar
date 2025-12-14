/*
 * File: EdgeLightWindow.swift
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

final class EdgeLightWindow: NSWindow {

    private let rootView = NSView(frame: .zero)
    private let glowView = EdgeLightView(frame: .zero)

    init(frame: CGRect) {
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        rootView.frame = CGRect(origin: .zero, size: frame.size)
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.clear.cgColor
        contentView = rootView

        glowView.frame = rootView.bounds
        glowView.autoresizingMask = [.width, .height]
        rootView.addSubview(glowView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        if let cv = contentView {
            glowView.frame = cv.bounds
            glowView.needsLayout = true
        }
    }

    func update(contentInsets: NSEdgeInsets) {
        glowView.contentInsets = contentInsets
        glowView.needsLayout = true
    }

    func apply(brightness: Double,
               temperatureK: Double,
               neonEnabled: Bool,
               neonPreset: SettingsStore.NeonPreset,
               neonMode: SettingsStore.NeonMode,
               excludeFromCapture: Bool,
               animated: Bool) {

        sharingType = excludeFromCapture ? .none : .readOnly

        glowView.updateAppearance(
            brightness: brightness,
            temperatureK: temperatureK,
            neonEnabled: neonEnabled,
            neonPreset: neonPreset,
            neonMode: neonMode,
            animated: animated
        )
    }
}
