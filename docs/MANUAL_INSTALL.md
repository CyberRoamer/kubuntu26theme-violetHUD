# Manual Installation Guide

If you prefer to install assets manually without running `install.sh`, follow the steps below.

---

### Step 1: Install System Assets
Copy all assets into their respective system directories:

```bash
# Aurorae decoration
sudo cp -r assets/aurorae/VioletHUD /usr/share/aurorae/themes/

# Color schemes
sudo cp assets/color-schemes/*.colors /usr/share/color-schemes/

# Cursors
sudo cp -r assets/cursors/* /usr/share/icons/

# Icons
sudo cp -r assets/icons/SoursCompiled /usr/share/icons/

# Kvantum theme
sudo cp -r assets/kvantum/VioletHUD /usr/share/Kvantum/

# Konsole profile & colors
sudo cp assets/konsole/VioletHUD.profile /usr/share/konsole/
sudo cp assets/konsole/VioletHUD.colorscheme /usr/share/konsole/

# Splash screen
sudo cp -r assets/plasma/look-and-feel/VioletHUD /usr/share/plasma/look-and-feel/

# KWin script
sudo cp -r assets/kwin/scripts/toggle-window-opacity /usr/share/kwin/scripts/

# Plymouth theme
sudo cp -r assets/plymouth/VioletHUD /usr/share/plymouth/themes/

# Wallpaper
sudo cp -r assets/wallpapers/VioletHUD /usr/share/wallpapers/

# SDDM login config
sudo mkdir -p /etc/sddm.conf.d
sudo cp assets/sddm/kde_settings.conf /etc/sddm.conf.d/
```

Update caches and Plymouth:
```bash
sudo gtk-update-icon-cache -f /usr/share/icons/SoursCompiled
sudo gtk-update-icon-cache -f /usr/share/icons/invader-64-purple
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth 100 --slave /usr/share/plymouth/themes/default.grub default.plymouth.grub /usr/share/plymouth/themes/VioletHUD/VioletHUD.grub
sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/VioletHUD/VioletHUD.plymouth
sudo update-initramfs -u
```

---

### Step 2: Apply User KDE Configuration
Run the following commands as your normal user:

```bash
# Application style & colors
kwriteconfig6 --file ~/.config/kdeglobals --group KDE --key widgetStyle Breeze
kwriteconfig6 --file ~/.config/kdeglobals --group General --key ColorScheme PurpleHUD
kwriteconfig6 --file ~/.config/kdeglobals --group Icons --key Theme SoursCompiled

# Cursors
kwriteconfig6 --file ~/.config/kcminputrc --group Mouse --key cursorTheme invader-64-purple
kwriteconfig6 --file ~/.config/kcminputrc --group Mouse --key cursorSize 48

# Splash
kwriteconfig6 --file ~/.config/ksplashrc --group KSplash --key Theme VioletHUD

# Window decoration
kwriteconfig6 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
kwriteconfig6 --file ~/.config/kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__VioletHUD
kwriteconfig6 --file ~/.config/kwinrc --group Plugins --key toggle-window-opacityEnabled true
```

---

### Step 3: (Optional) Apply Desktop Panels
To apply the 5 floating HUD panels:
```bash
cp assets/plasma/panels/plasmashellrc ~/.config/plasmashellrc
cp assets/plasma/panels/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc
systemctl --user restart plasma-plasmashell.service
```
