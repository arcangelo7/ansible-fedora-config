# Fedora System Configuration with Ansible

Questo repository contiene playbook e ruoli Ansible per configurare automaticamente un sistema Fedora con le mie impostazioni personali.

## Prerequisiti

- Fedora (testato su Fedora 41)
- Ansible installato (`sudo dnf install ansible`)

## Utilizzo

1. Clona questo repository:
   ```bash
   git clone https://github.com/arcangelo/fedora-ansible-config.git
   cd fedora-ansible-config
   ```

2. Esegui il playbook principale:
   ```bash
   ansible-playbook -i inventory.yml main.yml --ask-become-pass
   ```

   Oppure esegui solo specifici tag:
   ```bash
   ansible-playbook -i inventory.yml main.yml --ask-become-pass --tags "system,packages"
   ```

## Contenuti

- `inventory.yml`: File di inventario Ansible
- `main.yml`: Playbook principale
- `roles/`: Directory contenente i vari ruoli Ansible
  - `common/`: Configurazioni di base del sistema
  - `development/`: Strumenti di sviluppo
  - `desktop/`: Configurazioni dell'ambiente desktop

## Ruoli disponibili

### Common
Installa e configura componenti di base del sistema:
- Aggiornamento del sistema
- Pacchetti di base (vim, git, htop, tmux, wget, curl)

### Development
Installa e configura strumenti di sviluppo:
- Compilatori e strumenti di build (gcc, make, etc.)
- Strumenti di sviluppo Python e Node.js
- Docker

### Desktop
Configura l'ambiente desktop GNOME:
- Temi e icone
- Estensioni GNOME
- Impostazioni personalizzate

## Personalizzazione

Puoi personalizzare la configurazione modificando i file in `group_vars/workstations.yml`. 