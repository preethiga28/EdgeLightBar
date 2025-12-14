/*
 * File: StatusBarController.swift
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
import SwiftUI

final class StatusBarController: NSObject {

    private let settings: SettingsStore
    private let overlayManager: OverlayManager
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    // Custom controls
    private let toggleView = ToggleRowView(title: "Light")
    private let brightnessView = SliderRowView(title: "Brightness",
                                               systemImageName: "sun.max",
                                               min: 0.10, max: 1.00)
    private let tempView = SliderRowView(title: "Color Temp",
                                         systemImageName: "thermometer.medium",
                                         min: 3000, max: 9000)

    // NeonLight Fun
    private let neonToggleView = ToggleRowView(title: "NeonLight Fun")

    // Neon submenu
    private let neonMenuItem = NSMenuItem(title: "NeonColor", action: nil, keyEquivalent: "")
    private let neonSubmenu = NSMenu()

    private let neonBlueItem   = NSMenuItem(title: "Blue",   action: #selector(setNeonBlue),   keyEquivalent: "")
    private let neonPurpleItem = NSMenuItem(title: "Purple", action: #selector(setNeonPurple), keyEquivalent: "")
    private let neonGoldItem   = NSMenuItem(title: "Gold",   action: #selector(setNeonGold),   keyEquivalent: "")

    // Mode submenu
    private let modeMenuItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
    private let modeSubmenu = NSMenu()

    private let modeStaticItem = NSMenuItem(title: "Static", action: #selector(setNeonStatic), keyEquivalent: "")
    private let modeBlinkItem  = NSMenuItem(title: "Blink",  action: #selector(setNeonBlink),  keyEquivalent: "")
    private let modeMoveItem   = NSMenuItem(title: "Move",   action: #selector(setNeonMove),   keyEquivalent: "")

    // Regular items
    private let switchMonitorItem = NSMenuItem(title: "Switch Monitor", action: #selector(switchMonitor), keyEquivalent: "m")
    private let allMonitorsItem = NSMenuItem(title: "All Monitors", action: #selector(toggleAllMonitors), keyEquivalent: "a")
    private let excludeCaptureItem = NSMenuItem(title: "Exclude from Capture", action: #selector(toggleExcludeFromCapture), keyEquivalent: "e")
    private let exitItem = NSMenuItem(title: "Exit", action: #selector(exitApp), keyEquivalent: "q")
    private let donateItem = NSMenuItem(title: "Donate", action: #selector(openDonate), keyEquivalent: "")
    private let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "")
    private let aboutWC = AboutWindowController()
    private let footerItem = NSMenuItem()
    private let footerView = FooterRowView(text: "© 2025-2026 Cmalf-Labs. All rights reserved.")

    init(settings: SettingsStore, overlayManager: OverlayManager) {
        self.settings = settings
        self.overlayManager = overlayManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(named: "AppGlyphSmall") ?? NSImage(named: "AppGlyphLarge")
            button.image?.isTemplate = true
            button.imagePosition = .imageOnly
        }

        configureMenu()
        hookUpActions()
        refreshMenuState()
    }

    private func configureMenu() {
        let toggleItem = NSMenuItem()
        toggleItem.view = toggleView
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let bItem = NSMenuItem()
        bItem.view = brightnessView
        menu.addItem(bItem)

        let tItem = NSMenuItem()
        tItem.view = tempView
        menu.addItem(tItem)

        menu.addItem(.separator())

        // Neon toggle row
        let neonItem = NSMenuItem()
        neonItem.view = neonToggleView
        menu.addItem(neonItem)

        // Target
        [neonBlueItem, neonPurpleItem, neonGoldItem,
         modeStaticItem, modeBlinkItem, modeMoveItem].forEach { $0.target = self }

        // Build Neon submenu
        neonSubmenu.addItem(neonBlueItem)
        neonSubmenu.addItem(neonPurpleItem)
        neonSubmenu.addItem(neonGoldItem)
        neonMenuItem.submenu = neonSubmenu
        menu.addItem(neonMenuItem)

        // Build Mode submenu
        modeSubmenu.addItem(modeStaticItem)
        modeSubmenu.addItem(modeBlinkItem)
        modeSubmenu.addItem(modeMoveItem)
        modeMenuItem.submenu = modeSubmenu
        menu.addItem(modeMenuItem)

        menu.addItem(.separator())

        switchMonitorItem.target = self
        allMonitorsItem.target = self
        excludeCaptureItem.target = self
        exitItem.target = self

        menu.addItem(switchMonitorItem)
        menu.addItem(allMonitorsItem)
        menu.addItem(.separator())
        menu.addItem(excludeCaptureItem)
        menu.addItem(.separator())
        menu.addItem(aboutItem)
        aboutItem.target = self
        menu.addItem(.separator())
        menu.addItem(donateItem)
        donateItem.target = self
        menu.addItem(.separator())
        menu.addItem(exitItem)
        menu.addItem(.separator())
        footerItem.view = footerView
        footerItem.isEnabled = false
        menu.addItem(footerItem)

        statusItem.menu = menu
    }

    private func hookUpActions() {
        toggleView.onToggle = { [weak self] isOn in
            guard let self else { return }
            self.settings.isLightOn = isOn
            self.overlayManager.applyCurrentSettings(animated: true)
            self.refreshMenuState()
        }

        brightnessView.onChange = { [weak self] value in
            guard let self else { return }
            self.settings.brightness = value
            self.overlayManager.applyCurrentSettings(animated: true)
        }

        tempView.onChange = { [weak self] value in
            guard let self else { return }
            self.settings.colorTemperature = value
            self.overlayManager.applyCurrentSettings(animated: true)
        }

        neonToggleView.onToggle = { [weak self] isOn in
            guard let self else { return }
            self.settings.neonEnabled = isOn
            self.overlayManager.applyCurrentSettings(animated: true)
            self.refreshMenuState()
        }
    }

    func refreshMenuState() {
        toggleView.setOn(settings.isLightOn)
        brightnessView.setValue(settings.brightness)
        tempView.setValue(settings.colorTemperature)
        donateItem.isEnabled = true

        neonToggleView.setOn(settings.neonEnabled)

        // Disable neon controls when off (gray)
        let neonOn = settings.neonEnabled
        // gray/disable submenu saat Neon OFF
        neonMenuItem.isEnabled = neonOn
        modeMenuItem.isEnabled = neonOn

        // checkmark untuk pilihan Neon
        neonBlueItem.state   = (neonOn && settings.neonPreset == .blue) ? .on : .off
        neonPurpleItem.state = (neonOn && settings.neonPreset == .purple) ? .on : .off
        neonGoldItem.state   = (neonOn && settings.neonPreset == .gold) ? .on : .off

        // checkmark untuk Mode
        modeStaticItem.state = (neonOn && settings.neonMode == .static) ? .on : .off
        modeBlinkItem.state  = (neonOn && settings.neonMode == .blink) ? .on : .off
        modeMoveItem.state   = (neonOn && settings.neonMode == .move) ? .on : .off

        // Regular
        allMonitorsItem.state = settings.useAllMonitors ? .on : .off
        excludeCaptureItem.state = settings.excludeFromCapture ? .on : .off

        let screens = NSScreen.screens
        let multi = screens.count > 1
        switchMonitorItem.isEnabled = multi && !settings.useAllMonitors

        if !screens.isEmpty, settings.currentMonitorIndex >= screens.count {
            settings.currentMonitorIndex = screens.count - 1
        }
    }
    
    // About
    
    @objc private func openAbout() {
        aboutWC.show()
    }
    
    // Donate
    
    @objc private func openDonate() {
        guard let url = URL(string: "https://github.com/cmalf/cmalf/blob/main/QR-Code/Support.md") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Neon actions

    @objc private func setNeonBlue() {
        settings.neonPreset = .blue
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func setNeonPurple() {
        settings.neonPreset = .purple
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func setNeonGold() {
        settings.neonPreset = .gold
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func setNeonStatic() {
        settings.neonMode = .static
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func setNeonBlink() {
        settings.neonMode = .blink
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func setNeonMove() {
        settings.neonMode = .move
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    // MARK: - Regular actions

    @objc private func switchMonitor() {
        let screens = NSScreen.screens
        guard screens.count > 1 else { NSSound.beep(); return }
        settings.currentMonitorIndex = (settings.currentMonitorIndex + 1) % screens.count
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func toggleAllMonitors() {
        settings.useAllMonitors.toggle()
        overlayManager.applyCurrentSettings(animated: true)
        refreshMenuState()
    }

    @objc private func toggleExcludeFromCapture() {
        settings.excludeFromCapture.toggle()
        overlayManager.applyCurrentSettings(animated: false)
        refreshMenuState()
    }

    @objc private func exitApp() {
        settings.save()
        overlayManager.teardownAll()
        NSApp.terminate(nil)
    }

    // MARK: - Menu custom views

    class MenuRowBaseView: NSView {
        private let selectionBackground = NSVisualEffectView()
        override var allowsVibrancy: Bool { true }

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            selectionBackground.blendingMode = .withinWindow
            selectionBackground.state = .active
            selectionBackground.material = .selection
            selectionBackground.isHidden = true
            addSubview(selectionBackground, positioned: .below, relativeTo: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            selectionBackground.frame = bounds
        }

        override func viewWillDraw() {
            super.viewWillDraw()
            updateHighlight()
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            updateHighlight()
        }

        private func updateHighlight() {
            let highlighted = (enclosingMenuItem?.isHighlighted == true)
            selectionBackground.isHidden = !highlighted
        }
    }

    final class ToggleRowView: MenuRowBaseView {
        private let titleLabel = NSTextField(labelWithString: "")
        private let stateLabel = NSTextField(labelWithString: "")
        private let toggle = NSSwitch()

        var onToggle: ((Bool) -> Void)?

        init(title: String) {
            super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 28))
            titleLabel.stringValue = title
            titleLabel.font = .systemFont(ofSize: 13)

            stateLabel.font = .systemFont(ofSize: 12)
            stateLabel.textColor = .secondaryLabelColor
            stateLabel.alignment = .right

            toggle.target = self
            toggle.action = #selector(changed)

            addSubview(titleLabel)
            addSubview(stateLabel)
            addSubview(toggle)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            let padding: CGFloat = 12
            toggle.sizeToFit()
            toggle.frame.origin = CGPoint(x: bounds.maxX - padding - toggle.frame.width,
                                          y: (bounds.height - toggle.frame.height) / 2)
            stateLabel.frame = CGRect(x: toggle.frame.minX - 54, y: 4, width: 50, height: bounds.height - 8)
            titleLabel.frame = CGRect(x: padding, y: 4,
                                      width: bounds.width - padding * 2 - toggle.frame.width - 70,
                                      height: bounds.height - 8)
        }

        func setOn(_ on: Bool) {
            toggle.state = on ? .on : .off
            stateLabel.stringValue = on ? "On" : "Off"
            needsLayout = true
            needsDisplay = true
        }

        @objc private func changed() {
            let isOn = (toggle.state == .on)
            setOn(isOn)
            onToggle?(isOn)
        }
    }
    
    final class FooterRowView: NSView {
        override var allowsVibrancy: Bool { true }

        private let label = NSTextField(labelWithString: "")

        init(text: String) {
            super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 22))
            label.stringValue = text
            label.font = .systemFont(ofSize: 10)
            label.textColor = .tertiaryLabelColor
            label.alignment = .center
            addSubview(label)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            label.frame = bounds.insetBy(dx: 10, dy: 0)
        }
    }

    final class SliderRowView: MenuRowBaseView {
        private let icon = NSImageView()
        private let titleLabel = NSTextField(labelWithString: "")
        private let valueLabel = NSTextField(labelWithString: "")
        private let slider: NSSlider

        var onChange: ((Double) -> Void)?

        init(title: String, systemImageName: String, min: Double, max: Double) {
            self.slider = NSSlider(value: min, minValue: min, maxValue: max, target: nil, action: nil)
            super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 44))

            titleLabel.stringValue = title
            titleLabel.font = .systemFont(ofSize: 13)

            valueLabel.font = .systemFont(ofSize: 11)
            valueLabel.textColor = .secondaryLabelColor
            valueLabel.alignment = .right

            icon.image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: title)
            icon.symbolConfiguration = .init(pointSize: 13, weight: .regular)

            slider.target = self
            slider.action = #selector(sliderChanged)

            addSubview(icon)
            addSubview(titleLabel)
            addSubview(valueLabel)
            addSubview(slider)

            updateValueLabel()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            let padding: CGFloat = 12
            icon.frame = CGRect(x: padding, y: bounds.height - 22, width: 16, height: 16)
            titleLabel.frame = CGRect(x: icon.frame.maxX + 8, y: bounds.height - 24, width: 150, height: 18)
            valueLabel.frame = CGRect(x: bounds.width - padding - 70, y: bounds.height - 24, width: 70, height: 18)
            slider.frame = CGRect(x: padding, y: 8, width: bounds.width - padding * 2, height: 18)
        }

        func setValue(_ v: Double) {
            slider.doubleValue = v
            updateValueLabel()
            needsDisplay = true
        }

        private func updateValueLabel() {
            if slider.maxValue <= 1.01 {
                valueLabel.stringValue = "\(Int(round(slider.doubleValue * 100)))%"
            } else {
                valueLabel.stringValue = "\(Int(slider.doubleValue))K"
            }
        }

        @objc private func sliderChanged() {
            updateValueLabel()
            onChange?(slider.doubleValue)
        }
    }
}

// MARK: - Window Controller

final class AboutWindowController: NSWindowController {

    private let panel: NSPanel = {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.isReleasedWhenClosed = false
        return p
    }()

    init() {
        let root = AboutView()
        panel.contentViewController = NSHostingController(rootView: root)
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        guard let w = window else { return }
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - SwiftUI View

struct AboutView: View {

    var body: some View {
        ZStack(alignment: .topTrailing) {
            settingsAboutCard
                .padding(18)
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private var settingsAboutCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {

                // App Icon & Name (center)
                VStack(spacing: 10) {
                    Image(nsImage: NSImage(named: "AppGlyphLarge") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)

                    Text(Bundle.main.info("CFBundleName").isEmpty ? "EdgeLightBar" : Bundle.main.info("CFBundleName"))
                        .font(.title3).fontWeight(.semibold)

                    Text("Version \(Bundle.main.info("CFBundleShortVersionString")) (Build \(Bundle.main.info("CFBundleVersion")))")
                        .font(.caption).foregroundStyle(.secondary)

                    Text("A minimal macOS menu bar utility to control an EdgeLight-style overlay (brightness, color temperature, and display targeting).Designed primarily for Intel Macs and older macOS setups that don’t support the newer EdgeLight experience available on macOS Tahoe 26.2.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)
                .padding(.bottom, 10)

                Divider()

                // Open Source Info (center)
                VStack(spacing: 6) {
                    Text("This application is open source and can be found on GitHub:")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Image(systemName: "link").foregroundStyle(.blue)
                            .frame(width: 14, alignment: .center)

                        Link("github.com/cmalf-labs/EdgeLightBar",
                             destination: URL(string: "https://github.com/cmalf-labs/EdgeLightBar")!)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .buttonStyle(.plain)
                    }
                }
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)

                Divider()

                // Contributors (left)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contributors").font(.headline)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Creator").font(.caption).foregroundStyle(.secondary)
                                Text("Cmalf").font(.subheadline).fontWeight(.medium)
                                Text("xcmalf@gmail.com").font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Publisher").font(.caption).foregroundStyle(.secondary)
                                Text("Panca").font(.subheadline).fontWeight(.medium)
                                Text("panca.rad@icloud.com").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Spacer(minLength: 0)

                Divider()

                // System Info (center)
                VStack(spacing: 2) {
                    Text("System Information").font(.caption).foregroundStyle(.secondary)
                    Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Components

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Helpers

extension Bundle {
    func info(_ key: String) -> String {
        (object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}
