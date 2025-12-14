# <img width="64" height="64" alt="AppGlyphLarge" src="https://github.com/user-attachments/assets/83bbf5fb-052c-4171-b3e3-a0b32495d00d" /> EdgeLightBar

A minimal macOS menu bar utility to control an EdgeLight-style overlay (brightness, color temperature, and display targeting).
Designed primarily for Intel Macs and older macOS setups that don’t support the newer EdgeLight experience available on macOS Tahoe 26.2. <br><br>
* `EdgeLightBar-Preview`
* <details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/33109330-19d0-4060-aa7e-77815f66d94a" alt="EdgeLightBar-Preview">
</details>

## Why EdgeLightBar?
Some Macs (especially Intel models and older macOS versions) don’t receive newer system UI features.
EdgeLightBar provides a simple, lightweight alternative focused on fast access from the menu bar.

## Key capabilities
- <details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/2b95c3a4-a1d3-4857-9d25-0c0838dd7a1b" alt="EdgeLightBar-Menu">
</details>

- Quick on/off
- Brightness and color temperature adjustments
- Choose one display or apply to all displays
- Optional “Exclude from Capture” toggle (when supported)

## System requirements
- macOS Ventura (13) or later

## Install
### Prebuilt (recommended)
- Download the latest release from GitHub Releases.
- Move the app to /Applications and launch it.

### Build it yourself
```bash
git clone https://github.com/Cmalf-Labs/EdgeLightBar.git
cd EdgeLightBar
```
open EdgeLightBar.xcodeproj
Then build and run in Xcode.

## Contributing

This project is open-source and Contributions, bug reports, and feature suggestions are very welcome!

-  Fork this repo and create a pull request.

-  Please open an [issue](https://github.com/cmalf-labs/EdgeLightBar/issues) to suggest enhancements or submit found bugs.

-  All levels of contributors are encouraged to participate.

## FAQ

| Question | Answer |
| :--- | :--- |
| **What does EdgeLightBar do?** | EdgeLightBar is a macOS menu bar app that lets you control an EdgeLight-style overlay quickly (toggle on/off, adjust brightness, and change color temperature). It also includes multi-monitor options (switch a target display or apply to all displays) plus an “Exclude from Capture” toggle when supported. |
| **How do I use it with multiple monitors (or record my screen)?** | Use “Switch Monitor” to cycle the target display, or enable “All Monitors” to show the overlay across every connected screen. For screen recording/screenshots, try enabling “Exclude from Capture”; availability/behavior can vary by macOS capture method and app. |
| **Is there any telemetry?** | No. EdgeLightBar never tracks your activity or sends data to third parties. |

## Acknowledgments

-   EdgeLightBar is developed and maintained by [Cmalf-Labs.](https://github.com/cmalf-labs)

-   Icon and UI are designed for a clean macOS experience.

-   This project is open source and made with ❤️ for the Mac,Hack community.

## Support
If you enjoy using EdgeLightBar, please consider supporting its development!
Several cryptocurrency donation options are available.

- Binance Pay ID: 96771283
- Bybit Pay ID: 117943952
- Solana (SOL): SoLMyRa3FGfjSD8ie6bsXK4g4q8ghSZ4E6HQzXhyNGG
- EVM (ETH/BSC/etc): 0xbeD69b650fDdB6FBB528B0fF7a15C24DcAd87FC4

## License
EdgeLightBar is free software released under the **GNU General Public License v3.0 or later**. You can redistribute it and/or modify it under the terms of this license.
See the [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) file for more details.
