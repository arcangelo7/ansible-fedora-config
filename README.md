# Fedora System Configuration with Ansible

![Configured Desktop Preview](preview.png)

Ansible playbooks to automatically configure a Fedora system with my personal settings.

## Prerequisites

- Fedora (tested on Fedora 41)
- Ansible installed (`sudo dnf install ansible`)
- For BTRFS script: BTRFS filesystem on root partition

## Usage

> **Note:** Set `local_user` in `group_vars/workstations.yml` to your username.

1. Clone and run:
   ```bash
   git clone https://github.com/arcangelo/fedora-ansible-config.git
   cd fedora-ansible-config
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass
   ```

2. Run specific tags:
   ```bash
   # System and base packages
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "system,base-packages"
   
   # Development tools
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "development"
   
   # Desktop environment
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "desktop"
   
   # Applications (requires vault)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass --tags "applications"
   ```

## BTRFS Subvolume Setup

Script to configure BTRFS subvolumes for `/var` directories to exclude them from snapshots.

> **Note:** Edit `USER_NAME` in `btrfs-subvolumes-setup.sh` before running.

```bash
chmod +x btrfs-subvolumes-setup.sh
sudo ./btrfs-subvolumes-setup.sh
```

Creates separate subvolumes for `var/cache`, `var/log`, `var/tmp`, etc. and updates `/etc/fstab`.

## Features

- **Idempotent**: Can be run multiple times safely
- **Modular**: Use tags to run specific parts
- **Configurable**: Modify variables in `group_vars/workstations.yml`

## Roles

### Common
- System update and base packages
- Cleanup of bloatware packages

### Development
- Development tools (gcc, make, etc.)
- Git configuration
- Docker Desktop
- VS Code editor
- Python tools (pipx, poetry, uv)
- Java/Maven, Flutter SDK, Android Studio

### Desktop
- GNOME themes and extensions
- Flatpak setup

### Applications
- Firefox, Discord, VLC, Zoom
- Conky system monitor
- Joplin with WebDAV sync

### Logiops
- Unofficial userspace driver for HID++ Logitech devices
- Builds from source and configures systemd service
- Default configuration for MX Master mouse with gestures

## Customization

Edit `group_vars/workstations.yml`:
- `local_user`: Your username
- `git_config`: Git settings (name, email, editor)
- Package lists for customization

### Joplin WebDAV Setup

1. Create `group_vars/all/joplin_settings.yml`:
   ```yaml
   joplin_sync_webdav_path: "YOUR_WEBDAV_URL"
   joplin_sync_webdav_username: "YOUR_USERNAME"
   ```

2. Create encrypted vault for password:
   ```bash
   ansible-vault create group_vars/all/vault.yml
   ```
   Add:
   ```yaml
   vault_joplin_webdav_password: "YOUR_PASSWORD"
   ``` 