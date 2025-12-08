#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NOCOLOR='\033[0m' # No Color

echo -e "${CYAN}"
cat << "EOF"


       __      __  _____ __
  ____/ /___  / /_/ __(_) /__  _____
 / __  / __ \/ __/ /_/ / / _ \/ ___/
/ /_/ / /_/ / /_/ __/ / /  __(__  )
\__,_/\____/\__/_/_/_/_/\___/____/
   (_)___  _____/ /_____ _/ / /__  _____
  / / __ \/ ___/ __/ __ `/ / / _ \/ ___/
 / / / / (__  ) /_/ /_/ / / /  __/ /
/_/_/ /_/____/\__/\__,_/_/_/\___/_/


EOF
echo -e "${NOCOLOR}"

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution"
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Configure passwordless sudo
if sudo grep -q '^%wheel[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$' /etc/sudoers; then
    sudo sed -i 's/^%wheel[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
    echo "Configured passwordless sudo for wheel group"
elif sudo grep -q '^%sudo[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$' /etc/sudoers; then
    sudo sed -i 's/^%sudo[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
    echo "Configured passwordless sudo for sudo group"
else
    echo "Warning: Could not find standard sudo group configuration in /etc/sudoers"
fi

# Distribution-specific setup
case $DISTRO in
    debian)
        echo "Setting up Debian..."
        
        # Enable non-free and contrib components
        sudo sed -i 's/^deb \(.*\) main$/deb \1 main contrib non-free non-free-firmware/' /etc/apt/sources.list
        sudo sed -i 's/^deb-src \(.*\) main$/deb-src \1 main contrib non-free non-free-firmware/' /etc/apt/sources.list
        
        # Install base packages
        sudo apt update && sudo apt full-upgrade -y
        sudo apt install build-essential zsh nala file lsd fzf git wget curl bat btop cifs-utils tar unzip unrar unar unace bzip2 xz-utils 7zip fastfetch -y
        
        # Install GitHub CLI
        sudo mkdir -p -m 755 /etc/apt/keyrings
        out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
        cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        sudo mkdir -p -m 755 /etc/apt/sources.list.d
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
        
        # Install Docker
        sudo apt update
        sudo apt install ca-certificates curl -y
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
        sudo apt update
        sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        sudo usermod -aG docker $USER
        ;;
        
    arch)
        echo "Setting up Arch Linux..."
        
        # Update system
        sudo pacman -Syu --noconfirm
        
        # Install base packages
        sudo pacman -S --noconfirm zsh file lsd fzf git base-devel wget curl bat btop cifs-utils tar unzip unrar unar unace bzip2 xz p7zip fastfetch
        
        # Install yay AUR helper
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -

        # Install GitHub CLI
        sudo pacman -S --noconfirm github-cli
        
        # Install Docker
        sudo pacman -S --noconfirm docker docker-compose docker-buildx
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        ;;
        
    alpine)
        echo "Setting up Alpine Linux..."
        
        # Enable community repository
        sudo sed -i 's/^#\(.*\/community\)$/\1/' /etc/apk/repositories
        
        # Update system
        sudo apk update && sudo apk upgrade
        
        # Install base packages
        sudo apk add build-base zsh file lsd fzf git wget curl bat btop cifs-utils tar unzip unrar unar unace bzip2 xz p7zip fastfetch github-cli docker docker-compose docker-cli-buildx

        # Set up Docker
        sudo rc-update add docker boot
        sudo service docker start
        sudo usermod -aG docker $USER
        ;;
        
    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

# Clone and install dotfiles
git clone https://github.com/chriscorbell/dotfiles /tmp/dotfiles
cp -r /tmp/dotfiles/.config "$HOME/"
cp /tmp/dotfiles/.zshrc "$HOME/"

# Change default shell to ZSH
chsh -s $(which zsh)
