#!/usr/bin/env bash

# Arch Linux Base Installation Script
# This script automates the base installation of Arch Linux
# Keyboard Layout: Spanish (es)

set -e

# Colors for output - using printf for better compatibility
print_info() {
    printf '\033[0;32m[INFO]\033[0m %s\n' "$1"
}

print_warn() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$1"
}

print_error() {
    printf '\033[0;31m[ERROR]\033[0m %s\n' "$1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Check if running in UEFI mode
if [ ! -d /sys/firmware/efi/efivars ]; then
    print_error "This script requires UEFI mode"
    exit 1
fi

print_info "Starting Arch Linux installation..."

# Set Spanish keyboard layout for installation
print_info "Setting Spanish keyboard layout..."
loadkeys es

# Verify boot mode
print_info "Verifying UEFI boot mode..."
ls /sys/firmware/efi/efivars > /dev/null

# Update system clock
print_info "Updating system clock..."
timedatectl set-ntp true

# List available disks
print_info "Available disks:"
lsblk -d -o NAME,SIZE,TYPE | grep disk

# Prompt for disk selection
printf '\n'
printf 'Enter the disk to install Arch (e.g., sda, nvme0n1, vda): '
read -r DISK
DISK="/dev/${DISK}"

if [ ! -b "$DISK" ]; then
    print_error "Disk $DISK does not exist"
    exit 1
fi

print_warn "WARNING: All data on $DISK will be erased!"
printf 'Are you sure you want to continue? (yes/no): '
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Installation cancelled"
    exit 0
fi

# Get user input
printf 'Enter hostname: '
read -r HOSTNAME
printf 'Enter username: '
read -r USERNAME
printf 'Enter user password: '
read -rs USER_PASSWORD
printf '\n'
printf 'Enter root password: '
read -rs ROOT_PASSWORD
printf '\n'

# Partition the disk
print_info "Partitioning disk $DISK..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 512MiB 100%

# Wait for the kernel to recognize the partitions
sleep 2
partprobe "$DISK"
sleep 2

# Determine partition names
if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

print_info "EFI Partition: $EFI_PART"
print_info "Root Partition: $ROOT_PART"

# Format partitions
print_info "Formatting partitions..."
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

# Mount partitions
print_info "Mounting partitions..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# Install base system with all necessary packages
print_info "Installing base system (this may take a while)..."
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager \
    grub efibootmgr nano vim git sudo wget curl \
    man-db man-pages texinfo bash-completion

# Generate fstab
print_info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Create configuration script for chroot
cat > /mnt/configure.sh << 'CONFIGURE_EOF'
#!/bin/bash

# Set timezone (Madrid, Spain)
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Localization - Spanish and English
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf

# Console keyboard layout - Spanish
echo "KEYMAP=es" > /etc/vconsole.conf

# Network configuration
echo "HOSTNAME_PLACEHOLDER" > /etc/hostname

cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   HOSTNAME_PLACEHOLDER.localdomain HOSTNAME_PLACEHOLDER
EOF

# Root password
echo "root:ROOT_PASSWORD_PLACEHOLDER" | chpasswd

# Create user
useradd -m -G wheel,audio,video,optical,storage -s /bin/bash USERNAME_PLACEHOLDER
echo "USERNAME_PLACEHOLDER:USER_PASSWORD_PLACEHOLDER" | chpasswd

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable NetworkManager
systemctl enable NetworkManager

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Base configuration complete!"
CONFIGURE_EOF

# Replace placeholders in configuration script
sed -i "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" /mnt/configure.sh
sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/configure.sh
sed -i "s/USER_PASSWORD_PLACEHOLDER/$USER_PASSWORD/g" /mnt/configure.sh
sed -i "s/ROOT_PASSWORD_PLACEHOLDER/$ROOT_PASSWORD/g" /mnt/configure.sh

# Make configuration script executable
chmod +x /mnt/configure.sh

# Run configuration in chroot
print_info "Configuring system..."
arch-chroot /mnt /configure.sh

# Remove configuration script
rm /mnt/configure.sh

print_info "==========================================="
print_info "Base Arch Linux installation complete!"
print_info "==========================================="
printf '\n'
print_info "System configured with:"
print_info "  - Keyboard layout: Spanish (es)"
print_info "  - Locale: es_ES.UTF-8"
print_info "  - Timezone: Europe/Madrid"
print_info "  - Hostname: $HOSTNAME"
print_info "  - User: $USERNAME"
printf '\n'
print_info "Next steps:"
print_info "1. umount -R /mnt"
print_info "2. reboot"
print_info "3. Login with your user account"
print_info "4. Run install-ml4w.sh"
printf '\n'