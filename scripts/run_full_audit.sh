#!/bin/bash
# Debian Complete Security Audit Script
# Runs all security checks and saves results

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create report directory in the calling user's home

if [ -n "$SUDO_USER" ]; then
    REPORT_DIR="/home/$SUDO_USER/security-audit-reports/$(date +%Y%m%d-%H%M%S)"
else
    REPORT_DIR="$HOME/security-audit-reports/$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$REPORT_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Debian Complete Security Audit${NC}"
echo -e "${GREEN}  $(date)${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo "Report will be saved to: $REPORT_DIR"
echo

# Function to run command and save output
run_check() {
    local name="$1"
    local command="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Running: $name${NC}"
    eval "$command" > "$REPORT_DIR/$output_file" 2>&1
    echo -e "${GREEN}✓ Saved to $output_file${NC}"
    echo
}

# ============================================
# SYSTEM INFORMATION
# ============================================

echo "=== System Information ===" | tee "$REPORT_DIR/00-summary.txt"

run_check "System Info" "uname -a && echo && cat /etc/debian_version && echo && uptime" "01-system-info.txt"
run_check "Disk Space" "df -h" "02-disk-space.txt"
run_check "Memory Usage" "free -h" "03-memory-usage.txt"

# ============================================
# SECURITY UPDATES
# ============================================

echo "=== Security Updates ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Available Updates" "sudo apt update && sudo apt list --upgradable" "04-updates.txt"
run_check "Security Updates" "sudo apt list --upgradable 2>/dev/null | grep -i security" "05-security-updates.txt"

# ============================================
# SSH SECURITY
# ============================================

echo "=== SSH Security ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "SSH Status" "sudo systemctl status ssh" "06-ssh-status.txt"
run_check "SSH Config Test" "sudo sshd -t" "07-ssh-config-test.txt"
run_check "SSH Hardening Config" "cat /etc/ssh/sshd_config.d/99-yubikey-hardening.conf" "08-ssh-hardening.txt"
run_check "Recent SSH Logins" "last -n 20" "09-recent-logins.txt"
run_check "Failed Logins" "sudo lastb -n 20" "10-failed-logins.txt"

# ============================================
# FAIL2BAN
# ============================================

echo "=== fail2ban ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "fail2ban Status" "sudo systemctl status fail2ban" "11-fail2ban-status.txt"
run_check "fail2ban Client Status" "sudo fail2ban-client status" "12-fail2ban-client.txt"
run_check "SSH Jail Status" "sudo fail2ban-client status sshd" "13-ssh-jail.txt"
run_check "fail2ban Logs" "sudo tail -100 /var/log/fail2ban.log" "14-fail2ban-logs.txt"

# ============================================
# AIDE FILE INTEGRITY
# ============================================

echo "=== AIDE File Integrity ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "AIDE Database Info" "ls -lh /var/lib/aide/aide.db" "15-aide-database.txt"
run_check "AIDE Logs" "ls -la /var/log/aide/" "16-aide-logs.txt"

echo -e "${YELLOW}Running AIDE check (this may take a few minutes)...${NC}"
sudo aide --check > "$REPORT_DIR/17-aide-check.txt" 2>&1 || echo "AIDE check completed with warnings (exit code $?)" >> "$REPORT_DIR/17-aide-check.txt"
echo -e "${GREEN}✓ AIDE check complete${NC}"
echo

# ============================================
# RKHUNTER
# ============================================

echo "=== rkhunter ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "rkhunter Update" "sudo rkhunter --update" "18-rkhunter-update.txt"

echo -e "${YELLOW}Running rkhunter scan (this may take a few minutes)...${NC}"
yes "" | sudo rkhunter --check --skip-keypress --report-warnings-only > "$REPORT_DIR/19-rkhunter-scan.txt" 2>&1
echo -e "${GREEN}✓ rkhunter scan complete${NC}"
echo

# ============================================
# APPARMOR
# ============================================

echo "=== AppArmor ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "AppArmor Status" "sudo aa-status" "20-apparmor-status.txt"
run_check "AppArmor Denials" "sudo journalctl -xe | grep -i apparmor | tail -50" "21-apparmor-denials.txt"

# ============================================
# LYNIS SECURITY AUDIT
# ============================================

echo "=== Lynis Security Audit ===" | tee -a "$REPORT_DIR/00-summary.txt"

echo -e "${YELLOW}Running Lynis audit (this may take a few minutes)...${NC}"
yes "" | sudo /usr/sbin/lynis audit system --quick --no-colors > "$REPORT_DIR/22-lynis-audit.txt" 2>&1
echo -e "${GREEN}✓ Lynis audit complete${NC}"
echo

# ============================================
# KERNEL SECURITY
# ============================================

echo "=== Kernel Security ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Kernel Parameters" "sysctl -a | grep -E 'tcp_syncookies|randomize_va_space|ip_forward|accept_redirects|log_martians'" "23-kernel-params.txt"
run_check "Core Dumps" "ulimit -c && echo && cat /etc/systemd/coredump.conf.d/disable.conf && echo && sysctl kernel.core_pattern" "24-core-dumps.txt"

# ============================================
# NETWORK SECURITY
# ============================================

echo "=== Network Security ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Listening Ports" "sudo ss -tlnp" "25-listening-ports.txt"
run_check "Established Connections" "sudo ss -tnp | grep ESTAB" "26-connections.txt"
run_check "Routing Table" "ip route" "27-routing.txt"
run_check "ARP Table" "arp -a" "28-arp-table.txt"

