# VioletHUD 🔮

> A comprehensive, cyber-violet HUD theme suite and floating desktop experience designed for **KDE Plasma 6** on Kubuntu and modern Linux distributions.

[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-3daee9?style=flat-square&logo=kde)](https://kde.org/plasma-desktop/)
[![Platform](https://img.shields.io/badge/Platform-Kubuntu%20%7C%20Ubuntu%20%7C%20Linux-E95420?style=flat-square&logo=ubuntu)](https://kubuntu.org/)
[![License](https://img.shields.io/badge/License-GPLv3-blue?style=flat-square)](LICENSE)
[![Theme Style](https://img.shields.io/badge/Style-Cyber%20Violet%20HUD-8A2BE2?style=flat-square)](#)

---

## 🌟 Overview

**VioletHUD** transforms your KDE Plasma 6 desktop into an integrated, cybernetic violet workstation. It coordinates everything from the UEFI boot splash and login manager to glowing vector window decorations, translucent windows, customized system monitors, and a modular 5-piece floating HUD panel system.

---

## 🧩 Components Suite

| Component | Asset / Package | Target Path | Description |
| :--- | :--- | :--- | :--- |
| **Window Decoration** | `assets/aurorae/VioletHUD` | `/usr/share/aurorae/themes/` | Neon violet vector borders and buttons |
| **Color Scheme** | `PurpleHUD.colors` | `/usr/share/color-schemes/` | High-contrast neon violet and obsidian palette |
| **Cursor Theme** | `invader-64-purple` (Alienware Purple) | `/usr/share/icons/` | Full animated Alienware purple cursor suite at 48px/64px |
| **Icon Theme** | `SoursCompiled` | `/usr/share/icons/` | Custom glowing icon theme |
| **Widget Style** | `VioletHUD` (Kvantum) | `/usr/share/Kvantum/` | Translucent SVG widget styling |
| **Konsole** | `VioletHUD.profile` + `VioletHUD.colorscheme` | `/usr/share/konsole/` | Cyberpunk terminal profile (selected as default) |
| **Profile Avatar** | `assets/avatar/user-avatar.png` | `~/.face` & AccountsService | High-res Alienware violet badge profile picture |
| **Splash Screen** | `VioletHUD` Look-and-Feel | `/usr/share/plasma/look-and-feel/` | Clean animated startup splash |
| **Desktop Panels** | 5 Floating HUD Panels | `~/.config/` | Weather, Monitors, Dock, Clock, Tray |
| **Window Rules** | `Translucent-Windows.rules` | `~/.config/kwinrulesrc` | Window translucency & KWin script |
| **Login Screen** | `kde_settings.conf` + `theme.conf.user` | `/etc/sddm.conf.d/` & SDDM themes | SDDM Breeze with VioletHUD wallpaper & Invader cursor |
| **Boot Splash** | `VioletHUD` Plymouth | `/usr/share/plymouth/themes/` | High-resolution boot splash with glowing progress dots |
| **Wallpaper** | `VioletHUD` (Alienware Purple) | `/usr/share/wallpapers/` | High-definition 1080p HUD wallpaper |

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/CyberRoamer/kubuntu26theme-violetHUD.git
cd violetHUD-repo
```

### 2. Run the Automated Installer
The installer automates asset deployment, permissions, cache rebuilding, and Plasma activation:

```bash
# Full installation (Themes + Wallpaper + 5 Floating HUD Panels)
sudo ./install.sh

# Theme only (Install styles & assets, preserve existing panels)
sudo ./install.sh --no-panels

# Panels only (Apply only wallpaper and floating HUD panels)
sudo ./install.sh --panels-only
```

> **Note on Backups:**  
> The installer automatically creates a safety snapshot of existing configurations under `/var/backups/violethud/` before making any changes.

---

## 🖥️ Desktop Panels Layout

The `--all` installation configures a modular 5-piece floating HUD layout:

```
+-----------------------------------------------------------------------------------+
| [Delhi Weather]                                          [CPU | MEM | CORES | NET]|
| (Floating Panel 100)                                       (Floating Panel 102)   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                   [Kickoff | AppMenu | Icons Dock]    [Clock | Bat]   [Tray | User]|
|                         (Floating Panel 53)          (Panel 56)      (Panel 81)   |
+-----------------------------------------------------------------------------------+
```

* **System Monitors:** Calibrated in deep violet (`#300090`) for CPU, Memory, and Network load.
* **Dock:** Floating and transparent (`panelOpacity=0`) with pinned launchers.

---

## 🔄 Uninstallation

To cleanly remove all installed theme assets and restore your original configurations from backup:

```bash
sudo ./uninstall.sh
```

---

## 🛠️ Repository Structure

```
violetHUD-repo/
├── assets/                 # All theme asset trees
│   ├── aurorae/            # Window decoration SVGs
│   ├── color-schemes/      # KDE color scheme files
│   ├── cursors/            # Purple cursor themes
│   ├── icons/              # SoursCompiled icon theme
│   ├── konsole/            # Konsole profiles & colors
│   ├── kvantum/            # Kvantum SVG theme
│   ├── kwin/               # KWin rules and opacity script
│   ├── plasma/             # Look-and-Feel splash & panels
│   ├── plymouth/           # Boot splash theme
│   ├── sddm/               # SDDM login configuration
│   └── wallpapers/         # 1080p Wallpaper package
├── docs/                   # Documentation & manuals
│   ├── COMPONENTS.md       # Technical component specs
│   ├── MANUAL_INSTALL.md   # Step-by-step manual setup
│   └── TROUBLESHOOTING.md  # Common issues and solutions
├── tools/                  # Developer utilities
│   ├── build-tarball.sh    # Release packaging script
│   └── inventory.sh        # System configuration auditor
├── install.sh              # Unified installer
├── uninstall.sh            # Unified uninstaller
└── README.md
```

---

## 📖 Further Documentation

* [Component Specifications](docs/COMPONENTS.md)
* [Manual Installation Guide](docs/MANUAL_INSTALL.md)
* [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
