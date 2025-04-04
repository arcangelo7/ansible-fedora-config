#!/bin/bash
set -e

# === CONFIGURAZIONE ===
USER_NAME="arcangelo"
# Ottieni l'UUID della partizione root in modo dinamico
ROOT_UUID=$(findmnt -n -o UUID /)
SUBVOLUMES=(
  "var/cache"
  "var/crash"
  "var/lib/AccountsService"
  "var/lib/gdm"
  "var/log"
  "var/spool"
  "var/tmp"
)

echo "📦 Avvio creazione sottovolumi Btrfs avanzati per Fedora (utente: $USER_NAME)"
echo "📍 UUID partizione root: $ROOT_UUID"
echo

# === SMONTA SUBVOLUMI GIÀ MONTATI ===
echo "🔄 Smonto eventuali subvolumi già montati..."
for sub in "${SUBVOLUMES[@]}"; do
  sudo umount -l "/${sub}" 2>/dev/null || true
done
echo

# === PULIZIA PRECEDENTI TENTATIVI ===
echo "🧹 Pulizia dei precedenti tentativi..."
for sub in "${SUBVOLUMES[@]}"; do
  if [[ -d "/${sub}-old" ]]; then
    echo "Rimuovo /${sub}-old"
    sudo rm -rf "/${sub}-old"
  fi
done
echo

# === BACKUP E PULIZIA FSTAB ===
echo "📝 Backup fstab e pulizia voci..."
sudo cp /etc/fstab /etc/fstab.backup
temp_fstab=$(mktemp)
grep -v "/var/" /etc/fstab > "$temp_fstab"
sudo cp "$temp_fstab" /etc/fstab
rm "$temp_fstab"
echo

# === FUNZIONE PER CREARE SOTTOVOLUME E MONTARLO ===
create_subvolume() {
  local subpath="$1"
  local mountpoint="/${subpath}"
  local backup="${mountpoint}-old"
  local full_subvol_path="root/${subpath}"  # Percorso completo incluso root/

  echo "🔧 Lavoro su: $mountpoint"

  if [[ -d "$mountpoint" ]]; then
    sudo mv -v "$mountpoint" "$backup"
    sudo btrfs subvolume create "$mountpoint"
    sudo cp -ar "$backup/." "$mountpoint/"
  else
    sudo btrfs subvolume create "$mountpoint"
  fi

  sudo restorecon -RF "$mountpoint"
  
  # Aggiungi a fstab usando UUID e percorso completo del subvolume
  echo "UUID=${ROOT_UUID} ${mountpoint} btrfs subvol=${full_subvol_path},compress=zstd:1,x-systemd.device-timeout=0 0 0" | sudo tee -a /etc/fstab
  echo
}

# === CREA SOTTOVOLUMI SISTEMA ===
for sub in "${SUBVOLUMES[@]}"; do
  create_subvolume "$sub"
done

# === MOUNT DI TUTTI I SUBVOLUMI ===
echo "🔄 Rimontaggio di tutti i sottovolumi da fstab..."
sudo systemctl daemon-reload
sudo mount -a

# === RIPRISTINA PERMESSI HOME ===
echo "🔐 Ripristino permessi per /home/${USER_NAME}..."
sudo chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}
sudo restorecon -RF /home/${USER_NAME}

# === ELIMINA LE DIRECTORY TEMPORANEE ===
echo "🧹 Pulizia delle vecchie directory..."
for sub in "${SUBVOLUMES[@]}"; do
  if [[ -d "/${sub}-old" ]]; then
    sudo rm -rf "/${sub}-old"
  fi
done

echo "✅ Tutto pronto! Ora hai un layout Btrfs avanzato con tutti i sottovolumi richiesti."
