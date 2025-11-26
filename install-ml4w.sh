#!/usr/bin/env bash

# ML4W (My Linux 4 Work) Installation Script
# This script installs ML4W dotfiles and Hyprland environment
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

print_step() {
    printf '\033[0;34m[STEP]\033[0m %s\n' "$1"
}

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then
    print_error "Please run as a regular user, not root"
    exit 1
fi

# Check internet connection
print_info "Checking internet connection..."
if ! ping -c 1 archlinux.org &> /dev/null; then
    print_error "No internet connection. Please connect to the internet first."
    exit 1
fi

print_info "Starting ML4W installation..."
print_info "This will install Hyprland, ML4W dotfiles, and all dependencies"
printf '\n'

# Update system
print_step "Updating system..."
sudo pacman -Syu --noconfirm

# Install yay (AUR helper) if not present
print_step "Installing yay AUR helper..."
if ! command -v yay &> /dev/null; then
    # Install dependencies for building yay
    sudo pacman -S --needed --noconfirm git base-devel
    
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    print_info "yay installed successfully"
else
    print_info "yay is already installed"
fi

# Install required packages from official repositories
print_step "Installing required packages from official repos..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    waybar \
    wofi \
    dunst \
    swww \
    swaylock-effects \
    wlogout \
    xdg-desktop-portal-hyprland \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    qt5ct \
    qt6ct \
    pipewire \
    wireplumber \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    brightnessctl \
    pamixer \
    pavucontrol \
    bluez \
    bluez-utils \
    blueman \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    file-roller \
    firefox \
    neofetch \
    fastfetch \
    htop \
    btop \
    wget \
    curl \
    zip \
    unzip \
    p7zip \
    gtk3 \
    gtk4 \
    gtk-engine-murrine \
    gnome-themes-extra \
    papirus-icon-theme \
    xdg-user-dirs \
    xdg-utils \
    gvfs \
    gvfs-mtp

# Install fonts
print_step "Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    ttf-fira-sans \
    ttf-fira-code \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk

# Install AUR packages
print_step "Installing AUR packages..."
yay -S --needed --noconfirm \
    swayosd-git \
    hyprpicker \
    hyprpaper \
    nwg-look-bin

# Create necessary directories
print_step "Creating configuration directories..."
mkdir -p ~/.config
mkdir -p ~/.local/share/wallpapers
mkdir -p ~/Pictures/screenshots
mkdir -p ~/Documents
mkdir -p ~/Downloads
mkdir -p ~/Music
mkdir -p ~/Videos

# Initialize XDG user directories
xdg-user-dirs-update

# Clone ML4W dotfiles
print_step "Cloning ML4W dotfiles..."
if [ -d ~/dotfiles ]; then
    print_warn "Dotfiles directory already exists, backing up..."
    mv ~/dotfiles ~/dotfiles.backup."$(date +%Y%m%d_%H%M%S)"
fi

cd ~
git clone --depth=1 https://gitlab.com/stephan-raabe/dotfiles.git ~/dotfiles

# Install ML4W dotfiles
print_step "Installing ML4W dotfiles..."
cd ~/dotfiles

# Check if install script exists
if [ -f install.sh ]; then
    chmod +x install.sh
    ./install.sh
elif [ -f .install/install.sh ]; then
    chmod +x .install/install.sh
    ./.install/install.sh
else
    print_error "ML4W install script not found"
    print_info "Attempting manual installation..."
    
    # Manual fallback installation
    if [ -d hypr ]; then
        cp -r hypr ~/.config/
    fi
    if [ -d waybar ]; then
        cp -r waybar ~/.config/
    fi
    if [ -d kitty ]; then
        cp -r kitty ~/.config/
    fi
    if [ -d wofi ]; then
        cp -r wofi ~/.config/
    fi
    if [ -d dunst ]; then
        cp -r dunst ~/.config/
    fi
fi

# Configure Spanish keyboard for Hyprland
print_step "Configuring Spanish keyboard layout for Hyprland..."
if [ -f ~/.config/hypr/hyprland.conf ]; then
    # Check if keyboard config already exists
    if ! grep -q "kb_layout = es" ~/.config/hypr/hyprland.conf; then
        # Add or update keyboard configuration
        sed -i '/kb_layout/d' ~/.config/hypr/hyprland.conf
        sed -i '/input {/a\    kb_layout = es' ~/.config/hypr/hyprland.conf
    fi
else
    print_warn "Hyprland config not found, creating basic configuration..."
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration

input {
    kb_layout = es
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
    sensitivity = 0
}

monitor=,preferred,auto,1

exec-once = waybar
exec-once = dunst
exec-once = swww init

# More configuration will be added by ML4W
EOF
fi

# Enable required services
print_step "Enabling required services..."
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

# Enable bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Set up default applications
print_step "Setting up default applications..."
xdg-mime default thunar.desktop inode/directory
xdg-mime default firefox.desktop x-scheme-handler/http
xdg-mime default firefox.desktop x-scheme-handler/https

# Create a helper script to start Hyprland
print_step "Creating Hyprland launcher..."
cat > ~/.config/hypr/start-hyprland.sh << 'EOF'
#!/bin/bash
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export MOZ_ENABLE_WAYLAND=1
exec Hyprland
EOF

chmod +x ~/.config/hypr/start-hyprland.sh

print_info "==========================================="
print_info "ML4W installation complete!"
print_info "==========================================="
printf '\n'
print_info "System configured with:"
print_info "  - Keyboard layout: Spanish (es)"
print_info "  - Hyprland window manager"
print_info "  - ML4W dotfiles"
print_info "  - All required dependencies"
printf '\n'
print_info "To start Hyprland:"
print_info "1. Reboot: sudo reboot"
print_info "2. Login to TTY"
print_info "3. Type: Hyprland"
printf '\n'
print_warn "Recommended: Install a display manager"
printf '  sudo pacman -S sddm\n'
printf '  sudo systemctl enable sddm\n'
printf '\n'
print_info "Run post-install.sh for additional software and optimizations"
printf '\n'