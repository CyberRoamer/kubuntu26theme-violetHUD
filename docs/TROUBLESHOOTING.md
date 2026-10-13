# Troubleshooting Guide

### 1. Desktop panels did not reload immediately
If you ran `install.sh` and the panels do not appear right away, restart `plasmashell` manually in your user terminal:
```bash
systemctl --user restart plasma-plasmashell.service
```
Or alternatively:
```bash
kquitapp6 plasmashell && kstart plasmashell
```

---

### 2. Plymouth boot animation does not show
On Ubuntu/Kubuntu systems, Plymouth requires updating the initramfs:
```bash
sudo plymouth-set-default-theme -R VioletHUD
sudo update-initramfs -u
```
Ensure your GRUB configuration includes `quiet splash` in `/etc/default/grub`.

---

### 3. Cursor size differs in certain applications
Flatpak or older GTK apps may need the cursor theme mirrored in your user home:
```bash
mkdir -p ~/.icons
ln -s /usr/share/icons/invader-64-purple ~/.icons/default
```

---

### 4. Translucent windows rule is not active
Open **System Settings -> Window Management -> Window Rules** and verify that the **Translucent Windows** rule is checked. You can adjust active/inactive window opacity percentages to your liking.

---

### 5. Weather applet displays Delhi by default
The floating weather applet in the top-left panel defaults to Delhi, India. Right-click the applet, select **Configure Weather Report**, and set your desired city.
