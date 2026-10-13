#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  VioletHUD Complete Theme Suite Uninstaller
# ==============================================================================

BACKUP_DIR="/var/backups/violethud"

BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Elevation required. Rerunning with sudo...${RESET}"
    exec sudo "$0" "$@"
fi

echo -e "${PURPLE}${BOLD}"
echo "============================================================"
echo "          VioletHUD Complete Theme Suite Uninstaller"
echo "============================================================"
echo -e "${RESET}"

remove_tree() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        rm -rf "$path"
        echo -e "  ${YELLOW}[REMOVE]${RESET} $path"
    fi
}

echo -e "${BOLD}${BLUE}>>> Removing System Theme Assets...${RESET}"
remove_tree /usr/share/icons/SoursCompiled
remove_tree /usr/share/icons/invader-64-purple
remove_tree /usr/share/icons/Tronnix
remove_tree /usr/share/aurorae/themes/VioletHUD
remove_tree /usr/share/color-schemes/PurpleHUD.colors
remove_tree /usr/share/color-schemes/LavenderHUD.colors
remove_tree /usr/share/Kvantum/VioletHUD
remove_tree /usr/share/konsole/VioletHUD.profile
remove_tree /usr/share/konsole/Tronnix.colorscheme
remove_tree /usr/share/plasma/look-and-feel/VioletHUD
remove_tree /usr/share/kwin/scripts/toggle-window-opacity
remove_tree /usr/share/plymouth/themes/VioletHUD
remove_tree /usr/share/wallpapers/VioletHUD

if [ -f /etc/sddm.conf.d/kde_settings.conf ]; then
    rm -f /etc/sddm.conf.d/kde_settings.conf
    echo -e "  ${YELLOW}[REMOVE]${RESET} /etc/sddm.conf.d/kde_settings.conf"
fi

# ------------------------------------------------------------------------------
# Restore System Backups (SDDM & Plymouth)
# ------------------------------------------------------------------------------

echo -e "${BOLD}${BLUE}>>> Restoring System Settings...${RESET}"

if [ -d "$BACKUP_DIR" ]; then
    for file in "$BACKUP_DIR"/*; do
        [ -e "$file" ] || continue
        name="$(basename "$file")"
        case "$name" in
            etc__sddm.conf)
                cp -a "$file" "/etc/sddm.conf"
                echo -e "  ${GREEN}[RESTORE]${RESET} /etc/sddm.conf"
                ;;
            etc__sddm.conf.d__kde_settings.conf)
                cp -a "$file" "/etc/sddm.conf.d/kde_settings.conf"
                echo -e "  ${GREEN}[RESTORE]${RESET} /etc/sddm.conf.d/kde_settings.conf"
                ;;
        esac
    done
fi

if command -v update-initramfs >/dev/null 2>&1 && \
   command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme -R breeze 2>/dev/null || true
    echo -e "  ${GREEN}[PLYMOUTH]${RESET} Reset boot theme to breeze"
fi

# ------------------------------------------------------------------------------
# Restore User Backups
# ------------------------------------------------------------------------------

if [ -n "${SUDO_USER:-}" ] && [ -d "$BACKUP_DIR/user-config" ]; then
    echo -e "${BOLD}${BLUE}>>> Restoring User Configurations for $SUDO_USER...${RESET}"
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    USER_CONFIG="$USER_HOME/.config"

    restore_user_cfg() {
        local original_name="$1"
        for f in "$BACKUP_DIR/user-config"/*; do
            [ -e "$f" ] || continue
            if [[ "$f" == *"$original_name" ]]; then
                cp -a "$f" "$USER_CONFIG/$original_name"
                chown "$SUDO_USER:$SUDO_USER" "$USER_CONFIG/$original_name"
                echo -e "  ${GREEN}[RESTORE]${RESET} $USER_CONFIG/$original_name"
            fi
        done
    }

    restore_user_cfg "kdeglobals"
    restore_user_cfg "kwinrc"
    restore_user_cfg "kwinrulesrc"
    restore_user_cfg "ksplashrc"
    restore_user_cfg "kcminputrc"
    restore_user_cfg "plasma-org.kde.plasma.desktop-appletsrc"
    restore_user_cfg "plasmashellrc"

    USER_UID="$(id -u "$SUDO_USER")"
    USER_RUNDIR="/run/user/$USER_UID"
    if [ -d "$USER_RUNDIR" ]; then
        sudo -u "$SUDO_USER" \
            env XDG_RUNTIME_DIR="$USER_RUNDIR" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
                systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        echo -e "  ${GREEN}[SHELL]${RESET} Reloaded plasma-plasmashell.service"
    fi
fi

echo
echo -e "${PURPLE}${BOLD}============================================================${RESET}"
echo -e "${GREEN}${BOLD} VioletHUD Successfully Uninstalled.${RESET}"
echo -e "${PURPLE}${BOLD}============================================================${RESET}"
echo
