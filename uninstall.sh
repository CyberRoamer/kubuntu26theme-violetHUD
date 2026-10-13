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
remove_tree /usr/share/konsole/VioletHUD.colorscheme
remove_tree /usr/share/konsole/Tronnix.colorscheme
remove_tree /usr/share/plasma/look-and-feel/VioletHUD
remove_tree /usr/share/kwin/scripts/toggle-window-opacity
remove_tree /usr/share/plymouth/themes/VioletHUD
remove_tree /usr/share/wallpapers/VioletHUD

if [ -f /etc/sddm.conf.d/kde_settings.conf ]; then
    rm -f /etc/sddm.conf.d/kde_settings.conf
    echo -e "  ${YELLOW}[REMOVE]${RESET} /etc/sddm.conf.d/kde_settings.conf"
fi

for sddm_theme in breeze kubuntu; do
    if [ -f "/usr/share/sddm/themes/$sddm_theme/theme.conf.user" ]; then
        rm -f "/usr/share/sddm/themes/$sddm_theme/theme.conf.user"
        rm -f "/usr/share/sddm/themes/$sddm_theme/VioletHUD.jpg"
        echo -e "  ${YELLOW}[REMOVE]${RESET} /usr/share/sddm/themes/$sddm_theme/theme.conf.user"
    fi
done

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

if command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --remove x-cursor-theme /usr/share/icons/invader-64-purple/index.theme 2>/dev/null || true
    update-alternatives --auto x-cursor-theme 2>/dev/null || true
    update-alternatives --remove default.plymouth /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth 2>/dev/null || true
    if [ -f /usr/share/plymouth/themes/breeze/breeze.plymouth ]; then
        update-alternatives --set default.plymouth /usr/share/plymouth/themes/breeze/breeze.plymouth 2>/dev/null || true
    else
        update-alternatives --auto default.plymouth 2>/dev/null || true
    fi
    echo -e "  ${GREEN}[ALTERNATIVES]${RESET} Reset cursor and boot theme default alternatives"
fi

if command -v update-initramfs >/dev/null 2>&1; then
    echo -e "  ${BLUE}[INITRAMFS]${RESET} Updating initramfs..."
    update-initramfs -u 2>/dev/null || true
    echo -e "  ${GREEN}[INITRAMFS]${RESET} Initramfs restored"
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

    restore_user_cfg "konsolerc"
    restore_user_cfg "kdeglobals"
    restore_user_cfg "kwinrc"
    restore_user_cfg "kwinrulesrc"
    restore_user_cfg "ksplashrc"
    restore_user_cfg "kcminputrc"
    restore_user_cfg "plasma-org.kde.plasma.desktop-appletsrc"
    restore_user_cfg "plasmashellrc"

    # Restore or clean profile picture / avatar
    if [ -f "$BACKUP_DIR/user-config"/*__face ]; then
        cp -a "$BACKUP_DIR/user-config"/*__face "$USER_HOME/.face"
        chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.face"
        echo -e "  ${GREEN}[RESTORE]${RESET} $USER_HOME/.face"
    fi

    remove_tree "$USER_HOME/.local/share/color-schemes/PurpleHUD.colors"
    remove_tree "$USER_HOME/.local/share/color-schemes/LavenderHUD.colors"
    remove_tree "$USER_HOME/.local/share/aurorae/themes/VioletHUD"
    remove_tree "$USER_HOME/.local/share/icons/SoursCompiled"
    remove_tree "$USER_HOME/.local/share/icons/invader-64-purple"
    remove_tree "$USER_HOME/.local/share/konsole/VioletHUD.profile"
    remove_tree "$USER_HOME/.local/share/konsole/VioletHUD.colorscheme"
    remove_tree "$USER_HOME/.local/share/konsole/Tronnix.colorscheme"
    remove_tree "$USER_HOME/.local/share/plasma/look-and-feel/VioletHUD"
    remove_tree "$USER_HOME/.local/share/wallpapers/VioletHUD"
    remove_tree "$USER_HOME/.icons/invader-64-purple"
    remove_tree "$USER_HOME/.icons/default"

    USER_UID="$(id -u "$SUDO_USER")"
    USER_RUNDIR="/run/user/$USER_UID"
    if [ -d "$USER_RUNDIR" ]; then
        sudo -u "$SUDO_USER" \
            env XDG_RUNTIME_DIR="$USER_RUNDIR" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNDIR/bus" \
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
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
