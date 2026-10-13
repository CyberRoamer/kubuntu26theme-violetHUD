#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  VioletHUD Complete Theme Suite Installer for KDE Plasma 6
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$REPO_DIR/assets"
BACKUP_DIR="/var/backups/violethud"

INSTALL_MODE="all" # all, no-panels, panels-only

# ANSI Color codes
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

usage() {
    echo -e "${BOLD}Usage:${RESET} sudo ./install.sh [OPTIONS]"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  ${CYAN}--all${RESET}          Install full theme suite and 5 floating HUD panels (default)"
    echo -e "  ${CYAN}--no-panels${RESET}    Install full theme suite, but preserve existing desktop panels"
    echo -e "  ${CYAN}--panels-only${RESET}  Only configure desktop wallpaper and 5 floating HUD panels"
    echo -e "  ${CYAN}-h, --help${RESET}     Show this help message and exit"
    echo
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            INSTALL_MODE="all"
            shift
            ;;
        --no-panels)
            INSTALL_MODE="no-panels"
            shift
            ;;
        --panels-only)
            INSTALL_MODE="panels-only"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            usage
            ;;
    esac
done

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Elevation required. Rerunning with sudo...${RESET}"
    exec sudo "$0" --$INSTALL_MODE "$@"
fi

if [ -z "${SUDO_USER:-}" ]; then
    echo -e "${RED}ERROR: Please run this installer as your normal user via sudo:${RESET}"
    echo "       sudo ./install.sh"
    exit 1
fi

USER_NAME="$SUDO_USER"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
USER_CONFIG="$USER_HOME/.config"
USER_BACKUP="$BACKUP_DIR/user-config"

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    echo -e "${RED}ERROR: Could not resolve home directory for user '$USER_NAME'.${RESET}"
    exit 1
fi

USER_UID="$(id -u "$USER_NAME")"
USER_RUNDIR="/run/user/$USER_UID"

run_as_user() {
    sudo -u "$USER_NAME" \
        env HOME="$USER_HOME" \
            XDG_CONFIG_HOME="$USER_CONFIG" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$USER_RUNDIR/bus}" \
            XDG_RUNTIME_DIR="${USER_RUNDIR:-}" \
        "$@"
}

echo -e "${PURPLE}${BOLD}"
echo "============================================================"
echo "          VioletHUD Complete Theme Suite Installer"
echo "============================================================"
echo -e "${RESET}"
echo -e "${CYAN}Target User:${RESET}    $USER_NAME"
echo -e "${CYAN}Install Mode:${RESET}   $INSTALL_MODE"
echo -e "${CYAN}Backup Dir:${RESET}     $BACKUP_DIR"
echo

mkdir -p "$BACKUP_DIR" "$USER_BACKUP"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

backup_file() {
    local file="$1"
    if [ -e "$file" ] || [ -L "$file" ]; then
        local safe
        safe="$(echo "$file" | sed 's#^/##; s#/#__#g')"
        cp -a "$file" "$BACKUP_DIR/$safe"
        echo -e "  ${YELLOW}[BACKUP]${RESET} $file"
    fi
}

backup_user_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local safe
        safe="$(echo "$file" | sed 's#^/##; s#/#__#g')"
        cp -a "$file" "$USER_BACKUP/$safe"
        echo -e "  ${YELLOW}[BACKUP]${RESET} $file"
    fi
}

install_tree() {
    local src="$1"
    local dst="$2"
    if [ -d "$src" ]; then
        mkdir -p "$dst"
        cp -a "$src"/. "$dst"/
        echo -e "  ${GREEN}[INSTALL]${RESET} $dst"
    fi
}

install_file() {
    local src="$1"
    local dst="$2"
    local mode="${3:-644}"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        install -m "$mode" "$src" "$dst"
        echo -e "  ${GREEN}[INSTALL]${RESET} $dst"
    fi
}

install_user_file() {
    local src="$1"
    local dst="$2"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        chown "$USER_NAME:$USER_NAME" "$dst"
        echo -e "  ${GREEN}[INSTALL]${RESET} $dst"
    fi
}

# ------------------------------------------------------------------------------
# 1. System Assets Installation
# ------------------------------------------------------------------------------

