/*
 * File: EdgeLightView.swift
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
import QuartzCore

final class EdgeLightView: NSView {

    var contentInsets: NSEdgeInsets = .zero { didSet { needsLayout = true } }

    // Tuning
    private let outerInset: CGFloat = -45
    private let ringThickness: CGFloat = 99
    private let radiusRatio: CGFloat = 0.19
    private let featherMultiplier: CGFloat = 1.22
    private let bloomMultiplier: CGFloat = 1.50
    private let holePadding: CGFloat = 12

    // Container + donut mask
    private let ringContainer = CALayer()
    private let ringMask = CAShapeLayer()

    // Normal strokes (temperature / neon static)
    private let coreStroke = CAShapeLayer()
    private let featherStroke = CAShapeLayer()
    private let bloomStroke = CAShapeLayer()

    // Neon “3 sectors” layer, clipped by ringContainer.mask (donut even-odd)
    private let neonFillLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        ringContainer.backgroundColor = NSColor.clear.cgColor
        layer?.addSublayer(ringContainer)

        // Donut mask
        ringMask.fillRule = .evenOdd
        ringMask.fillColor = NSColor.black.cgColor
        ringContainer.mask = ringMask

        // Neon fill (conic)
        neonFillLayer.type = .conic
        neonFillLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        neonFillLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        neonFillLayer.isHidden = true
        ringContainer.addSublayer(neonFillLayer)

        // Strokes
        [bloomStroke, featherStroke, coreStroke].forEach { s in
            s.fillColor = NSColor.clear.cgColor
            s.lineJoin = .round
            s.lineCap = .round
            ringContainer.addSublayer(s)
        }

        // Bloom defaults
        bloomStroke.shadowOpacity = 1
        bloomStroke.shadowRadius = 80
        bloomStroke.shadowOffset = .zero

        updateAppearance(
            brightness: 0.55,
            temperatureK: 6500,
            neonEnabled: false,
            neonPreset: .blue,
            neonMode: .static,
            animated: false
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        ringContainer.frame = bounds
        neonFillLayer.frame = bounds

        rebuildPaths()

        CATransaction.commit()
    }

    private func rebuildPaths() {
        let b = CGRect(
            x: contentInsets.left,
            y: contentInsets.bottom,
            width: bounds.width - contentInsets.left - contentInsets.right,
            height: bounds.height - contentInsets.top - contentInsets.bottom
        )

        let half = ringThickness / 2
        let outerRect = b.insetBy(dx: half + outerInset, dy: half + outerInset)

        // Radius from b so outerInset negative doesn't over-round corners
        let radius = min(b.width, b.height) * radiusRatio
        let outerPath = CGPath(
            roundedRect: outerRect,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        let innerRect = b.insetBy(
            dx: ringThickness + holePadding + outerInset,
            dy: ringThickness + holePadding + outerInset
        )
        let innerRadius = max(0, radius - (ringThickness + holePadding) * 0.45)
        let innerPath = CGPath(
            roundedRect: innerRect,
            cornerWidth: innerRadius,
            cornerHeight: innerRadius,
            transform: nil
        )

        let combined = CGMutablePath()
        combined.addPath(outerPath)
        combined.addPath(innerPath)
        ringMask.path = combined

        coreStroke.path = outerPath
        featherStroke.path = outerPath
        bloomStroke.path = outerPath

        coreStroke.lineWidth = ringThickness
        featherStroke.lineWidth = ringThickness * featherMultiplier
        bloomStroke.lineWidth = ringThickness * bloomMultiplier

        bloomStroke.shadowPath = outerPath
    }

    // MARK: - Public API

    func updateAppearance(brightness: Double,
                          temperatureK: Double,
                          neonEnabled: Bool,
                          neonPreset: SettingsStore.NeonPreset,
                          neonMode: SettingsStore.NeonMode,
                          animated: Bool) {

        // Reset transforms to avoid “tercampur”
        ringContainer.transform = CATransform3DIdentity
        neonFillLayer.transform = CATransform3DIdentity
        coreStroke.transform = CATransform3DIdentity
        featherStroke.transform = CATransform3DIdentity
        bloomStroke.transform = CATransform3DIdentity

        stopBlink()
        stopNeonMove()

        // brightness curve
        let a = min(1.0, pow(CGFloat(brightness), 0.55) * 1.25)

        if neonEnabled {
            switch neonMode {
            case .static:
                applyNeonStatic(intensity: a, preset: neonPreset, animated: animated)

            case .blink:
                applyNeonStatic(intensity: a, preset: neonPreset, animated: animated)
                startBlink()

            case .move:
                applyNeonMove(intensity: a, lead: neonPreset)
                startNeonMove(intensity: a, lead: neonPreset)
            }
            return
        }

        // Default temperature mode
        neonFillLayer.isHidden = true
        ringContainer.opacity = 1.0

        let base = NSColor(kelvin: temperatureK)
        let glow = base.blended(withFraction: 0.20, of: .white) ?? base
        applySolid(color: glow, intensity: a, animated: animated)
    }

    // MARK: - Solid

    private func applySolid(color: NSColor, intensity a: CGFloat, animated: Bool) {
        neonFillLayer.isHidden = true

        coreStroke.isHidden = false
        featherStroke.isHidden = false
        bloomStroke.isHidden = false

        let apply = { [weak self] in
            guard let self else { return }
            self.coreStroke.strokeColor = color.withAlphaComponent(a).cgColor
            self.featherStroke.strokeColor = color.withAlphaComponent(a * 0.40).cgColor
            self.bloomStroke.strokeColor = color.withAlphaComponent(a * 0.28).cgColor
            self.bloomStroke.shadowColor = color.withAlphaComponent(a * 1.00).cgColor
        }

        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.12)
            apply()
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            apply()
            CATransaction.commit()
        }
    }

    private func applyNeonStatic(intensity a: CGFloat,
                                 preset: SettingsStore.NeonPreset,
                                 animated: Bool) {
        ringContainer.opacity = 1.0
        let solid = neonSolidColor(for: preset)
        applySolid(color: solid, intensity: a, animated: animated)
    }

    // MARK: - Neon colors

    private func neonSolidColor(for preset: SettingsStore.NeonPreset) -> NSColor {
        switch preset {
        case .blue:
            return NSColor(calibratedRed: 0.20, green: 0.75, blue: 1.00, alpha: 1.0)
        case .purple:
            return NSColor(calibratedRed: 0.70, green: 0.25, blue: 1.00, alpha: 1.0)
        case .gold:
            return NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.22, alpha: 1.0)
        }
    }

    private func neonTrio(lead: SettingsStore.NeonPreset) -> [NSColor] {
        let blue = neonSolidColor(for: .blue)
        let purple = neonSolidColor(for: .purple)
        let gold = neonSolidColor(for: .gold)

        switch lead {
        case .blue: return [blue, purple, gold]
        case .purple: return [purple, gold, blue]
        case .gold: return [gold, blue, purple]
        }
    }

    // MARK: - Blink

    private func startBlink() {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 1.0
        anim.toValue = 0.25
        anim.duration = 0.55
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ringContainer.add(anim, forKey: "neonBlink.opacity")
    }

    private func stopBlink() {
        ringContainer.removeAnimation(forKey: "neonBlink.opacity")
        ringContainer.opacity = 1.0
    }

    // MARK: - Neon Move (NO rotation)

    private func applyNeonMove(intensity a: CGFloat, lead: SettingsStore.NeonPreset) {
        // ring shape stays (mask), only colors cycle
        coreStroke.isHidden = true
        featherStroke.isHidden = true
        bloomStroke.isHidden = false

        bloomStroke.strokeColor = NSColor.white.withAlphaComponent(a * 0.10).cgColor
        bloomStroke.shadowColor = NSColor.white.withAlphaComponent(a * 0.85).cgColor

        neonFillLayer.isHidden = false

        let trio = neonTrio(lead: lead)

        // 3 sectors fixed by locations
        neonFillLayer.locations = [0.0, 0.333, 0.666, 1.0] as [NSNumber]
        neonFillLayer.colors = [
            trio[0].withAlphaComponent(a).cgColor,
            trio[1].withAlphaComponent(a).cgColor,
            trio[2].withAlphaComponent(a).cgColor,
            trio[0].withAlphaComponent(a).cgColor
        ]
    }

    private func startNeonMove(intensity a: CGFloat, lead: SettingsStore.NeonPreset) {
        // IMPORTANT: no transform rotation at all
        neonFillLayer.removeAnimation(forKey: "neonFill.rotate")
        neonFillLayer.removeAnimation(forKey: "neonFill.colorsCycle")

        let trio = neonTrio(lead: lead)

        let c0 = trio[0].withAlphaComponent(a).cgColor
        let c1 = trio[1].withAlphaComponent(a).cgColor
        let c2 = trio[2].withAlphaComponent(a).cgColor

        // Cycle colors across fixed sectors (chasing without rotating geometry)
        let kf = CAKeyframeAnimation(keyPath: "colors")
        kf.values = [
            [c0, c1, c2, c0],
            [c2, c0, c1, c2],
            [c1, c2, c0, c1],
            [c0, c1, c2, c0]
        ]
        kf.keyTimes = [0.0, 0.333, 0.666, 1.0] as [NSNumber]
        kf.duration = 1.6
        kf.repeatCount = .infinity
        // Use discrete for “switching lanes”; change to .linear if you want crossfade.
        kf.calculationMode = .discrete

        neonFillLayer.add(kf, forKey: "neonFill.colorsCycle")
    }

    private func stopNeonMove() {
        neonFillLayer.removeAnimation(forKey: "neonFill.rotate")
        neonFillLayer.removeAnimation(forKey: "neonFill.colorsCycle")
        neonFillLayer.isHidden = true
    }
}

extension NSEdgeInsets {
    static var zero: NSEdgeInsets { NSEdgeInsetsZero }
}
