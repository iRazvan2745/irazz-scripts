#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$2"
        exit 1
    fi
}

display_banner() {
    echo -e "${GREEN}"
    echo " __                                  "
    echo "/\\_\\  _ __    __     ____    ____    "
    echo "\\/\\ \\/\\\`'__\\/'__\\\`\\  /\\_ ,\\\`\\ /\\_ ,\\\`\\  "
    echo " \\ \\ \\ \\ \\//\\ \\L\\.\\_\\\\/_/  /_\\/_/  /_ "
    echo "  \\ \\_\\ \\_\\\\ \\__/.\\_\\ /\\____\\ /\\____\\"
    echo "   \\/_/\\/_/ \\/__/\\/_/ \\/____/ \\/____/"
    echo -e "${NC}"
    echo -e "${RED}Debian Setup Script${NC}\n"
}

check_os() {
    print_status "Checking operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
            print_success "Confirmed Debian 12"
        else
            print_error "This script requires Debian 12"
            exit 1
        fi
    else
        print_error "Cannot determine OS, /etc/os-release not found"
        exit 1
    fi
}

update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    check_success "System updated successfully" "Failed to update system"
}

install_packages() {
    print_status "Installing required packages..."
    apt install -y curl sudo neovim btop htop neofetch nload git
    check_success "Packages installed successfully" "Failed to install packages"
}

install_docker() {
    print_status "Installing Docker Engine..."
    curl -fsSL https://get.docker.com | bash
    check_success "Docker installed successfully" "Failed to install Docker"
    
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        print_success "Added user to docker group"
    fi
}

install_nvm() {
    print_status "Installing NVM (Node Version Manager)..."
    
    if [ -n "$SUDO_USER" ]; then
        REAL_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
        NVM_DIR="$REAL_HOME/.nvm"
        mkdir -p "$NVM_DIR"
        chown $SUDO_USER:$SUDO_USER "$NVM_DIR"
        
        su - $SUDO_USER -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
        check_success "NVM installed successfully" "Failed to install NVM"
    else
        NVM_DIR="$HOME/.nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        check_success "NVM installed successfully" "Failed to install NVM"
    fi
}

install_node() {
    print_status "Installing latest Node.js..."
    
    if [ -n "$SUDO_USER" ]; then
        su - $SUDO_USER -c "export NVM_DIR=\$HOME/.nvm && [ -s \$NVM_DIR/nvm.sh ] && . \$NVM_DIR/nvm.sh && nvm install node && nvm use node"
    else
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node
        nvm use node
    fi
    check_success "Node.js installed successfully" "Failed to install Node.js"
}

install_bun() {
    print_status "Installing Bun..."
    
    if [ -n "$SUDO_USER" ]; then
        su - $SUDO_USER -c "export NVM_DIR=\$HOME/.nvm && [ -s \$NVM_DIR/nvm.sh ] && . \$NVM_DIR/nvm.sh && npm i -g bun"
    else
        npm i -g bun
    fi
    check_success "Bun installed successfully" "Failed to install Bun"
}

main() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
    
    display_banner
    check_os
    update_system
    install_packages
    install_docker
    install_nvm
    install_node
    install_bun
    
    print_success "Setup completed successfully!"
}

main
