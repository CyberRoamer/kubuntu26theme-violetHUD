# VioletHUD Component Specifications

This document outlines the technical details and installation targets for each module in the **VioletHUD** theme suite for **KDE Plasma 6**.

---

## 1. Window Decoration (Aurorae)
* **Path:** `assets/aurorae/VioletHUD`
* **Target:** `/usr/share/aurorae/themes/VioletHUD`
* **Config Key:** `kwinrc` -> `[org.kde.kdecoration2]` -> `theme=__aurorae__svg__VioletHUD`
* **Description:** Custom vector-drawn Aurorae decoration with a dark violet glow, custom window controls (minimize, maximize, close, keep-above, keep-below, restore, and alldesktops).

---

## 2. Color Schemes
* **Paths:**
  * `assets/color-schemes/PurpleHUD.colors`
  * `assets/color-schemes/LavenderHUD.colors`
* **Target:** `/usr/share/color-schemes/`
* **Config Key:** `kdeglobals` -> `[General]` -> `ColorScheme=PurpleHUD`
* **Description:** High-contrast dark themes featuring curated violet and purple accents (`#300090`, `#900060`, `#2b0050`) calibrated for terminal and desktop productivity.

---

## 3. Cursor Theme
* **Path:** `assets/cursors/invader-64-purple` (Alienware Purple)
* **Target:** `/usr/share/icons/`
* **Config Key:** `kcminputrc` -> `[Mouse]` -> `cursorTheme=invader-64-purple`, `cursorSize=48`
* **Description:** Sharp, futuristic high-DPI purple cursor sets supporting animated states, Wayland, and X11 cursor specifications.

---

## 4. Icon Theme
* **Path:** `assets/icons/SoursCompiled`
* **Target:** `/usr/share/icons/SoursCompiled`
* **Config Key:** `kdeglobals` -> `[Icons]` -> `Theme=SoursCompiled`
* **Description:** Comprehensive icon suite customized with glowing violet folders, system tray symbols, and app category icons.

---

## 5. Kvantum Widget Style
* **Path:** `assets/kvantum/VioletHUD`
* **Target:** `/usr/share/Kvantum/VioletHUD`
* **Description:** Complete Qt application styling engine configuration providing translucent window surfaces, rounded violet controls, and widget glow effects.

---

## 6. Konsole Profile & Colors
* **Paths:**
  * `assets/konsole/VioletHUD.profile`
  * `assets/konsole/Tronnix.colorscheme`
* **Target:** `/usr/share/konsole/`
* **Description:** Semi-transparent terminal profile with neon purple syntax highlighting and custom ANSI color mapping.

---

## 7. Splash Screen (Plasma Look-and-Feel)
* **Path:** `assets/plasma/look-and-feel/VioletHUD`
* **Target:** `/usr/share/plasma/look-and-feel/VioletHUD`
* **Config Key:** `ksplashrc` -> `[KSplash]` -> `Theme=VioletHUD`
* **Description:** Plasma 6 splash animation cleanly self-branded without external welcome text.

---

## 8. Desktop Panels & Layout
* **Paths:**
  * `assets/plasma/panels/plasma-org.kde.plasma.desktop-appletsrc`
  * `assets/plasma/panels/plasmashellrc`
* **Target:** `~/.config/`
* **Description:** Modular 5-piece floating HUD desktop panel arrangement:
  1. **Top-Left:** Weather monitor.
  2. **Top-Right:** Hardware monitors (CPU, Memory, Cores, Network in purple `#300090`).
  3. **Bottom-Center:** Translucent dock (Global menu, Icons-Only Task Manager, Kickoff).
  4. **Bottom-Right:** Digital clock and battery level.
  5. **Bottom-Far-Right:** System Tray and user profile switch.

---

## 9. KWin Scripts & Rules
* **Paths:**
  * `assets/kwin/scripts/toggle-window-opacity`
  * `assets/kwin/rules/Translucent-Windows.rules`
* **Targets:**
  * Script: `/usr/share/kwin/scripts/toggle-window-opacity`
  * Rule: Injected into `~/.config/kwinrulesrc`
* **Description:** Enables window translucency and provides a keyboard-toggleable window opacity script.

---

## 10. SDDM Login Screen
* **Path:** `assets/sddm/kde_settings.conf`
* **Target:** `/etc/sddm.conf.d/kde_settings.conf`
* **Description:** Standardizes the login screen to Breeze dark mode with the `invader-64-purple` cursor at 48px.

---

## 11. Plymouth Boot Theme
* **Path:** `assets/plymouth/VioletHUD`
* **Target:** `/usr/share/plymouth/themes/VioletHUD`
* **Registration:** `plymouth-set-default-theme -R VioletHUD`
* **Description:** High-resolution boot splash with blurred background transition and centered logo.

---

## 12. Wallpaper
* **Path:** `assets/wallpapers/VioletHUD`
* **Target:** `/usr/share/wallpapers/VioletHUD`
* **Description:** 1920x1080 Alienware Purple wallpaper structured as a standard KDE Wallpaper package.