if [[ "$INSTALL_MODE" != "panels-only" ]]; then
    echo -e "${BOLD}${BLUE}>>> Installing System Theme Assets...${RESET}"

    # Icons
    install_tree "$ASSETS_DIR/icons/SoursCompiled" "/usr/share/icons/SoursCompiled"

    # Cursors (Alienware Invader Purple)
    rm -rf /usr/share/icons/Tronnix /usr/share/icons/invader-64-purple
    install_tree "$ASSETS_DIR/cursors/invader-64-purple" "/usr/share/icons/invader-64-purple"


    # Aurorae Window Decoration
    install_tree "$ASSETS_DIR/aurorae/VioletHUD" "/usr/share/aurorae/themes/VioletHUD"

    # Color Schemes
    install_file "$ASSETS_DIR/color-schemes/PurpleHUD.colors" "/usr/share/color-schemes/PurpleHUD.colors"
    if [ -f "$ASSETS_DIR/color-schemes/LavenderHUD.colors" ]; then
        install_file "$ASSETS_DIR/color-schemes/LavenderHUD.colors" "/usr/share/color-schemes/LavenderHUD.colors"
    fi

    # Kvantum Style
    install_tree "$ASSETS_DIR/kvantum/VioletHUD" "/usr/share/Kvantum/VioletHUD"

    # Konsole Profile & Colors
    install_file "$ASSETS_DIR/konsole/VioletHUD.profile" "/usr/share/konsole/VioletHUD.profile"
    install_file "$ASSETS_DIR/konsole/Tronnix.colorscheme" "/usr/share/konsole/Tronnix.colorscheme"

    # Plasma Look-and-Feel (Splash)
    install_tree "$ASSETS_DIR/plasma/look-and-feel/VioletHUD" "/usr/share/plasma/look-and-feel/VioletHUD"

    # KWin Opacity Script
    install_tree "$ASSETS_DIR/kwin/scripts/toggle-window-opacity" "/usr/share/kwin/scripts/toggle-window-opacity"

    # SDDM Login Configuration & Background
    mkdir -p /etc/sddm.conf.d
    backup_file /etc/sddm.conf
    backup_file /etc/sddm.conf.d/kde_settings.conf
    install_file "$ASSETS_DIR/sddm/kde_settings.conf" "/etc/sddm.conf.d/kde_settings.conf"

    # Configure background for Breeze and Kubuntu SDDM themes
    for sddm_theme in breeze kubuntu; do
        if [ -d "/usr/share/sddm/themes/$sddm_theme" ]; then
            backup_file "/usr/share/sddm/themes/$sddm_theme/theme.conf.user"
            install_file "$ASSETS_DIR/sddm/theme.conf.user" "/usr/share/sddm/themes/$sddm_theme/theme.conf.user"
            if [ -f "$ASSETS_DIR/wallpapers/VioletHUD/VioletHUD.jpg" ]; then
                cp -a "$ASSETS_DIR/wallpapers/VioletHUD/VioletHUD.jpg" "/usr/share/sddm/themes/$sddm_theme/VioletHUD.jpg"
                cp -a "$ASSETS_DIR/wallpapers/VioletHUD/VioletHUD.jpg" "/usr/share/sddm/themes/$sddm_theme/alienware_purple.webp" 2>/dev/null || true
            fi
            echo -e "  ${GREEN}[SDDM]${RESET} Configured VioletHUD background for $sddm_theme login theme"
        fi
    done

    # Plymouth Boot Splash
    install_tree "$ASSETS_DIR/plymouth/VioletHUD" "/usr/share/plymouth/themes/VioletHUD"
fi

# Wallpaper (used for both theme and panel setups)
echo -e "${BOLD}${BLUE}>>> Installing VioletHUD Wallpaper...${RESET}"
install_tree "$ASSETS_DIR/wallpapers/VioletHUD" "/usr/share/wallpapers/VioletHUD"

# ------------------------------------------------------------------------------
# 2. Permissions and Cache Registrations
# ------------------------------------------------------------------------------

