#!/bin/bash

# Interactive PHP Development Setup Script for Linux
# Author: Ohene Adjei
# Website: https://ohene.dev
# GitHub:  github.com/oheneadj
# Version: 1.0
# License: MIT
# Description: This script sets up a PHP development environment with optional tools like Node.js, Composer
# Laravel, web servers, databases, and more.
# It includes logging, color-coded output, and user prompts for configuration.
# This script is designed for Ubuntu/Debian-based systems.
# Date: 2025-08-01

LOG_FILE="$HOME/php-dev-setup-$(date +%Y%m%d_%H%M%S).log"
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

echo -e "${GREEN}Starting PHP Development Environment Setup...${NC}"
echo "Log file: $LOG_FILE"

sudo apt update && sudo apt upgrade -y

ESSENTIALS=(curl git unzip software-properties-common gnupg lsb-release ca-certificates)
echo -e "${GREEN}Installing essential tools...${NC}"
sudo apt install -y "${ESSENTIALS[@]}"

read -rp "Enter your GitHub email: " github_email
read -rp "Enter your Git user name: " git_name

git config --global user.email "$github_email"
git config --global user.name "$git_name"

echo -e "${GREEN}Git global config set.${NC}"

ssh-keygen -t ed25519 -C "$github_email"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub

# Node.js installation
echo -e "${YELLOW}Choose Node.js installation method:${NC}"
select node_choice in "Latest LTS (default)" "nvm (Node Version Manager)" "Specific version"; do
    case $node_choice in
        "Latest LTS (default)"|"")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs
            break;;
        "nvm (Node Version Manager)")
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \ . "$NVM_DIR/nvm.sh"
            nvm install --lts
            break;;
        "Specific version")
            read -rp "Enter Node.js version (e.g., 18.17.0): " node_ver
            curl -fsSL https://deb.nodesource.com/setup_$node_ver.x | sudo -E bash -
            sudo apt install -y nodejs
            break;;
        *) echo "Invalid option.";;
    esac
done

node -v && npm -v

read -rp "Enter PHP version to install [8.4]: " php_version
php_version=${php_version:-8.4}

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
PHP_PACKAGES=(php$php_version php$php_version-cli php$php_version-fpm \
php$php_version-curl php$php_version-mbstring php$php_version-xml \
php$php_version-zip php$php_version-bcmath php$php_version-intl \
php$php_version-gd php$php_version-mysql php$php_version-pgsql \
php$php_version-sqlite3 php$php_version-xdebug php$php_version-redis)
sudo apt install -y "${PHP_PACKAGES[@]}"
php -v

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

if confirm "Install Laravel Installer globally?"; then
    composer global require laravel/installer
    export PATH="$HOME/.config/composer/vendor/bin:$PATH"
    echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    laravel --version
fi

# Xdebug auto configuration
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

# Database choice
echo -e "${YELLOW}Choose a database to install:${NC}"
select db_choice in "PostgreSQL" "MariaDB" "Skip"; do
    case $db_choice in
        PostgreSQL)
            sudo apt install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            break;;
        MariaDB)
            sudo apt install -y mariadb-server mariadb-client
            sudo systemctl start mariadb
            sudo systemctl enable mariadb
            echo -e "Run 'sudo mysql_secure_installation' to secure MariaDB."
            break;;
        Skip)
            break;;
        *) echo "Invalid option.";;
    esac
done

# Web Server choice
echo -e "${YELLOW}Choose a web server to install:${NC}"
select web_choice in "Nginx" "Apache" "Both" "Skip"; do
    case $web_choice in
        Nginx)
            sudo apt install -y nginx
            sudo systemctl start nginx
            sudo systemctl enable nginx
            break;;
        Apache)
            sudo apt install -y apache2 libapache2-mod-php$php_version
            sudo systemctl start apache2
            sudo systemctl enable apache2
            sudo chown -R $USER:www-data /var/www/html
            sudo chmod -R 775 /var/www/html
            break;;
        Both)
            sudo apt install -y nginx apache2 libapache2-mod-php$php_version
            sudo systemctl start nginx apache2
            sudo systemctl enable nginx apache2
            sudo chown -R $USER:www-data /var/www/html
            sudo chmod -R 775 /var/www/html
            break;;
        Skip)
            break;;
        *) echo "Invalid option.";;
    esac
done

# MongoDB
if confirm "Install MongoDB and PHP extension?"; then
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt update
    sudo apt install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod
    sudo pecl install mongodb
    echo "extension=mongodb.so" | sudo tee /etc/php/$php_version/mods-available/mongodb.ini
    sudo phpenmod mongodb
fi

# MongoDB Compass
if confirm "Install MongoDB Compass GUI?"; then
    sudo snap install mongodb-compass
fi

# pgAdmin
if confirm "Install pgAdmin for PostgreSQL GUI?"; then
    sudo apt install -y pgadmin4-desktop
fi

# phpMyAdmin
if confirm "Install phpMyAdmin for MySQL/MariaDB GUI?"; then
    sudo apt install -y phpmyadmin
fi

# Redis
if confirm "Install Redis for caching/queues?"; then
    sudo apt install redis-server -y
    sudo systemctl enable redis
    sudo systemctl start redis
fi

# Docker
if confirm "Install Docker + Docker Compose?"; then
    sudo apt install -y docker.io docker-compose
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}Logout and login again to apply Docker group changes.${NC}"
fi

# Valet
if confirm "Install Valet for Linux?"; then
    composer global require cpriego/valet-linux
    export PATH="$HOME/.config/composer/vendor/bin:$PATH"
    echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    valet install
fi

# Developer Aliases
alias_file=~/.bash_aliases
[[ "$SHELL" == *"zsh"* ]] && alias_file=~/.zshrc

ALIAS_BLOCK="\n# PHP Dev Aliases\nalias serve='php artisan serve'\nalias art='php artisan'\nalias nginx-restart='sudo systemctl restart nginx'\nalias mongo-start='sudo systemctl start mongod'\nstart_project() {\n  cd ~/Projects/\"\$1\" && valet link && php artisan serve\n}\n"

echo -e "$ALIAS_BLOCK" >> "$alias_file"
source "$alias_file"

# Cleanup
sudo apt-get autoremove -y
sudo apt-get clean

# Final Checklist
echo -e "${GREEN}\nSetup complete! Log file saved to $LOG_FILE${NC}"
echo -e "Run 'serve' to quickly start Laravel server."
echo -e "${YELLOW}Git: $(git config --global user.name) <$(git config --global user.email)>${NC}"
echo -e "${YELLOW}PHP: $(php -v | head -n 1)${NC}"
echo -e "${YELLOW}Node.js: $(node -v)${NC}"
echo -e "${YELLOW}Composer: $(composer --version)${NC}"
echo -e "${GREEN}Thank you for using this script ❤️ (https://github.com/oheneadjei)${NC}"


# Author credits
echo -e "\n${YELLOW}Script developed by: Ohene Adjei ❤️ (https://github.com/oheneadjei)${NC}"
echo -e "${YELLOW}Powered by: ❤️ for the PHP Developer Community${NC}"
echo -e "${GREEN}Thank you for using this setup script! ⭐️ Consider starring the repo if you found it helpful.${NC}"