# ============================================
# SERVICES
# ============================================

echo "=== Running Services ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "All Running Services" "systemctl list-units --type=service --state=running" "29-services.txt"
run_check "Security Services" "systemctl status fail2ban ssh unattended-upgrades --no-pager" "30-security-services.txt"

# ============================================
# USER ACCOUNTS
# ============================================

echo "=== User Accounts ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Users with Login" "cat /etc/passwd | grep -v 'nologin\|false'" "31-login-users.txt"
run_check "UID 0 Users" "awk -F: '\$3 == 0 {print \$1}' /etc/passwd" "32-root-users.txt"
run_check "Sudo Access" "sudo grep -E '^[^#]' /etc/sudoers && sudo grep -E '^[^#]' /etc/sudoers.d/* 2>/dev/null" "33-sudo-users.txt"

# ============================================
# FILE PERMISSIONS
# ============================================

echo "=== File Permissions ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "SUID Files" "sudo find / -perm -4000 -type f 2>/dev/null | head -30" "34-suid-files.txt"
run_check "World Writable in /etc" "sudo find /etc -type f -perm -002 2>/dev/null" "35-world-writable.txt"

# ============================================
# PACKAGE SECURITY
# ============================================

echo "=== Package Security ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Package Integrity" "timeout 60 sudo debsums -c 2>&1 | head -50 || echo 'Debsums check completed (or timed out)'" "36-package-integrity.txt"
run_check "Unattended Upgrades" "sudo systemctl status unattended-upgrades" "37-auto-updates.txt"

# ============================================
# LOGS
# ============================================

echo "=== System Logs ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Auth Failures" "sudo grep -i 'failed' /var/log/auth.log | tail -50" "38-auth-failures.txt"
run_check "Sudo Usage" "sudo grep 'sudo:' /var/log/auth.log | tail -50" "39-sudo-usage.txt"
run_check "System Errors" "sudo journalctl -p err -n 100 --no-pager" "40-system-errors.txt"

# ============================================
# APPLICATION CLEANUP
# ============================================

echo "=== Application Cleanup ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Orphaned Packages" "sudo apt autoremove --dry-run" "45-orphaned-packages.txt"
run_check "Old Config Files" "dpkg -l | grep '^rc'" "46-old-configs.txt"
run_check "Large Old Files" "find ~/ -type f -size +100M -mtime +180 2>/dev/null | head -20" "47-large-old-files.txt"
run_check "Package Cache Size" "du -sh /var/cache/apt/archives/" "48-package-cache.txt"

# ============================================
# VPN STATUS
# ============================================

echo "=== VPN Status ===" | tee -a "$REPORT_DIR/00-summary.txt"

run_check "Tailscale" "tailscale status 2>&1" "49-tailscale.txt"
run_check "Mullvad" "mullvad status 2>&1" "50-mullvad.txt"

# ============================================
# CUSTOM HEALTH CHECKS
# ============================================

echo "=== Custom Health Checks ===" | tee -a "$REPORT_DIR/00-summary.txt"

if [ -f ~/bin/health_check.sh ]; then
    run_check "Health Check Script" "~/bin/health_check.sh" "51-health-check.txt"
fi

if [ -f ~/bin/security_audit.sh ]; then
    run_check "Security Audit Script" "~/bin/security_audit.sh" "52-security-audit.txt"
fi

# ============================================
# CREATE SUMMARY
# ============================================

echo | tee -a "$REPORT_DIR/00-summary.txt"
echo "=== Audit Summary ===" | tee -a "$REPORT_DIR/00-summary.txt"
echo "Date: $(date)" | tee -a "$REPORT_DIR/00-summary.txt"
echo "Hostname: $(hostname)" | tee -a "$REPORT_DIR/00-summary.txt"
echo "Report Directory: $REPORT_DIR" | tee -a "$REPORT_DIR/00-summary.txt"
echo | tee -a "$REPORT_DIR/00-summary.txt"

# Quick summary of critical items
echo "=== Critical Security Items ===" | tee -a "$REPORT_DIR/00-summary.txt"
echo -n "fail2ban Status: " | tee -a "$REPORT_DIR/00-summary.txt"
systemctl is-active fail2ban | tee -a "$REPORT_DIR/00-summary.txt"

echo -n "SSH Status: " | tee -a "$REPORT_DIR/00-summary.txt"
systemctl is-active ssh | tee -a "$REPORT_DIR/00-summary.txt"

echo -n "AppArmor Profiles Loaded: " | tee -a "$REPORT_DIR/00-summary.txt"
sudo aa-status 2>/dev/null | grep "profiles are loaded" | tee -a "$REPORT_DIR/00-summary.txt"

echo -n "Security Updates Available: " | tee -a "$REPORT_DIR/00-summary.txt"
sudo apt list --upgradable 2>/dev/null | grep -c -i security | tee -a "$REPORT_DIR/00-summary.txt"

echo -n "Currently Banned IPs: " | tee -a "$REPORT_DIR/00-summary.txt"
sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' | tee -a "$REPORT_DIR/00-summary.txt"

# ============================================
# COMPLETION
# ============================================

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Audit Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo "Full report saved to: $REPORT_DIR"
echo
echo "Quick access:"
echo "  Summary:     cat $REPORT_DIR/00-summary.txt"
echo "  All reports: ls -la $REPORT_DIR"
echo
echo "To view all reports:"
echo "  cd $REPORT_DIR && ls -la"
echo
