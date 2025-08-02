#!/bin/bash

# PHP Dev Environment Setup Script for WSL (Windows Subsystem for Linux)
# Author: Ohene Adjei (https://ohene.dev)
# GitHub: https://github.com/oheneadjei
# License: MIT
# Date: 2025-08-01

LOG_FILE="$HOME/php-dev-setup-wsl-$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

confirm() {
    while true; do
        read -rp "$1 [Y/n]: " yn
        case $yn in
            [Yy]*|"") return 0;;
            [Nn]*) return 1;;
            *) echo "Please answer yes or no.";;
        esac
    done
}

clear
echo -e "${GREEN}Starting PHP Development Environment Setup for WSL...${NC}"
echo "Log file: $LOG_FILE"

sudo apt update && sudo apt upgrade -y

ESSENTIALS=(curl git unzip software-properties-common gnupg lsb-release ca-certificates)
echo -e "${GREEN}Installing essential tools...${NC}"
sudo apt install -y "${ESSENTIALS[@]}"

read -rp "Enter your GitHub email: " github_email
read -rp "Enter your Git user name: " git_name

git config --global user.email "$github_email"
git config --global user.name "$git_name"

ssh-keygen -t ed25519 -C "$github_email"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub

# Node.js installation
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v

# PHP installation
read -rp "Enter PHP version to install [8.4]: " php_version
php_version=${php_version:-8.4}

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
PHP_PACKAGES=(php$php_version php$php_version-cli php$php_version-curl \
php$php_version-mbstring php$php_version-xml php$php_version-zip \
php$php_version-bcmath php$php_version-intl php$php_version-gd \
php$php_version-mysql php$php_version-pgsql php$php_version-sqlite3 \
php$php_version-xdebug php$php_version-redis)
sudo apt install -y "${PHP_PACKAGES[@]}"
php -v

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

# Laravel Installer
if confirm "Install Laravel Installer globally?"; then
    composer global require laravel/installer
    export PATH="$HOME/.config/composer/vendor/bin:$PATH"
    echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    laravel --version
fi

# Xdebug Configuration
if confirm "Install Xdebug for PHP debugging?"; then
    XDEBUG_PATH=$(find /usr/lib/php -name xdebug.so 2>/dev/null | head -n 1)
    if [[ -n "$XDEBUG_PATH" ]]; then
        sudo bash -c "echo 'zend_extension=$XDEBUG_PATH' >> /etc/php/$php_version/cli/php.ini"
        sudo bash -c "echo '[Xdebug]\nxdebug.mode=develop,debug\nxdebug.start_with_request=yes\nxdebug.client_port=9003\nxdebug.log=/var/log/xdebug.log' >> /etc/php/$php_version/cli/php.ini"
        echo -e "${GREEN}Xdebug configured.${NC}"
    else
        echo -e "${RED}Xdebug not found. Please check installation.${NC}"
    fi
fi

# Database
if confirm "Install MariaDB? (MySQL alternative)"; then
    sudo apt install -y mariadb-server mariadb-client
    sudo service mysql start
    echo "Run 'sudo mysql_secure_installation' to secure MariaDB."
fi

if confirm "Install PostgreSQL?"; then
    sudo apt install -y postgresql postgresql-contrib
    sudo service postgresql start
fi

# MongoDB
if confirm "Install MongoDB and PHP extension?"; then
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt update
    sudo apt install -y mongodb-org
    sudo service mongod start
    sudo pecl install mongodb
    echo "extension=mongodb.so" | sudo tee /etc/php/$php_version/mods-available/mongodb.ini
    sudo phpenmod mongodb
fi

# GUI Tool Notes for WSL Users
echo -e "${YELLOW}\nFor database GUI tools, install these on Windows side:\n- MySQL Workbench\n- pgAdmin\n- MongoDB Compass\n\nThese work better outside WSL.\n${NC}"

# Check for Snap support (not available in WSL by default)
if confirm "Check Snap support for MongoDB Compass installation?"; then
    if command -v snap >/dev/null 2>&1; then
        echo -e "${GREEN}Snap detected.${NC}"
        if confirm "Install MongoDB Compass using Snap?"; then
            sudo snap install mongodb-compass
        fi
    else
        echo -e "${RED}Snap is not available in WSL. Install Compass on Windows side.${NC}"
    fi
fi

# Aliases
alias_file=~/.bash_aliases
ALIAS_BLOCK="\n# PHP Dev Aliases\nalias serve='php artisan serve'\nalias art='php artisan'\nstart_project() {\n  cd ~/Projects/\"\$1\" && php artisan serve\n}\n"
echo -e "$ALIAS_BLOCK" >> "$alias_file"
source "$alias_file"

sudo apt autoremove -y
sudo apt clean

# Final Checklist
echo -e "${GREEN}\nSetup complete! Log file saved to $LOG_FILE${NC}"
echo -e "Run 'serve' to quickly start Laravel server."
echo -e "${YELLOW}Git: $(git config --global user.name) <$(git config --global user.email)>${NC}"
echo -e "${YELLOW}PHP: $(php -v | head -n 1)${NC}"
echo -e "${YELLOW}Node.js: $(node -v)${NC}"
echo -e "${YELLOW}Composer: $(composer --version)${NC}"
echo -e "${GREEN}Thank you for using this WSL setup script ❤️ (https://github.com/oheneadj)${NC}"
