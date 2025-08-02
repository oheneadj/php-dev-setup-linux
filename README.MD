# PHP Development Environment Setup Scripts for Linux & WSL

## Overview
This repository provides **interactive bash scripts** to set up a complete PHP development environment on:

- **Linux** (Ubuntu/Debian-based distros)
- **Windows Subsystem for Linux (WSL 1/2)**

### Features
- ✅ Install **PHP** (version selectable: 8.1 - 8.4)
- ✅ Install **Node.js** (via LTS, specific version, or nvm)
- ✅ Install **Composer**, **Laravel Installer**, and **Valet for Linux**
- ✅ Web servers: **Nginx**, **Apache**, or both
- ✅ Databases: **MariaDB**, **PostgreSQL**, **MongoDB**
- ✅ Optional tools: **Xdebug**, **Redis**, **Docker**, **ZSH**, **UFW Firewall**
- ✅ GUI tools: **pgAdmin**, **phpMyAdmin**, **MongoDB Compass**, **DBeaver**, **VS Code**, **Postman/Insomnia**
- ✅ Auto configures **Git** & SSH for GitHub
- ✅ Adds useful **command aliases**
- ✅ Creates detailed **log file** for troubleshooting

## 📁 Scripts Included
| Script              | Target Platform      | Description                                   |
|--------------------|----------------------|-----------------------------------------------|
| `setup.sh`         | Linux (Ubuntu/Debian)| Full setup script for Linux                   |
| `setup-wsl.sh`     | Windows WSL 1/2      | Adapted setup script for WSL + Windows notes  |

---

## ⚙️ Usage Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/oheneadjei/php-dev-setup.git
cd php-dev-setup
```

### 2. Make Scripts Executable
```bash
chmod +x setup.sh setup-wsl.sh
```

### 3. Run the Script
- **Linux:**
```bash
./setup.sh
```
- **WSL (Windows Subsystem for Linux):**
```bash
./setup-wsl.sh
```

---

## 🖥️ WSL Notes
- GUI tools like **phpMyAdmin**, **pgAdmin**, or **Compass** may have limited support.
- **Recommended:** Install these GUI apps on Windows:
  - [MySQL Workbench](https://dev.mysql.com/downloads/workbench/)
  - [pgAdmin](https://www.pgadmin.org/download/pgadmin-4-windows/)
  - [MongoDB Compass](https://www.mongodb.com/try/download/compass)

> Snap is often **unsupported** on WSL. The script detects this and offers alternatives.

---

## 🚀 Aliases for Productivity
Default aliases added (can be customized during setup):
```bash
alias serve="php artisan serve"
alias art="php artisan"
alias nginx-restart="sudo systemctl restart nginx"
alias mongo-start="sudo systemctl start mongod"
start_project() {
  cd ~/Projects/"$1" && valet link && php artisan serve
}
```
📢 Run `serve` to quickly start a Laravel server.

---

## 📜 License
MIT License - See [LICENSE](LICENSE)

## 👤 Author
**Ohene Adjei**  
[https://ohene.dev](https://ohene.dev)  
GitHub: [@oheneadj](https://github.com/oheneadj)

> 💡 Contributions, suggestions, and PRs are welcome!

---

## 📋 Final Setup Checklist (Sample)
- Git: `John Doe <john@example.com>`
- PHP: `PHP 8.4.1 (cli)`
- Node.js: `v18.17.0`
- Composer: `2.7.x`
- Web Server: `Nginx`
- Database: `PostgreSQL`
- Laravel Installer: Installed
- Docker: Installed
- Redis: Enabled
- Aliases: Added to `.bashrc` or `.zshrc`
- Log File: `~/php-dev-setup-YYYYMMDD_HHMMSS.log`

---

## 🧪 Test & Feedback
Tested on:
- Ubuntu 22.04 LTS
- Debian 11
- WSL 2 (Ubuntu on Windows 10/11)

Please open an issue for bugs or environment-specific improvements.

---

## 📂 File Structure Example
```
php-dev-setup/
├── setup.sh
├── setup-wsl.sh
├── alias-sample.sh
├── LICENSE
└── README.md
