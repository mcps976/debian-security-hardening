# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Bash-based security hardening automation for Debian 13 (Trixie) with KDE Plasma. Tailored for a homelab environment protected by OPNsense/Suricata with YubiKey-only SSH authentication and Tailscale VPN (100.64.0.0/10 network).

There is no build system, package manager, or test framework — this is a collection of bash scripts applied directly to a live system.

## Script Execution Order

The hardening workflow runs in this sequence:

1. **`scripts/debian_harden.sh`** — Main hardening script. Runs pre-flight checks (verifies `~/.ssh/authorized_keys` exists), hardens SSH, installs security tools (`fail2ban`, `rkhunter`, `aide`, `lynis`, `debsums`, etc.), and configures fail2ban/unattended-upgrades.

2. **`scripts/finish_hardening.sh`** — Completes the remaining steps: initializes the AIDE database (takes 5–10 min), configures rkhunter, disables core dumps, enables AppArmor, applies kernel hardening (`/etc/sysctl.d/99-security-hardening.conf`), and secures shared memory.

3. **`scripts/run_full_audit.sh`** — Comprehensive audit that saves timestamped reports to `~/security-audit-reports/YYYYMMDD-HHMMSS/`. Run with `sudo`. The summary is at `00-summary.txt`; individual checks are numbered `01-` through `51-`.

The other scripts (`scripts/health_check.sh`, `scripts/security_audit.sh`) are lighter-weight standalone checks that get copied to `~/bin/` on the target system.

## Running Audits

```bash
# Full automated audit (saves reports to ~/security-audit-reports/)
sudo ./scripts/run_full_audit.sh

# View summary of most recent run
cat ~/security-audit-reports/$(ls -t ~/security-audit-reports/ | head -1)/00-summary.txt

# Quick health check (if installed on target)
health-check

# Individual checks
sudo fail2ban-client status sshd
sudo aa-status
sudo aide --check
sudo rkhunter --check --skip-keypress
yes "" | sudo /usr/sbin/lynis audit system --quick
```

## Architecture

| Component | Config Location | Purpose |
|-----------|----------------|---------|
| SSH hardening | `/etc/ssh/sshd_config.d/99-yubikey-hardening.conf` | YubiKey-only auth, strong ciphers |
| fail2ban | `/etc/fail2ban/jail.local` | SSH brute-force protection, 24h bans |
| AIDE | `/var/lib/aide/aide.db` | File integrity baseline |
| rkhunter | `/var/log/rkhunter.log` | Weekly rootkit scans (cron.weekly) |
| AppArmor | system | MAC enforcement |
| Kernel params | `/etc/sysctl.d/99-security-hardening.conf` | ASLR, SYN cookies, IP forwarding off |
| Auto-updates | `/etc/apt/apt.conf.d/50unattended-upgrades` | Unattended security updates |

## Homelab Infrastructure

| Host | Hardware | OS | Role |
|------|----------|----|------|
| OPNsense router | Protectli VP2420 | OPNsense | Perimeter firewall, Suricata IDS, Unbound DNS, HAProxy |
| TrueNAS | Terramaster F4-423 | TrueNAS | NAS, SMB shares, Nextcloud, Dockge container host |
| Linux workstation | Beelink SER | Debian 13 KDE | Primary Linux workstation — **primary target of these scripts** |
| Bitcoin node | Beelink (separate) | Ubuntu | Bitcoin Core, Mempool.space, Alby Hub |
| Mac workstation | MacBook Pro M3 Pro | macOS | Primary Mac workstation |

**TrueNAS containers (via Dockge):** Sonarr, Radarr, Lidarr, Prowlarr, Jellyfin, Jellyseerr, Audiobookshelf, Homarr

**Network:** All devices on Tailscale for remote access. Mullvad VPN on all devices. No local firewall — perimeter is OPNsense.

## Git Remotes

- `origin` — GitHub (`mcps976`)
- `truenas` — Bare repos on TrueNAS at `/mnt/tank/git-repos/`

## Environment-Specific Assumptions

- **User**: `swine` (hardcoded in `AllowUsers` in SSH config)
- **Network**: Tailscale (100.64.0.0/10) and local LAN (10.54.10.0/24) are whitelisted in fail2ban
- **Shell target**: bash 5.x on Debian/Ubuntu — avoid bash 4-only syntax and non-portable constructs

## Critical Safety Rule

When modifying SSH configuration, always verify the SSH config is valid (`sudo sshd -t`) before reloading. The hardening scripts enforce this — any SSH config error causes the script to remove the bad config and exit. Never reload SSH without a verified working session as a fallback.
