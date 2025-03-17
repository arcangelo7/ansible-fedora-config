# Fedora System Configuration with Ansible

This repository contains Ansible playbooks and roles to automatically configure a Fedora system with my personal settings.

## Prerequisites

- Fedora (tested on Fedora 41)
- Ansible installed (`sudo dnf install ansible`)

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/arcangelo/fedora-ansible-config.git
   cd fedora-ansible-config
   ```

2. Run the main playbook:
   ```bash
   ansible-playbook -i inventory.yml main.yml --ask-become-pass
   ```

   Or run only specific tags:
   ```bash
   # System update and base packages
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "system,base-packages"
   
   # Development environment configuration
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "development"
   
   # Docker installation
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "docker"
   
   # Desktop and browser configuration
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "desktop,browser"
   
   # Cursor (code editor) installation
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "cursor"
   ```

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
- Brave Browser via Flatpak (`tags: desktop, browser, brave`)

### Applications
Installs and configures additional applications:
- Cursor (AI-first code editor) as AppImage (`tags: applications, cursor`)
  - Downloads the AppImage to `/opt/appimages/`
  - Extracts the icon from the AppImage
  - Creates an application menu entry
  - Makes the AppImage accessible from anywhere in the system

## Customization

You can customize the configuration by modifying the `group_vars/workstations.yml` file, which includes:

- `fedora_bloatware`: List of DNF packages to remove
- `flatpak_bloatware`: List of Flatpak applications to remove
- `common_packages`: List of base packages to install
- `development_packages`: List of development packages to install
- `git_config`: Git configuration (username, email, editor)
- `desktop_theme`: Default desktop theme
- `desktop_icon_theme`: Default icon theme
- `desktop_dark_mode`: Dark mode activation

Additionally, you can modify the specific settings for each role in their respective `defaults/main.yml` files. 