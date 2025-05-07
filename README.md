# Fedora System Configuration with Ansible

![Configured Desktop Preview](preview.png)

This repository contains Ansible playbooks and roles to automatically configure a Fedora system with my personal settings.

## Table of Contents

- [Fedora System Configuration with Ansible](#fedora-system-configuration-with-ansible)
  - [Prerequisites](#prerequisites)
  - [Ansible Usage](#ansible-usage)
  - [BTRFS Subvolume Setup](#btrfs-subvolume-setup)
  - [Idempotency](#idempotency)
  - [Repository Structure](#repository-structure)
  - [Available Roles](#available-roles)
    - [Common](#common)
    - [Development](#development)
    - [Desktop](#desktop)
    - [Applications](#applications)
  - [Customization](#customization)
    - [Managing Joplin Synchronization Credentials](#managing-joplin-synchronization-credentials)

## Prerequisites

- Fedora (tested on Fedora 41)
- Ansible installed (`sudo dnf install ansible`)
- For the BTRFS script: A BTRFS filesystem setup on the root partition.

## Ansible Usage

> **Note:** Before running the playbook, ensure the `local_user` variable in `group_vars/workstations.yml` is set to your actual username.

1. Clone this repository:
   ```bash
   git clone https://github.com/arcangelo/fedora-ansible-config.git
   cd fedora-ansible-config
   ```

2. Run the main playbook:
   This playbook uses Ansible Vault to protect sensitive information (like the Joplin WebDAV password). You will be prompted for the vault password when running the full playbook, as it includes tasks requiring vaulted variables.
   ```bash
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass
   ```

   > **Important:** Before running for the first time, ensure you have configured your Joplin WebDAV credentials as described in the [Managing Joplin Synchronization Credentials](#managing-joplin-synchronization-credentials) section under "Customization".

   Or run only specific tags. You only need to add `--ask-vault-pass` if the selected tags include tasks that rely on vaulted variables (e.g., `--tags "applications"` or `--tags "joplin-sync"`):
   ```bash
   # System update and base packages (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "system,base-packages"
   
   # Development environment configuration (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "development"
   
   # Docker installation (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "docker"
   
   # Desktop and browser configuration (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "desktop,browser"
   
   # Cursor (code editor) installation (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "cursor"
   
   # Android Studio installation (no vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "android-studio"

   # Example: Running applications tag which includes Joplin sync (vault needed)
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass --tags "applications"
   ```

## BTRFS Subvolume Setup

This repository also includes a shell script `btrfs-subvolumes-setup.sh` to automatically configure a recommended BTRFS subvolume layout for `/var`. This helps in organizing snapshots and managing system directories more effectively.

> **Note:** Before running the script, open `btrfs-subvolumes-setup.sh` and change the `USER_NAME` variable at the top to match your actual username.

**Why is this useful?**

Creating separate subvolumes for volatile directories under `/var` is particularly important when using snapshot tools like Snapper. Snapper allows you to take snapshots of your `root` (and potentially `home`) subvolume and restore them later.

However, directories like `/var/log`, `/var/cache`, `/var/tmp`, and `/var/lib/gdm` contain data that changes frequently and should generally *not* be rolled back with the rest of the system. If these directories are part of the main `root` snapshot and you restore an older snapshot, you might bring back outdated cache files, logs, or service states.

This can lead to system inconsistencies, prevent services from starting correctly, or even make the system unbootable from GRUB. By placing these volatile directories on their own subvolumes using this script, you ensure they are excluded from `root` snapshots, maintaining system stability during rollbacks.

**Usage:**

1.  Navigate to the repository directory:
    ```bash
    cd fedora-ansible-config
    ```
2.  Make the script executable:
    ```bash
    chmod +x btrfs-subvolumes-setup.sh
    ```
3.  Run the script with `sudo`:
    ```bash
    sudo ./btrfs-subvolumes-setup.sh
    ```

**What it does:**

- Creates separate BTRFS subvolumes for directories like `var/cache`, `var/log`, `var/tmp`, etc.
- Backs up existing data before creating subvolumes.
- Updates `/etc/fstab` to mount the new subvolumes correctly.
- Restores SELinux contexts and user permissions.

**Important:** This script modifies your `/etc/fstab` and filesystem structure. It's recommended to back up important data before running it, although the script includes its own backup steps.

## Idempotency

This playbook is designed to be fully idempotent, meaning it can be run multiple times without causing unnecessary changes. Each task includes specific checks to determine if the operation is actually needed:

- **System updates**: The playbook checks if updates are available before running the update process
- **Package installation**: Each package is individually checked to see if it's already installed
- **Git configuration**: The current Git settings are compared with the desired ones before making changes
- **Docker installation**: The system checks if Docker Desktop is already installed and if requirements are met
- **Application installation**: For applications like Cursor, the playbook verifies if the binaries, desktop entries, and PATH links already exist

This makes the playbook:
1. **Faster**: Skips operations that aren't needed
2. **Safer**: Avoids unnecessary changes to the system
3. **Reusable**: Can be run regularly to keep the system up to date and configured correctly

You can safely run the entire playbook or specific parts using tags whenever you want to ensure your system matches the desired configuration.

## Repository Structure

- `inventory.yml`: Ansible inventory file (configures localhost as target)
- `main.yml`: Main playbook that includes all roles
- `ansible.cfg`: Ansible configuration
- `group_vars/workstations.yml`: Configurable variables for the workstations group
- `roles/`: Directory containing various Ansible roles
  - `common/`: Basic system configurations
  - `development/`: Development tools and Git configuration
  - `desktop/`: GNOME desktop environment configurations
  - `applications/`: Additional applications

## Available Roles

### Common
Installs and configures basic system components:
- System update (`tags: system, update`)
- Base packages like git, htop, tilix, wget, curl (`tags: packages, base-packages`)
- Removal of DNF and Flatpak bloatware packages (`tags: system, cleanup, bloatware`)

### Development
Installs and configures development tools:
- Compilers and build tools like gcc, make, automake (`tags: development, packages`)
- Custom Git configuration (`tags: development, git`)
- Docker and system requirements (`tags: development, docker, docker_requirements`)
- Python and Node.js development tools

### Desktop
Configures the GNOME desktop environment:
- Themes and icons with gnome-tweaks (`tags: desktop, themes`)
- GNOME extensions like dash-to-dock and appindicator (`tags: desktop, gnome-extensions`)
- Flatpak for application management (`tags: desktop, browser`)

### Applications
Installs and configures additional applications:
- Firefox via Flatpak (`tags: applications, firefox`)
- Discord via Flatpak (`tags: applications, discord`)
- VLC via Flatpak (`tags: applications, vlc`)
- Drawing via Flatpak (`tags: applications, drawing`)
- Zoom via Flatpak (`tags: applications, zoom`)
- Android Studio via Flatpak (`tags: applications, development, android-studio`)
- Cursor (AI-first code editor) as AppImage (`tags: applications, cursor`)
  - Downloads the AppImage to `/opt/appimages/`
  - Extracts the icon from the AppImage
  - Creates an application menu entry
  - Makes the AppImage accessible from anywhere in the system
- Conky system monitor (`tags: applications, conky, conky-config`)
  - Installs Conky and `lm-sensors` (for temperature readings).
  - Deploys the *Hybrid* theme configuration files (`hybrid/hybrid.conf`, `hybrid/lua/hybrid-rings.lua`, fonts, images) to `~/.config/conky/`.
  - **Resolution Support:** This theme includes configurations for QHD (default) and FHD (1920x1080) resolutions. You can select the desired resolution when running the playbook using the `-e` flag:
    ```bash
    # Use QHD configuration (default if variable is omitted)
    ansible-playbook main.yml --tags conky
    # Or explicitly
    ansible-playbook main.yml -e "conky_resolution=qhd" --tags conky

    # Use FHD configuration
    ansible-playbook main.yml -e "conky_resolution=fhd" --tags conky
    ```
  - **Important:** After installation, you likely need to run `sudo sensors-detect` once manually and follow its prompts (answering 'yes' is usually safe for standard detection) to ensure all hardware sensors (CPU temp, fans, etc.) are detected correctly. A reboot might be needed afterward.
  - **Customization:** The provided Conky theme (`hybrid`) is highly personalized and **will likely require manual adjustments** to work correctly on your specific hardware, even after selecting the correct base resolution. To make persistent changes, edit the source files within the `hybrid/` directory in this repository:
    - `hybrid/hybrid.conf` (QHD) / `hybrid/hybrid-fhd.conf` (FHD): Modify general layout, fonts, colors, and displayed text information (like network interface names).
    - `hybrid/lua/hybrid-rings.lua` (QHD) / `hybrid/lua/hybrid-rings-fhd.lua` (FHD): Adjust the ring appearance, positioning, and the logic for reading sensor data (especially CPU core count detection and `${platform ...}` arguments which depend on your specific hardware sensors found via the `sensors` command).
  - Changes made directly to `~/.config/conky/conky.conf` or the Lua script in `~/.config/conky/hybrid/lua/` will work for testing but will be overwritten if you re-run the Ansible playbook with the `conky` tag.
  - **Autostart:** Conky is configured to start automatically on login using a systemd user service (`~/.config/systemd/user/conky.service`).
  - **Disabling Autostart:** If you don't want Conky to start automatically, you can disable the systemd user service by running:
    ```bash
    systemctl --user disable --now conky.service
    ```

## Customization

You can customize the configuration by modifying the `group_vars/workstations.yml` file, which includes:

- `local_user`: **(Important!)** Set this to your local username. Used by several roles.
- `fedora_bloatware`: List of DNF packages to remove
- `flatpak_bloatware`: List of Flatpak applications to remove
- `common_packages`: List of base packages to install
- `development_packages`: List of development packages to install
- `git_config`: Git configuration (username, email, editor)

Additionally, you can modify the specific settings for each role in their respective `defaults/main.yml` files. 

### Managing Joplin Synchronization Credentials

This configuration requires you to provide your personal WebDAV server details for Joplin synchronization.

Default values are placeholders in `roles/applications/defaults/main.yml`, but you **must override** them with your own settings:

1.  **Configure Non-Sensitive Details:** Create a new file (e.g., `group_vars/all/joplin_settings.yml`) or add to an existing *non-vault* group variables file. Define your WebDAV path and username here:
    ```yaml
    # group_vars/all/joplin_settings.yml
    joplin_sync_webdav_path: "YOUR_WEBDAV_URL_HERE"
    joplin_sync_webdav_username: "YOUR_WEBDAV_USERNAME_HERE"
    ```

2.  **Configure Password Securely (using Vault):** 
    *   If you haven't already, create an encrypted vault file (e.g., `group_vars/all/vault.yml`):
        ```bash
        ansible-vault create group_vars/all/vault.yml
        ```
        Set a strong vault password when prompted.
    *   Inside the vault file (which opens in your editor), define the password variable using **your actual WebDAV password**:
        ```yaml
        # group_vars/all/vault.yml
        vault_joplin_webdav_password: "YOUR_ACTUAL_WEBDAV_PASSWORD"
        ```
    *   Save and close the editor.

3.  **Run Playbook with Vault Password:** Remember to always use the `--ask-vault-pass` flag when running `ansible-playbook` so it can decrypt the password:
    ```bash
    ansible-playbook -i inventory.yml main.yml --ask-become-pass --ask-vault-pass
    ```

This ensures your sensitive password remains encrypted while allowing you to customize the synchronization target for your own environment. 