if [[ "$INSTALL_MODE" != "panels-only" ]]; then
    echo -e "${BOLD}${BLUE}>>> Setting Asset Permissions & Updating Caches...${RESET}"

    chown -R root:root \
        /usr/share/icons/SoursCompiled \
        /usr/share/icons/invader-64-purple \
        /usr/share/aurorae/themes/VioletHUD \
        /usr/share/color-schemes/PurpleHUD.colors \
        /usr/share/Kvantum/VioletHUD \
        /usr/share/konsole/VioletHUD.profile \
        /usr/share/konsole/Tronnix.colorscheme \
        /usr/share/plasma/look-and-feel/VioletHUD \
        /usr/share/kwin/scripts/toggle-window-opacity \
        /usr/share/plymouth/themes/VioletHUD \
        /usr/share/wallpapers/VioletHUD \
        2>/dev/null || true

    find \
        /usr/share/icons/SoursCompiled \
        /usr/share/icons/invader-64-purple \
        /usr/share/aurorae/themes/VioletHUD \
        /usr/share/color-schemes/PurpleHUD.colors \
        /usr/share/Kvantum/VioletHUD \
        /usr/share/konsole/VioletHUD.profile \
        /usr/share/konsole/Tronnix.colorscheme \
        /usr/share/plasma/look-and-feel/VioletHUD \
        /usr/share/kwin/scripts/toggle-window-opacity \
        /usr/share/plymouth/themes/VioletHUD \
        /usr/share/wallpapers/VioletHUD \
        -type f -exec chmod a+r {} \; 2>/dev/null || true

    find \
        /usr/share/icons/SoursCompiled \
        /usr/share/icons/invader-64-purple \
        /usr/share/aurorae/themes/VioletHUD \
        /usr/share/Kvantum/VioletHUD \
        /usr/share/plasma/look-and-feel/VioletHUD \
        /usr/share/kwin/scripts/toggle-window-opacity \
        /usr/share/plymouth/themes/VioletHUD \
        /usr/share/wallpapers/VioletHUD \
        -type d -exec chmod a+rx {} \; 2>/dev/null || true

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f /usr/share/icons/SoursCompiled 2>/dev/null || true
        gtk-update-icon-cache -f /usr/share/icons/invader-64-purple 2>/dev/null || true
    fi

    # System x-cursor-theme registration
    if [ -f "/usr/share/icons/invader-64-purple/index.theme" ]; then
        if command -v update-alternatives >/dev/null 2>&1; then
            update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme \
                /usr/share/icons/invader-64-purple/index.theme 100 2>/dev/null || true
            update-alternatives --set x-cursor-theme \
                /usr/share/icons/invader-64-purple/index.theme 2>/dev/null || true
            echo -e "  ${GREEN}[CURSORS]${RESET} Registered invader-64-purple as default x-cursor-theme"
        fi
    fi

    # Plymouth boot theme registration and initramfs update
    if [ -f "/usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth" ]; then
        if command -v update-alternatives >/dev/null 2>&1; then
            update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
                /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth 100 \
                --slave /usr/share/plymouth/themes/default.grub default.plymouth.grub \
                /usr/share/plymouth/themes/VioletHUD/VioletHUD.grub 2>/dev/null || \
            update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
                /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth 100 2>/dev/null || true

            update-alternatives --set default.plymouth /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth 2>/dev/null || true
            echo -e "  ${GREEN}[PLYMOUTH]${RESET} Registered VioletHUD via update-alternatives"
        fi

        if [ -f /etc/plymouth/plymouthd.conf ]; then
            sed -i 's/^Theme=.*/Theme=VioletHUD/' /etc/plymouth/plymouthd.conf 2>/dev/null || true
        fi

        if command -v update-initramfs >/dev/null 2>&1; then
            echo -e "  ${BLUE}[INITRAMFS]${RESET} Updating initramfs with VioletHUD boot theme..."
            update-initramfs -u 2>/dev/null || true
            echo -e "  ${GREEN}[INITRAMFS]${RESET} Initramfs updated successfully"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 3. User KDE Settings Activation
# ------------------------------------------------------------------------------

