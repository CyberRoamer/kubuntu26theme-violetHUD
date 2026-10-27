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

# Detect active user session display, wayland socket, and auth
DETECTED_WAYLAND=""
DETECTED_DISPLAY=""
DETECTED_XAUTH=""

if [ -d "$USER_RUNDIR" ]; then
    DETECTED_WAYLAND="$(find "$USER_RUNDIR" -maxdepth 1 -name "wayland-*" 2>/dev/null | head -n1 | xargs -r basename || true)"
fi

if [ -z "$DETECTED_WAYLAND" ] && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    DETECTED_WAYLAND="$WAYLAND_DISPLAY"
fi

if [ -n "${DISPLAY:-}" ]; then
    DETECTED_DISPLAY="$DISPLAY"
else
    DETECTED_DISPLAY="$(who 2>/dev/null | grep "^$USER_NAME " | grep -o '(:[0-9]*' | tr -d '()' | head -n1 || echo ":0")"
fi

if [ -n "${XAUTHORITY:-}" ] && [ -f "$XAUTHORITY" ]; then
    DETECTED_XAUTH="$XAUTHORITY"
elif [ -f "$USER_HOME/.Xauthority" ]; then
    DETECTED_XAUTH="$USER_HOME/.Xauthority"
fi

run_as_user() {
    sudo -u "$USER_NAME" \
        env HOME="$USER_HOME" \
            USER="$USER_NAME" \
            LOGNAME="$USER_NAME" \
            XDG_CONFIG_HOME="$USER_CONFIG" \
            XDG_DATA_HOME="$USER_HOME/.local/share" \
            XDG_CACHE_HOME="$USER_HOME/.cache" \
            XDG_RUNTIME_DIR="${USER_RUNDIR:-}" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$USER_RUNDIR/bus}" \
            WAYLAND_DISPLAY="${DETECTED_WAYLAND:-}" \
            DISPLAY="${DETECTED_DISPLAY:-:0}" \
            XAUTHORITY="${DETECTED_XAUTH:-}" \
            QT_QPA_PLATFORM="wayland;xcb;offscreen" \
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

