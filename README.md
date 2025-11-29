# Debian Security Hardening Stack

Comprehensive security hardening automation for Debian 13 (Trixie) with KDE Plasma. Production-ready security configuration for homelabs and servers.

## 🔒 Features

### System Hardening
- **SSH Security** - YubiKey-only authentication, hardened configuration
- **fail2ban** - Automated intrusion prevention and IP banning
- **AIDE** - File integrity monitoring with weekly scans
- **rkhunter** - Rootkit detection with automated checks
- **AppArmor** - Mandatory access control enforcement
- **Kernel Hardening** - Sysctl security parameters
- **Core Dump Prevention** - Disabled system-wide

### Security Monitoring
- **Automated Security Updates** - Unattended-upgrades
- **Weekly Security Audits** - Comprehensive health checks
- **System Health Monitoring** - Real-time security status

### Network Security
- **Hardened SSH** - Strong ciphers, key-based auth only
- **Secure Defaults** - Disabled unnecessary services
- **fail2ban Protection** - SSH and custom rule support

## 🚀 Quick Start

### Prerequisites
- Debian 13 (Trixie) or compatible
- Sudo privileges
- YubiKey (for SSH authentication)
- 500MB free disk space

### Installation
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/debian-security-hardening.git
cd debian-security-hardening

# Review the hardening script
cat scripts/debian_harden.sh

# Run the installation (REVIEW FIRST!)
chmod +x scripts/debian_harden.sh
./scripts/debian_harden.sh
```

### Post-Installation

**CRITICAL: Test SSH before closing your session!**

1. Keep your current SSH session open
2. Open a NEW terminal and test:
```bash
   ssh your-debian-server
   # Touch YubiKey when prompted
```
3. If successful, restart SSH:
```bash
   sudo systemctl restart ssh
```
4. Test again in new session
5. Only close original session after verification

## 📋 Available Commands

After installation, these aliases are available:

| Command | Description |
|---------|-------------|
| `health-check` | Complete system security audit |
| `security-audit` | Detailed security analysis |
| `sys-update` | Update system packages |
| `scan-rootkit` | Run rkhunter scan |
| `check-aide` | AIDE integrity check |
| `check-fail2ban` | View fail2ban status |
| `check-apparmor` | AppArmor profile status |
| `view-bans` | Show banned IPs |

## 🛡️ Security Features

### SSH Hardening
- YubiKey-only authentication (no passwords)
- Strong cryptography (ChaCha20, AES-256-GCM)
- Root login disabled
- PAM enabled for session management
- Max auth tries: 3

### fail2ban Configuration
- SSH protection: 3 attempts, 24h ban
- SSH-DDOS protection: 6 attempts, 10m ban
- Ignored networks: localhost, Tailscale (100.64.0.0/10)

### AIDE (File Integrity)
- Weekly automated checks
- Logs: `/var/log/aide/`

### Kernel Hardening
- TCP SYN cookies enabled
- IP forwarding disabled
- ASLR fully enabled
- Protected symlinks/hardlinks

### AppArmor
- 189+ profiles loaded
- 65+ profiles in enforce mode

## 📁 Project Structure
```
debian-security-hardening/
├── scripts/
│   ├── debian_harden.sh         # Main hardening script
│   ├── health_check.sh          # System health audit
│   ├── security_audit.sh        # Detailed security scan
│   └── finish_hardening.sh      # Post-AIDE completion
├── docs/
│   ├── SETUP.md                 # Detailed setup guide
│   ├── SSH_YUBIKEY.md          # YubiKey SSH configuration
│   └── TROUBLESHOOTING.md       # Common issues
├── config/
│   ├── ssh_hardening.conf       # SSH configuration
│   ├── fail2ban_jail.local      # fail2ban rules
│   └── sysctl_hardening.conf    # Kernel parameters
└── README.md                    # This file
```

## 🆚 Comparison to Default Debian

| Feature | Default Debian | This Stack |
|---------|---------------|-----------|
| **SSH Auth** | Password | YubiKey only |
| **Intrusion Prevention** | None | fail2ban |
| **File Integrity** | None | AIDE |
| **Rootkit Detection** | None | rkhunter |
| **MAC System** | None | AppArmor |
| **Kernel Hardening** | Minimal | Comprehensive |
| **Auto Updates** | Manual | Automated |
| **Cost** | Free | Free |

## 📝 License

MIT License - See LICENSE file for details.

## 🙏 Acknowledgments

- [Debian Security Team](https://www.debian.org/security/)
- [AIDE](https://aide.github.io/)
- [fail2ban](https://www.fail2ban.org/)
- [rkhunter](http://rkhunter.sourceforge.net/)
- [AppArmor](https://apparmor.net/)

---

**Built for secure homelabs and production Debian servers** 🔒
