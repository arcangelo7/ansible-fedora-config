# Fedora system configuration with Ansible

![Configured Desktop Preview](preview.png)

Ansible playbooks to automatically configure a Fedora system with my personal settings.

## Prerequisites

- Fedora (tested on Fedora 41)
- Ansible installed (`sudo dnf install ansible`)
- BTRFS filesystem on root partition (optional, for subvolume script)

## Quick start

Set `local_user` in `group_vars/workstations.yml` to your username, then run:

```bash
ansible-playbook -i inventory.yml main.yml --ask-become-pass
```

For Joplin WebDAV sync, add `--ask-vault-pass` flag.

## What this playbook does

### System configuration
- Removes Fedora bloatware (GNOME apps, Flatpak preinstalled packages)
- Updates all system packages
- Installs base packages (git, htop, wget, curl, tmux, wireguard-tools, parallel, etc.)

### Development environment
- **Build tools**: gcc, make, automake, python-devel, nodejs, npm
- **Version control**: Git with personal configuration, GitHub CLI
- **Containerization**: Docker Desktop with requirements validation
- **Python ecosystem**: pipx, Poetry, uv package manager
- **Java development**: Multiple JDK versions (8, 11, 17, 21) via Adoptium Temurin with version switching
- **Mobile development**: Flutter SDK, Android Studio, Android command-line tools
- **Code editor**: Visual Studio Code

### Desktop environment
- **GNOME customization**: GNOME Tweaks, extensions (AppIndicator, Dash to Dock, gTile)
- **Terminal**: Tilix with Ctrl+Alt+T keybinding
- **Email**: Thunderbird
- **Monitor control**: ddcutil/ddcui for external monitor brightness adjustment
- **Display**: Custom desktop background
- **File associations**: Default applications for common file types (video, images, documents, PDFs)

### Applications

**Communication**
- Discord, Telegram, Zoom (Flatpak)

**Media**
- VLC, Spotify, Stremio, qBittorrent (Flatpak)

**Browsers**
- Google Chrome, Brave (Flatpak)

**Graphics and design**
- Pinta (image editor), Inkscape (vector graphics) - Flatpak

**Productivity**
- LibreOffice (Flatpak)
- Zotero (reference manager) - Flatpak
- Joplin (notes) - AppImage with CLI and WebDAV synchronization
- Okular (PDF viewer)

**Development tools**
- TeXLive (LaTeX distribution)
- PlantUML (UML diagrams)

**System utilities**
- Conky (system monitor built from source with custom configuration)
- Gradia (screenshot tool with Print Screen keybinding)
- Caligula (ISO to USB writer)
- Btrfs Assistant (snapshot management)

**VPN**
- Mullvad VPN
- openfortivpn with UniBo VPN alias

**CLI tools**
- Jimmy (Joplin markdown exporter)
- Portfolio (my portfolio app)

### Logitech device support
- Logiops (HID++ driver built from source)
- Systemd service configuration
- Custom gestures for MX Master mouse

## Usage patterns

Run specific components using tags:

```bash
# System and base packages only
ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "system,base-packages"

# Development environment
ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "development"

# Desktop environment
ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "desktop"

# Applications
ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "applications"

# Joplin with WebDAV sync (requires vault password)
ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass --tags "joplin-cli,joplin-sync"
```

## Customization

### User configuration
Edit `group_vars/workstations.yml`:
- `local_user`: Your username
- `git_config`: Git name, email, and editor
- Package lists for each category

### Default applications
Configure file associations in `roles/desktop/defaults/main.yml`:

```yaml
video_player_app: "org.videolan.VLC.desktop"
text_editor_app: "code.desktop"
image_editor_app: "com.github.PintaProject.Pinta.desktop"
vector_graphics_app: "org.inkscape.Inkscape.desktop"
pdf_viewer_app: "okularApplication_pdf.desktop"
office_suite_app: "org.libreoffice.LibreOffice.desktop"
```

Apply with: `ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "desktop,mimeapps"`

### Joplin WebDAV sync
1. Edit `roles/applications/defaults/main.yml`:
   ```yaml
   joplin_sync_webdav_path: "YOUR_WEBDAV_URL"
   joplin_sync_webdav_username: "YOUR_USERNAME"
   ```

2. Create encrypted vault:
   ```bash
   ansible-vault create group_vars/vault/joplin.yml
   ```

   Add password:
   ```yaml
   vault_joplin_webdav_password: "YOUR_PASSWORD"
   ```

## BTRFS subvolume setup

Optional script to exclude `/var` directories from snapshots by creating separate subvolumes.

Edit `USER_NAME` in `btrfs-subvolumes-setup.sh`, then run:

```bash
chmod +x btrfs-subvolumes-setup.sh
sudo ./btrfs-subvolumes-setup.sh
```

Creates subvolumes for `var/cache`, `var/log`, `var/tmp`, and updates `/etc/fstab`.

## Features

- **Idempotent**: Safe to run multiple times
- **Modular**: Use tags for selective execution
- **Version-controlled**: Application versions tracked with metadata files for update detection 