validate_and_repair_icons() {
    local target_dir="$1"
    if [ ! -d "$target_dir" ]; then
        return
    fi
    local p48_folder="$target_dir/places/48/folder.svg"
    local p48_dl="$target_dir/places/48/folder-download.svg"
    local p16_folder="$target_dir/places/16/folder.svg"
    local p16_dl="$target_dir/places/16/folder-download.svg"

    # Main file manager view: places/48 & mimetypes (scalable glowing purple Cyberpunk folders)
    if [ -f "$p48_folder" ]; then
        for f in \
            "$target_dir/mimetypes/scalable/inode-directory.svg" \
            "$target_dir/mimetypes/scalable/inode-directory-symbolic.svg" \
            "$target_dir/mimetypes/scalable/folder.svg" \
            "$target_dir/mimetypes/scalable/folder-symbolic.svg" \
            "$target_dir/mimetypes/scalable/directory.svg" \
            "$target_dir/places/48/inode-directory.svg" \
            "$target_dir/places/48/inode-directory-symbolic.svg" \
            "$target_dir/places/48/folder-symbolic.svg" \
            "$target_dir/places/48/directory.svg" \
            "$target_dir/places/48/folder-directory.svg"; do
            if [ ! -s "$f" ] || [ ! -e "$f" ]; then
                rm -f "$f"
                cp -a "$p48_folder" "$f"
            fi
        done
    fi

    if [ -f "$p48_dl" ]; then
        for f in \
            "$target_dir/places/48/folder-downloads.svg" \
            "$target_dir/places/48/user-downloads.svg" \
            "$target_dir/places/48/user-download.svg" \
            "$target_dir/places/48/download.svg" \
            "$target_dir/places/48/downloads.svg" \
            "$target_dir/places/48/download-folder.svg"; do
            if [ ! -s "$f" ] || [ ! -e "$f" ]; then
                rm -f "$f"
                cp -a "$p48_dl" "$f"
            fi
        done
    fi

    # Sidebar view: places/16 (small white icons with purple offset shadow, 16px-24px)
    if [ -f "$p16_folder" ]; then
        for f in \
            "$target_dir/places/16/folder-symbolic.svg" \
            "$target_dir/places/16/inode-directory.svg" \
            "$target_dir/places/16/inode-directory-symbolic.svg" \
            "$target_dir/places/16/directory.svg"; do
            if [ ! -s "$f" ] || [ ! -e "$f" ]; then
                rm -f "$f"
                cp -a "$p16_folder" "$f"
            fi
        done
    fi

    if [ -f "$p16_dl" ]; then
        for f in \
            "$target_dir/places/16/folder-downloads.svg" \
            "$target_dir/places/16/user-downloads.svg" \
            "$target_dir/places/16/user-download.svg" \
            "$target_dir/places/16/download.svg" \
            "$target_dir/places/16/downloads.svg" \
            "$target_dir/places/16/download-folder.svg" \
            "$target_dir/places/16/folder_download.svg" \
            "$target_dir/places/16/folder_downloads.svg"; do
            if [ ! -s "$f" ] || [ ! -e "$f" ]; then
                rm -f "$f"
                cp -a "$p16_dl" "$f"
            fi
        done
    fi

    # Ensure places/22, places/24, places/32 and HiDPI scaled symlinks exist
    if [ -d "$target_dir/places/16" ]; then
        if [ ! -d "$target_dir/places/22" ]; then
            cp -a "$target_dir/places/16" "$target_dir/places/22"
        fi
        if [ ! -d "$target_dir/places/32" ]; then
            cp -a "$target_dir/places/22" "$target_dir/places/32"
        fi
        (
            cd "$target_dir/places" || exit 0
            [ -e "24" ] || ln -s 22 24
            [ -e "16@2x" ] || ln -s 16 16@2x
            [ -e "16@3x" ] || ln -s 16 16@3x
            [ -e "22@2x" ] || ln -s 22 22@2x
            [ -e "22@3x" ] || ln -s 22 22@3x
            [ -e "24@2x" ] || ln -s 24 24@2x
            [ -e "24@3x" ] || ln -s 24 24@3x
            [ -e "32@2x" ] || ln -s 32 32@2x
            [ -e "32@3x" ] || ln -s 32 32@3x
        ) 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 1. System Assets Installation
# ------------------------------------------------------------------------------

if [[ "$INSTALL_MODE" != "panels-only" ]]; then
    echo -e "${BOLD}${BLUE}>>> Installing System Theme Assets...${RESET}"

    # Icons
    rm -rf /usr/share/icons/SoursCompiled
    install_tree "$ASSETS_DIR/icons/SoursCompiled" "/usr/share/icons/SoursCompiled"
    validate_and_repair_icons "/usr/share/icons/SoursCompiled"

    # Cursors (Alienware Invader Purple)
    rm -rf /usr/share/icons/Tronnix /usr/share/icons/invader-64-purple
    install_tree "$ASSETS_DIR/cursors/invader-64-purple" "/usr/share/icons/invader-64-purple"


    # Aurorae Window Decoration
    install_tree "$ASSETS_DIR/aurorae/VioletHUD" "/usr/share/aurorae/themes/VioletHUD"

    # Color Scheme
    install_file "$ASSETS_DIR/color-schemes/PurpleHUD.colors" "/usr/share/color-schemes/PurpleHUD.colors"
    rm -f /usr/share/color-schemes/LavenderHUD.colors 2>/dev/null || true

    # Kvantum Style
    install_tree "$ASSETS_DIR/kvantum/VioletHUD" "/usr/share/Kvantum/VioletHUD"

    # Konsole Profile & Colors
    install_file "$ASSETS_DIR/konsole/VioletHUD.profile" "/usr/share/konsole/VioletHUD.profile"
    install_file "$ASSETS_DIR/konsole/VioletHUD.colorscheme" "/usr/share/konsole/VioletHUD.colorscheme"
    rm -f /usr/share/konsole/Tronnix.colorscheme 2>/dev/null || true

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

    # Configure SDDM user environment (/var/lib/sddm/.config)
    if id sddm >/dev/null 2>&1; then
        mkdir -p /var/lib/sddm/.config /var/lib/sddm/.icons/default
        cp -a "$ASSETS_DIR/color-schemes/PurpleHUD.colors" /var/lib/sddm/.config/kdeglobals
        kwriteconfig6 --file /var/lib/sddm/.config/kdeglobals --group General --key ColorScheme PurpleHUD
        kwriteconfig6 --file /var/lib/sddm/.config/kdeglobals --group Icons --key Theme SoursCompiled
        kwriteconfig6 --file /var/lib/sddm/.config/kdeglobals --group KDE --key LookAndFeelPackage org.kubuntudark.desktop
        kwriteconfig6 --file /var/lib/sddm/.config/kdeglobals --group KDE --key widgetStyle Breeze
        kwriteconfig6 --file /var/lib/sddm/.config/plasmarc --group Theme --key name kubuntu-dark
        kwriteconfig6 --file /var/lib/sddm/.config/kcminputrc --group Mouse --key cursorTheme invader-64-purple
        kwriteconfig6 --file /var/lib/sddm/.config/kcminputrc --group Mouse --key cursorSize 48

        cat > /var/lib/sddm/.icons/default/index.theme <<'EOF'
[Icon Theme]
Inherits=invader-64-purple
EOF
        chown -R sddm:sddm /var/lib/sddm/.config /var/lib/sddm/.icons 2>/dev/null || true
        chmod 755 /var/lib/sddm/.config /var/lib/sddm/.icons 2>/dev/null || true
        chmod 644 /var/lib/sddm/.config/* /var/lib/sddm/.icons/default/* 2>/dev/null || true
        rm -rf /var/lib/sddm/.cache 2>/dev/null || true
        echo -e "  ${GREEN}[SDDM]${RESET} Configured SDDM user dark environment (Kubuntu Dark, PurpleHUD, SoursCompiled)"
    fi

    # Set sddm-ubuntu-theme alternative to kubuntu if present
    if update-alternatives --list sddm-ubuntu-theme 2>/dev/null | grep -q "kubuntu"; then
        update-alternatives --set sddm-ubuntu-theme /usr/share/sddm/themes/kubuntu 2>/dev/null || true
    fi

    # Global system-wide fallback in /etc/xdg
    mkdir -p /etc/xdg
    cp -a "$ASSETS_DIR/color-schemes/PurpleHUD.colors" /etc/xdg/kdeglobals
    kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme PurpleHUD
    kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme SoursCompiled
    kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.kubuntudark.desktop
    kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key widgetStyle Breeze
    kwriteconfig6 --file /etc/xdg/plasmarc --group Theme --key name default
    kwriteconfig6 --file /etc/xdg/kcminputrc --group Mouse --key cursorTheme invader-64-purple
    kwriteconfig6 --file /etc/xdg/kcminputrc --group Mouse --key cursorSize 48
    chmod 644 /etc/xdg/kdeglobals /etc/xdg/plasmarc /etc/xdg/kcminputrc 2>/dev/null || true

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
        /usr/share/konsole/VioletHUD.colorscheme \
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
        /usr/share/konsole/VioletHUD.colorscheme \
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

    # System x-cursor-theme registration (using cursor.theme without Name= to avoid duplicate entry in KDE System Settings)
    if [ -f "/usr/share/icons/invader-64-purple/cursor.theme" ]; then
        if command -v update-alternatives >/dev/null 2>&1; then
            update-alternatives --remove x-cursor-theme /usr/share/icons/invader-64-purple/index.theme 2>/dev/null || true
            update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme \
                /usr/share/icons/invader-64-purple/cursor.theme 100 2>/dev/null || true
            update-alternatives --set x-cursor-theme \
                /usr/share/icons/invader-64-purple/cursor.theme 2>/dev/null || true
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
    backup_user_file "$USER_CONFIG/plasmarc"
    backup_user_file "$USER_CONFIG/kscreenlockerrc"
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
    run_as_user rm -f "$USER_HOME/.local/share/color-schemes/LavenderHUD.colors"
    # Ensure no duplicate local Aurorae theme exists
    run_as_user rm -rf "$USER_HOME/.local/share/aurorae/themes/VioletHUD"
    if [ -d "$ASSETS_DIR/icons/SoursCompiled" ]; then
        run_as_user rm -rf "$USER_HOME/.local/share/icons/SoursCompiled" "$USER_HOME/.icons/SoursCompiled"
        run_as_user cp -a "$ASSETS_DIR/icons/SoursCompiled" "$USER_HOME/.local/share/icons/"
        validate_and_repair_icons "$USER_HOME/.local/share/icons/SoursCompiled"
        chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local/share/icons/SoursCompiled" 2>/dev/null || true
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            run_as_user gtk-update-icon-cache -f "$USER_HOME/.local/share/icons/SoursCompiled" 2>/dev/null || true
        fi
    fi
    # Ensure no duplicate local Look-and-Feel / Splash theme exists
    run_as_user rm -rf "$USER_HOME/.local/share/plasma/look-and-feel/VioletHUD"
    if [ -d "$ASSETS_DIR/wallpapers/VioletHUD" ]; then
        run_as_user cp -a "$ASSETS_DIR/wallpapers/VioletHUD" "$USER_HOME/.local/share/wallpapers/"
    fi

    # Konsole Profile & Colorscheme Setup
    if [ -f "$ASSETS_DIR/konsole/VioletHUD.profile" ]; then
        run_as_user cp -a "$ASSETS_DIR/konsole/VioletHUD.profile" "$USER_HOME/.local/share/konsole/"
    fi
    if [ -f "$ASSETS_DIR/konsole/VioletHUD.colorscheme" ]; then
        run_as_user cp -a "$ASSETS_DIR/konsole/VioletHUD.colorscheme" "$USER_HOME/.local/share/konsole/"
    fi
    run_as_user rm -f "$USER_HOME/.local/share/konsole/Tronnix.colorscheme"
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

    # 1. Apply Kubuntu Dark (or Breeze Dark fallback) look-and-feel base FIRST
    # so that all underlying global dark frameworks, Kirigami structures, and defaults are in place
    run_as_user plasma-apply-lookandfeel -a org.kubuntudark.desktop 2>/dev/null || \
    run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true

    # Clean up kdedefaults so it never overrides VioletHUD with BreezeDark/breeze-dark defaults
    run_as_user rm -rf "$USER_CONFIG/kdedefaults"

    # 2. Directly merge all PurpleHUD color definitions & icons into user kdeglobals
    if [ -f "$ASSETS_DIR/color-schemes/PurpleHUD.colors" ]; then
        run_as_user python3 - "$ASSETS_DIR/color-schemes/PurpleHUD.colors" "$USER_CONFIG/kdeglobals" <<'PY'
import configparser, sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

cfg = configparser.RawConfigParser()
cfg.optionxform = str
if dst.exists():
    try:
        cfg.read(dst, encoding="utf-8")
    except Exception:
        pass

colors_cfg = configparser.RawConfigParser()
colors_cfg.optionxform = str
colors_cfg.read(src, encoding="utf-8")

for sec in colors_cfg.sections():
    if not cfg.has_section(sec):
        cfg.add_section(sec)
    for k, v in colors_cfg.items(sec):
        cfg.set(sec, k, v)

if not cfg.has_section("General"):
    cfg.add_section("General")
cfg.set("General", "ColorScheme", "PurpleHUD")
cfg.set("General", "Name", "Purple HUD")

if not cfg.has_section("Icons"):
    cfg.add_section("Icons")
cfg.set("Icons", "Theme", "SoursCompiled")

if not cfg.has_section("KDE"):
    cfg.add_section("KDE")
cfg.set("KDE", "LookAndFeelPackage", "org.kubuntudark.desktop")
cfg.set("KDE", "widgetStyle", "Breeze")

dst.parent.mkdir(parents=True, exist_ok=True)
with open(dst, "w", encoding="utf-8") as f:
    cfg.write(f)
PY
        echo -e "  ${GREEN}[COLORS]${RESET} Merged PurpleHUD color palette into kdeglobals"
    fi

    # Explicitly write keys in kdeglobals
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group KDE --key widgetStyle Breeze
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group KDE --key LookAndFeelPackage org.kubuntudark.desktop
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group General --key ColorScheme PurpleHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group Icons --key Theme SoursCompiled

    # Plasma Theme (Default/Breeze for translucent glass HUD panels)
    run_as_user kwriteconfig6 --file "$USER_CONFIG/plasmarc" --group Theme --key name default

    # Lock Screen Settings (Kubuntu Dark theme & VioletHUD wallpaper)
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kscreenlockerrc" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image /usr/share/wallpapers/VioletHUD/contents/images/1920x1080.jpg
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kscreenlockerrc" --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage /usr/share/wallpapers/VioletHUD/contents/images/1920x1080.jpg
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kscreenlockerrc" --group Greeter --key theme org.kubuntudark.desktop

    # Cursor Theme & Size
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorTheme invader-64-purple
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorSize 48

    # Clean up local user cursor copies to prevent duplicate entries in System Settings
    run_as_user rm -rf \
        "$USER_HOME/.local/share/icons/Tronnix" \
        "$USER_HOME/.icons/Tronnix" \
        "$USER_HOME/.local/share/icons/invader-64-purple" \
        "$USER_HOME/.icons/invader-64-purple" \
        "$USER_HOME/.icons/invader-64" \
        "$USER_HOME/.icons/invader"
    run_as_user mkdir -p "$USER_HOME/.icons/default"

    # Default user cursor inheritance
    run_as_user tee "$USER_HOME/.icons/default/index.theme" >/dev/null <<'EOF'
[Icon Theme]
Inherits=invader-64-purple
EOF

    # Xresources cursor configuration
    run_as_user tee "$USER_HOME/.Xresources" >/dev/null <<'EOF'
Xcursor.theme: invader-64-purple
Xcursor.size: 48
EOF
    run_as_user xrdb -merge "$USER_HOME/.Xresources" 2>/dev/null || true

    # GTK Cursor & Icon Settings (create if missing, or update existing)
    for gtk_ver in "gtk-3.0" "gtk-4.0"; do
        gtk_dir="$USER_CONFIG/$gtk_ver"
        gtk_file="$gtk_dir/settings.ini"
        run_as_user mkdir -p "$gtk_dir"
        if [ ! -f "$gtk_file" ]; then
            run_as_user tee "$gtk_file" >/dev/null <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Breeze
gtk-icon-theme-name=SoursCompiled
gtk-cursor-theme-name=invader-64-purple
gtk-cursor-theme-size=48
EOF
        else
            run_as_user kwriteconfig6 --file "$gtk_file" --group Settings --key gtk-application-prefer-dark-theme true
            run_as_user kwriteconfig6 --file "$gtk_file" --group Settings --key gtk-theme-name Breeze
            run_as_user kwriteconfig6 --file "$gtk_file" --group Settings --key gtk-icon-theme-name SoursCompiled
            run_as_user kwriteconfig6 --file "$gtk_file" --group Settings --key gtk-cursor-theme-name invader-64-purple
            run_as_user kwriteconfig6 --file "$gtk_file" --group Settings --key gtk-cursor-theme-size 48
        fi
    done

    # Splash Screen
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Theme VioletHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Engine KSplashQML

    # Aurorae Window Decoration
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key theme __aurorae__svg__VioletHUD

    # Live apply desktop theme, color scheme, cursor, and wallpaper
    run_as_user plasma-apply-desktoptheme default 2>/dev/null || true
    run_as_user plasma-apply-colorscheme PurpleHUD 2>/dev/null || true
    run_as_user plasma-apply-cursortheme invader-64-purple --size 48 2>/dev/null || true
    run_as_user plasma-apply-wallpaperimage /usr/share/wallpapers/VioletHUD/VioletHUD.jpg 2>/dev/null || \
    run_as_user plasma-apply-wallpaperimage "$USER_HOME/.local/share/wallpapers/VioletHUD/VioletHUD.jpg" 2>/dev/null || true

    # Re-assert configs after plasma-apply
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group Icons --key Theme SoursCompiled
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kdeglobals" --group General --key ColorScheme PurpleHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorTheme invader-64-purple
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kcminputrc" --group Mouse --key cursorSize 48
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key theme __aurorae__svg__VioletHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group org.kde.kdecoration2 --key BorderSize Normal
    run_as_user kwriteconfig6 --file "$USER_CONFIG/plasmarc" --group Theme --key name default
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Theme VioletHUD
    run_as_user kwriteconfig6 --file "$USER_CONFIG/ksplashrc" --group KSplash --key Engine KSplashQML

    # Dolphin Places sidebar configuration (Medium 22px static size)
    run_as_user kwriteconfig6 --file "$USER_CONFIG/dolphinrc" --group "KFileDialog Settings" --key "Places Icons Auto-resize" false
    run_as_user kwriteconfig6 --file "$USER_CONFIG/dolphinrc" --group "KFileDialog Settings" --key "Places Icons Static Size" 22
    run_as_user kwriteconfig6 --file "$USER_CONFIG/dolphinrc" --group "PlacesPanel" --key "IconSize" 22

    # Clear stale icon caches
    run_as_user rm -f "$USER_HOME/.cache/icon-cache.kcache" 2>/dev/null || true
    run_as_user rm -rf "$USER_HOME/.cache/ksycoca6"* 2>/dev/null || true
    run_as_user rm -rf "$USER_HOME/.cache/kicontheme"* 2>/dev/null || true
    run_as_user rm -rf "$USER_HOME/.cache/plasma_theme"* 2>/dev/null || true
    run_as_user rm -rf "$USER_HOME/.cache/plasma-svgelements"* 2>/dev/null || true
    run_as_user kbuildsycoca6 --noincremental 2>/dev/null || true

    # Enable Blur Effect and Opacity Script for frosted glass HUD panels
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group Plugins --key blurEnabled true
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group Effect-blur --key BlurStrength 1
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group Effect-blur --key NoiseStrength 0
    run_as_user kwriteconfig6 --file "$USER_CONFIG/kwinrc" --group Effect-blur --key Saturation 100
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
    "$USER_CONFIG/plasmarc" \
    "$USER_CONFIG/kscreenlockerrc" \
    "$USER_CONFIG/kwinrc" \
    "$USER_CONFIG/kwinrulesrc" \
    "$USER_CONFIG/ksplashrc" \
    "$USER_CONFIG/kcminputrc" \
    "$USER_CONFIG/dolphinrc" \
    "$USER_CONFIG/konsolerc" \
    "$USER_HOME/.face" \
    2>/dev/null || true

# Reconfigure KWin and notify desktop of cursor, icon, and theme changes
if [ -d "$USER_RUNDIR" ]; then
    run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    run_as_user dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
    run_as_user dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 2>/dev/null || true
    run_as_user dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:5 int32:0 2>/dev/null || true
    run_as_user dbus-send --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 2>/dev/null || true
    run_as_user dbus-send --type=signal / org.kde.kconfig.notify 2>/dev/null || true
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
echo "  • SDDM Login    : Kubuntu Dark (VioletHUD Background & Purple Cursor)"
echo "  • Lock Screen   : Kubuntu Dark (VioletHUD Wallpaper)"
echo "  • Wallpaper     : VioletHUD (Alienware Purple)"
if [[ "$INSTALL_MODE" != "no-panels" ]]; then
    echo "  • HUD Panels    : 5 Floating Panels (Top: Clock, Open Apps/Dock, Tray; Bottom: Weather, System Metrics)"
fi
echo
echo -e "${BOLD}Safety & Backups:${RESET}"
echo "  • Original configs backed up to: $BACKUP_DIR"
echo "  • Full reversal available via:  sudo ./uninstall.sh"
echo
