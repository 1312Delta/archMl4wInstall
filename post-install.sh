#!/bin/bash

# Post-Installation Script for Arch + ML4W
# Optional enhancements and additional software

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please run as a regular user, not root${NC}"
    exit 1
fi

echo "=========================================="
echo "  Post-Installation Enhancement Script   "
echo "=========================================="
echo ""

# Display manager installation
printf 'Install SDDM display manager? (y/n): '
read -r install_sddm
if [ "$install_sddm" = "y" ]; then
    print_step "Installing SDDM..."
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm
    print_info "SDDM will start on next boot"
fi

# Development tools
printf 'Install development tools (VSCode, Docker, etc.)? (y/n): '
read -r install_dev
if [ "$install_dev" = "y" ]; then
    print_step "Installing development tools..."
    
    # Install from official repos first
    sudo pacman -S --needed --noconfirm \
        docker \
        docker-compose \
        github-cli \
        nodejs \
        npm \
        python \
        python-pip
    
    # Install VSCode from AUR
    yay -S --needed --noconfirm visual-studio-code-bin
    
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    print_info "Logout and login for Docker group to take effect"
fi

# Multimedia applications
printf 'Install multimedia applications (VLC, GIMP, etc.)? (y/n): '
read -r install_media
if [ "$install_media" = "y" ]; then
    print_step "Installing multimedia applications..."
    sudo pacman -S --needed --noconfirm \
        vlc \
        gimp \
        inkscape \
        obs-studio \
        mpv \
        eog
fi

# Office suite
printf 'Install LibreOffice? (y/n): '
read -r install_office
if [ "$install_office" = "y" ]; then
    print_step "Installing LibreOffice..."
    sudo pacman -S --needed --noconfirm libreoffice-fresh
fi

# Gaming utilities
printf 'Install gaming utilities (Steam, Lutris)? (y/n): '
read -r install_gaming
if [ "$install_gaming" = "y" ]; then
    print_step "Installing gaming utilities..."
    sudo pacman -S --needed --noconfirm \
        steam \
        lutris \
        wine \
        wine-mono \
        wine-gecko \
        gamemode \
        lib32-gamemode
fi

# System optimization
print_step "Applying system optimizations..."

# Enable parallel downloads in pacman
sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Enable multilib repository
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    print_info "Enabling multilib repository..."
    echo "" | sudo tee -a /etc/pacman.conf
    echo "[multilib]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
fi

# Install useful utilities
print_step "Installing useful utilities..."
sudo pacman -S --needed --noconfirm \
    rsync \
    rclone \
    tmux \
    zsh \
    fish \
    bat \
    eza \
    ripgrep \
    fd \
    fzf \
    tree \
    ncdu \
    tldr \
    man-db \
    man-pages

# Oh My Zsh installation
printf 'Install Oh My Zsh? (y/n): '
read -r install_omz
if [ "$install_omz" = "y" ]; then
    print_step "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install popular plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    
    print_info "Oh My Zsh installed. Edit ~/.zshrc to customize"
fi

# Set up automatic snapshots with timeshift
printf 'Install Timeshift for system snapshots? (y/n): '
read -r install_timeshift
if [ "$install_timeshift" = "y" ]; then
    print_step "Installing Timeshift..."
    sudo pacman -S --needed --noconfirm timeshift
    print_info "Run 'sudo timeshift-gtk' to configure snapshots"
fi

# Create useful aliases
print_step "Setting up useful aliases..."
cat >> ~/.bashrc << 'EOF'

# Custom aliases
alias ls='eza --icons'
alias ll='eza -lah --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias update='sudo pacman -Syu && yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo "No orphaned packages to remove"'
alias mirrors='sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'
EOF

print_info "Post-installation complete!"
printf "\n"
printf "==========================================\n"
printf "  Recommended next steps:                \n"
printf "==========================================\n"
printf "1. Reboot your system\n"
printf "2. Configure Timeshift for system snapshots\n"
printf "3. Customize Hyprland config in ~/.config/hypr/\n"
printf "4. Explore Waybar config in ~/.config/waybar/\n"
printf "5. Set up your personal wallpapers in ~/.local/share/wallpapers/\n"
printf "\n"