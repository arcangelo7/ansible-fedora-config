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

- `common_packages`: List of base packages to install
- `development_packages`: List of development packages to install
- `git_config`: Git configuration (username, email, editor)
- `desktop_theme`: Default desktop theme
- `desktop_icon_theme`: Default icon theme
- `desktop_dark_mode`: Dark mode activation

Additionally, you can modify the specific settings for each role in their respective `defaults/main.yml` files. 