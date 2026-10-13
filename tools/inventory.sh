#!/usr/bin/env bash

echo "========================================"
echo " VioletHUD THEME INVENTORY"
echo "========================================"

section() {
    echo
    echo "===== $1 ====="
}

section "PLASMA / KDE SETTINGS"

echo "--- Application Style ---"
kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null

echo "--- Color Scheme ---"
kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null

echo "--- Icon Theme ---"
kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null

echo "--- Cursor Theme ---"
kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null
kreadconfig6 --file kcminputrc --group Mouse --key cursorSize 2>/dev/null

echo "--- Window Decoration ---"
kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library 2>/dev/null
kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme 2>/dev/null

echo "--- Plasma Look & Feel ---"
kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null

echo "--- KSplash ---"
kreadconfig6 --file ksplashrc --group KSplash --key Theme 2>/dev/null


section "COLOR SCHEMES"

echo "--- User color schemes ---"
find ~/.local/share/color-schemes /usr/share/color-schemes \
    -maxdepth 2 -type f 2>/dev/null \
    | grep -Ei 'VioletHUD|kvtheme|colors' | sort


section "LOOK & FEEL"

find ~/.local/share/plasma/look-and-feel /usr/share/plasma/look-and-feel \
    -maxdepth 2 -type f -name metadata.json 2>/dev/null \
    | sort


section "WINDOW DECORATIONS"

echo "--- User decorations ---"
find ~/.local/share/kwin ~/.local/share/kwin* \
    -maxdepth 5 -type f 2>/dev/null \
    | grep -Ei 'VioletHUD|metadata|decoration' | sort

echo "--- System decorations ---"
find /usr/share/kwin* /usr/share/plasma \
    -maxdepth 5 -type f 2>/dev/null \
    | grep -Ei 'VioletHUD|metadata|decoration' | sort


section "KWIN WINDOW RULES"

echo "--- kwinrc rules ---"
grep -nE '^\[.*\]|^Description=|^opacity|^types=|^wmclass|^wmclassmatch' \
    ~/.config/kwinrc 2>/dev/null


section "KWIN SCRIPTS"

find ~/.local/share/kwin/scripts \
    -maxdepth 4 -type f 2>/dev/null | sort


section "ICONS"

echo "--- SoursCompiled ---"
find ~/.local/share/icons /usr/share/icons \
    -maxdepth 2 -type d -iname 'SoursCompiled' 2>/dev/null

echo "--- Icon theme metadata ---"
find ~/.local/share/icons /usr/share/icons \
    -maxdepth 2 -type f -name index.theme 2>/dev/null \
    | while read f; do
        if grep -qi 'SoursCompiled' "$f" 2>/dev/null; then
            echo "$f"
        fi
    done


section "CURSOR"

find ~/.icons ~/.local/share/icons /usr/share/icons \
    -maxdepth 2 -type d -iname 'invader*' 2>/dev/null | sort


section "KONSOLE"

echo "--- Profiles ---"
find ~/.local/share/konsole ~/.config \
    -maxdepth 3 -type f 2>/dev/null \
    | grep -Ei '/konsole/|konsole.*profile|\.profile$' | sort

echo "--- Color schemes ---"
find ~/.local/share/konsole /usr/share/konsole \
    -maxdepth 3 -type f 2>/dev/null \
    | grep -Ei '\.(colorscheme|colors)$|color' | sort


section "SDDM"

echo "--- Active configuration ---"
grep -RniE '^\s*(Current|CursorTheme|CursorSize|Font)=' \
    /etc/sddm.conf /etc/sddm.conf.d 2>/dev/null

echo "--- Active SDDM theme ---"
journalctl -u sddm -b --no-pager 2>/dev/null \
    | grep 'Loading theme configuration' | tail -1

echo "--- SDDM cursor ---"
grep -RniE 'CursorTheme|CursorSize' \
    /etc/sddm.conf /etc/sddm.conf.d 2>/dev/null


section "PLYMOUTH"

echo "--- Active Plymouth theme ---"
readlink -f /etc/alternatives/default.plymouth 2>/dev/null
grep -E '^Theme=' /etc/plymouth/plymouthd.conf 2>/dev/null

echo "--- VioletHUD Plymouth files ---"
find /usr/share/plymouth/themes/VioletHUD \
    -maxdepth 2 -type f 2>/dev/null | sort


section "DESKTOP PANELS & WALLPAPER"

echo "--- Active Wallpaper ---"
grep -E '^\s*Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null

echo "--- Active Panels (Containments) ---"
grep -E '^\s*\[Containments\]\[[0-9]+\]' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null

echo "--- Panel Views (plasmashellrc) ---"
grep -E '^\s*\[PlasmaViews\]\[Panel [0-9]+\]' ~/.config/plasmashellrc 2>/dev/null


section "WALLPAPERS / CUSTOM ASSETS"

find ~/.local/share/wallpapers /usr/share/wallpapers \
    -maxdepth 3 -type f 2>/dev/null \
    | grep -Ei 'VioletHUD|alienware|purple' | sort


section "CUSTOM THEME FILE SEARCH"

echo "--- VioletHUD files in home ---"
find ~/.config ~/.local/share ~/.icons \
    -type f 2>/dev/null \
    | grep -Ei 'VioletHUD|Translucent|opacity|kvtheme' \
    | sort

echo
echo "========================================"
echo " END INVENTORY"
echo "========================================"