if [[ "$INSTALL_MODE" != "panels-only" ]]; then
    echo -e "${BOLD}${BLUE}>>> Applying KDE Plasma User Configurations...${RESET}"

    backup_user_file "$USER_CONFIG/kdeglobals"
    backup_user_file "$USER_CONFIG/kwinrc"
    backup_user_file "$USER_CONFIG/kwinrulesrc"
    backup_user_file "$USER_CONFIG/ksplashrc"
    backup_user_file "$USER_CONFIG/kcminputrc"
    backup_user_file "$USER_CONFIG/konsolerc"

    # User local asset trees (for Wayland / Qt6 / GTK user-level discovery)
    run_as_user mkdir -p \
        "$USER_HOME/.local/share/color-schemes" \
        "$USER_HOME/.local/share/aurorae/themes" \
        "$USER_HOME/.local/share/icons" \
        "$USER_HOME/.local/share/konsole" \
        "$USER_HOME/.local/share/plasma/look-and-feel" \
        "$USER_HOME/.local/share/wallpapers"

    if [ -f "$ASSETS_DIR/color-schemes/PurpleHUD.colors" ]; then
        run_as_user cp -a "$ASSETS_DIR/color-schemes"/* "$USER_HOME/.local/share/color-schemes/"
    fi
    if [ -d "$ASSETS_DIR/aurorae/VioletHUD" ]; then
        run_as_user cp -a "$ASSETS_DIR/aurorae/VioletHUD" "$USER_HOME/.local/share/aurorae/themes/"
    fi
    if [ -d "$ASSETS_DIR/icons/SoursCompiled" ]; then
        run_as_user cp -a "$ASSETS_DIR/icons/SoursCompiled" "$USER_HOME/.local/share/icons/"
    fi
    if [ -d "$ASSETS_DIR/plasma/look-and-feel/VioletHUD" ]; then
        run_as_user cp -a "$ASSETS_DIR/plasma/look-and-feel/VioletHUD" "$USER_HOME/.local/share/plasma/look-and-feel/"
    fi
    if [ -d "$ASSETS_DIR/wallpapers/VioletHUD" ]; then
        run_as_user cp -a "$ASSETS_DIR/wallpapers/VioletHUD" "$USER_HOME/.local/share/wallpapers/"
    fi

    # Konsole Profile & Colorscheme Setup
    if [ -f "$ASSETS_DIR/konsole/VioletHUD.profile" ]; then
        run_as_user cp -a "$ASSETS_DIR/konsole/VioletHUD.profile" "$USER_HOME/.local/share/konsole/"
    fi
    if [ -f "$ASSETS_DIR/konsole/Tronnix.colorscheme" ]; then
        run_as_user cp -a "$ASSETS_DIR/konsole/Tronnix.colorscheme" "$USER_HOME/.local/share/konsole/"
    fi
    run_as_user kwriteconfig6 --file "$USER_CONFIG/konsolerc" --group "Desktop Entry" --key DefaultProfile VioletHUD.profile
    run_as_user kwriteconfig6 --file "$USER_CONFIG/konsolerc" --group UiSettings --key ColorScheme PurpleHUD
    echo -e "  ${GREEN}[KONSOLE]${RESET} Configured VioletHUD.profile as default in konsolerc"

    # User Profile Picture (Avatar)
    if [ -f "$ASSETS_DIR/avatar/user-avatar.png" ]; then
        # System AccountsService
        mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
        cp -a "$ASSETS_DIR/avatar/user-avatar.png" "/var/lib/AccountsService/icons/$USER_NAME"
        chmod 644 "/var/lib/AccountsService/icons/$USER_NAME"

        USER_ACT_FILE="/var/lib/AccountsService/users/$USER_NAME"
        if [ -f "$USER_ACT_FILE" ]; then
            if grep -q '^Icon=' "$USER_ACT_FILE"; then
                sed -i "s#^Icon=.*#Icon=/var/lib/AccountsService/icons/$USER_NAME#" "$USER_ACT_FILE"
            else
                sed -i "/^\[User\]/a Icon=/var/lib/AccountsService/icons/$USER_NAME" "$USER_ACT_FILE" 2>/dev/null || \
                echo "Icon=/var/lib/AccountsService/icons/$USER_NAME" >> "$USER_ACT_FILE"
            fi
        else
            cat > "$USER_ACT_FILE" <<EOF
[User]
Icon=/var/lib/AccountsService/icons/$USER_NAME
EOF
        fi
        chmod 600 "$USER_ACT_FILE"

        # D-Bus AccountsService update
        if command -v busctl >/dev/null 2>&1; then
            busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$USER_UID" org.freedesktop.Accounts.User SetIconFile s "/var/lib/AccountsService/icons/$USER_NAME" 2>/dev/null || true
        fi

        # User ~/.face and ~/.face.icon
        backup_user_file "$USER_HOME/.face"
        install_user_file "$ASSETS_DIR/avatar/user-avatar.png" "$USER_HOME/.face"
        run_as_user ln -sf .face "$USER_HOME/.face.icon"
        echo -e "  ${GREEN}[AVATAR]${RESET} Set profile picture to VioletHUD avatar"
    fi

    # Global Style, Scheme, Icons
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group KDE --key widgetStyle Breeze
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group General --key ColorScheme PurpleHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group Icons --key Theme SoursCompiled

    # Cursor Theme & Size
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorTheme invader-64-purple
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorSize 48

    # Install user cursor directories for Wayland/Qt/GTK
    run_as_user rm -rf "$USER_HOME/.local/share/icons/Tronnix" "$USER_HOME/.icons/Tronnix"
    run_as_user rm -rf "$USER_HOME/.local/share/icons/invader-64-purple" "$USER_HOME/.icons/invader-64-purple"
    run_as_user mkdir -p "$USER_HOME/.local/share/icons" "$USER_HOME/.icons/default"
    run_as_user cp -a "$ASSETS_DIR/cursors/invader-64-purple" "$USER_HOME/.local/share/icons/invader-64-purple"
    run_as_user cp -a "$ASSETS_DIR/cursors/invader-64-purple" "$USER_HOME/.icons/invader-64-purple"

    # Default user cursor inheritance
    run_as_user tee "$USER_HOME/.icons/default/index.theme" >/dev/null <<'EOF'
[Icon Theme]
Inherits=invader-64-purple
EOF

    # GTK Cursor & Icon Settings
    for gtk_dir in "$USER_CONFIG/gtk-3.0" "$USER_CONFIG/gtk-4.0"; do
        if [ -d "$gtk_dir" ]; then
            if [ -f "$gtk_dir/settings.ini" ]; then
                run_as_user sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=invader-64-purple/' "$gtk_dir/settings.ini" 2>/dev/null || true
                run_as_user sed -i 's/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=48/' "$gtk_dir/settings.ini" 2>/dev/null || true
                run_as_user sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=SoursCompiled/' "$gtk_dir/settings.ini" 2>/dev/null || true
            fi
        fi
    done

    # Splash Screen
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Theme VioletHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Engine KSplashQML

    # Aurorae Window Decoration
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key theme __aurorae__svg__VioletHUD

    # Live apply themes to running Plasma session
    run_as_user plasma-apply-colorscheme PurpleHUD 2>/dev/null || true
    run_as_user plasma-apply-cursortheme invader-64-purple --size 48 2>/dev/null || true
    run_as_user plasma-apply-wallpaperimage /usr/share/wallpapers/VioletHUD/VioletHUD.jpg 2>/dev/null || \
    run_as_user plasma-apply-wallpaperimage "$USER_HOME/.local/share/wallpapers/VioletHUD/VioletHUD.jpg" 2>/dev/null || true

    # Enable Opacity Script
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group Plugins --key toggle-window-opacityEnabled true

    # Translucent Windows KWin Rule
    if [ -f "$ASSETS_DIR/kwin/rules/Translucent-Windows.rules" ]; then
        run_as_user python3 - "$ASSETS_DIR/kwin/rules/Translucent-Windows.rules" "$USER_CONFIG/kwinrulesrc" <<'PY'
import sys
from pathlib import Path
import re
import uuid

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

rule = src.read_text().strip()
if not rule:
    raise SystemExit("ERROR: Translucent Windows rule is empty")

new_uuid = str(uuid.uuid4())
rule = re.sub(r'^\[[^\]]+\]', f'[{new_uuid}]', rule, count=1)

text = dst.read_text() if dst.exists() else ""
blocks = text.split("\n\n")

general = None
other_sections = []
old_violet_uuids = set()

for part in blocks:
    part = part.strip()
    if not part:
        continue

    match = re.match(r'^\[([^\]]+)\]', part)
    if not match:
        other_sections.append(part)
        continue

    section_name = match.group(1)
    if section_name == "General":
        general = part
        continue

    if re.search(r'^Description=Translucent Windows\s*$', part, re.MULTILINE):
        old_violet_uuids.add(section_name)
        continue

    other_sections.append(part)

if general is None:
    general = "[General]\ncount=0\nrules=\n"

lines = general.rstrip().splitlines()
rules = []
new_lines = []

for line in lines:
    if line.startswith("rules="):
        rules = [x for x in line[len("rules="):].split(",") if x and x not in old_violet_uuids]
        continue
    if line.startswith("count="):
        continue
    new_lines.append(line)

rules.append(new_uuid)
new_lines.append(f"count={len(rules)}")
new_lines.append("rules=" + ",".join(rules))
general = "\n".join(new_lines)

sections = [general] + other_sections + [rule]
dst.write_text("\n\n".join(section.rstrip() for section in sections) + "\n")
print(f"Installed Translucent Windows rule: {new_uuid}")
PY
        echo -e "  ${GREEN}[RULE]${RESET} Configured Translucent Windows rule in kwinrulesrc"
    fi
fi

# ------------------------------------------------------------------------------
# 4. Desktop Panels and HUD Layout
# ------------------------------------------------------------------------------

if [[ "$INSTALL_MODE" != "no-panels" ]]; then
    echo -e "${BOLD}${BLUE}>>> Configuring Desktop Panels and HUD Layout...${RESET}"

    backup_user_file "$USER_CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
    backup_user_file "$USER_CONFIG/plasmashellrc"

    if [ -f "$ASSETS_DIR/plasma/panels/plasmashellrc" ]; then
        install_user_file "$ASSETS_DIR/plasma/panels/plasmashellrc" "$USER_CONFIG/plasmashellrc"
    fi

    if [ -f "$ASSETS_DIR/plasma/panels/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        TARGET_ACTIVITY="$(grep -m1 -E '^[0-9a-f-]{36}=' "$USER_CONFIG/kactivitymanagerdrc" 2>/dev/null | cut -d= -f1 || true)"
        if [ -n "$TARGET_ACTIVITY" ]; then
            sed "s/activityId=d5edce21-aae2-4004-a267-13fbd43d5632/activityId=$TARGET_ACTIVITY/g" \
                "$ASSETS_DIR/plasma/panels/plasma-org.kde.plasma.desktop-appletsrc" > "$USER_CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
        else
            cp -a "$ASSETS_DIR/plasma/panels/plasma-org.kde.plasma.desktop-appletsrc" "$USER_CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
        fi
        chown "$USER_NAME:$USER_NAME" "$USER_CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
        echo -e "  ${GREEN}[PANELS]${RESET} Installed 5 floating HUD panels layout"
    fi

    if [ -d "$USER_RUNDIR" ]; then
        sudo -u "$USER_NAME" \
            env XDG_RUNTIME_DIR="$USER_RUNDIR" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
                systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        echo -e "  ${GREEN}[SHELL]${RESET} Restarted plasma-plasmashell.service"
    fi
fi

# Ensure all user config files remain owned by target user
chown "$USER_NAME:$USER_NAME" \
    "$USER_CONFIG/kdeglobals" \
    "$USER_CONFIG/kwinrc" \
    "$USER_CONFIG/kwinrulesrc" \
    "$USER_CONFIG/ksplashrc" \
    "$USER_CONFIG/kcminputrc" \
    "$USER_CONFIG/konsolerc" \
    "$USER_HOME/.face" \
    2>/dev/null || true

# Reconfigure KWin and notify desktop of cursor, icon, and theme changes
if [ -d "$USER_RUNDIR" ]; then
    sudo -u "$USER_NAME" \
        env XDG_RUNTIME_DIR="$USER_RUNDIR" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    sudo -u "$USER_NAME" \
        env XDG_RUNTIME_DIR="$USER_RUNDIR" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
            dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
    sudo -u "$USER_NAME" \
        env XDG_RUNTIME_DIR="$USER_RUNDIR" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
            dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 2>/dev/null || true
    sudo -u "$USER_NAME" \
        env XDG_RUNTIME_DIR="$USER_RUNDIR" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
            dbus-send --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 2>/dev/null || true
fi

echo
echo -e "${PURPLE}${BOLD}============================================================${RESET}"
echo -e "${GREEN}${BOLD} VioletHUD Successfully Installed!${RESET}"
echo -e "${PURPLE}${BOLD}============================================================${RESET}"
echo
echo -e "${BOLD}Installed Components:${RESET}"
echo "  • Profile Avatar: VioletHUD Alienware Glow (~/.face & AccountsService)"
echo "  • Icons         : SoursCompiled"
echo "  • Cursor        : Invader 64 Purple"
echo "  • Decoration    : VioletHUD (Aurorae)"
echo "  • Color Scheme  : PurpleHUD"
echo "  • Kvantum Style : VioletHUD"
echo "  • Konsole       : VioletHUD.profile (Selected as Default)"
echo "  • Splash Screen : VioletHUD"
echo "  • Plymouth Boot : VioletHUD"
echo "  • SDDM Login    : Breeze (VioletHUD Background & Purple Cursor)"
echo "  • Wallpaper     : VioletHUD (Alienware Purple)"
if [[ "$INSTALL_MODE" != "no-panels" ]]; then
    echo "  • HUD Panels    : 5 Floating Panels (Weather, Monitors, Dock, Clock, Tray)"
fi
echo
echo -e "${BOLD}Safety & Backups:${RESET}"
echo "  • Original configs backed up to: $BACKUP_DIR"
echo "  • Full reversal available via:  sudo ./uninstall.sh"
echo
