#!/bin/bash

# Configure passwordless sudo for sudo group
sudo sed -i 's/^%sudo\s\+ALL=(ALL:ALL)\s\+ALL$/%sudo   ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Enable non-free and contrib components
sudo sed -i 's/^deb \(.*\) main$/deb \1 main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo sed -i 's/^deb-src \(.*\) main$/deb-src \1 main contrib non-free non-free-firmware/' /etc/apt/sources.list

# Install base packages
sudo apt update && sudo apt full-upgrade -y
sudo apt install zsh nala file lsd fzf git wget curl bat btop cifs-utils tar unzip unrar unar unace bzip2 xz-utils 7zip fastfetch -y

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

# Clone and install dotfiles
git clone https://github.com/chriscorbell/terminal-dotfiles /tmp/terminal-dotfiles
mkdir "$HOME/.config"
cp -r /tmp/terminal-dotfiles/starship.toml "$HOME/.config/"
cp -r /tmp/terminal-dotfiles/debian/.zshrc "$HOME/"

# Change default shell to ZSH
chsh -s /usr/bin/zsh
