#!/bin/bash
echo "=== Debian Security Audit - $(date) ==="
echo

# System Information
echo "--- System Information ---"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo

# User Accounts
echo "--- User Accounts ---"
echo "Users with login shells:"
grep -E '/bin/(bash|sh|zsh|fish)$' /etc/passwd | cut -d: -f1
echo
echo "Users with UID 0 (root privileges):"
awk -F: '($3 == 0) {print $1}' /etc/passwd
echo
echo "Users with empty passwords (CRITICAL if any):"
sudo awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null || echo "Need sudo to check"
echo

# SSH Configuration
echo "--- SSH Security ---"
if [[ -f /etc/ssh/sshd_config ]]; then
    echo "SSH Port: $(grep -E '^Port' /etc/ssh/sshd_config || echo '22 (default)')"
    echo "Root Login: $(grep -E '^PermitRootLogin' /etc/ssh/sshd_config || echo 'not explicitly set')"
    echo "Password Auth: $(grep -E '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'not explicitly set')"
    echo "PubKey Auth: $(grep -E '^PubkeyAuthentication' /etc/ssh/sshd_config || echo 'not explicitly set')"
    echo "Protocol: $(grep -E '^Protocol' /etc/ssh/sshd_config || echo '2 (default)')"
    
    # Check for weak settings
    if grep -qE '^PermitRootLogin yes' /etc/ssh/sshd_config 2>/dev/null; then
        echo "⚠️  WARNING: Root login via SSH is enabled!"
    fi
    if grep -qE '^PermitEmptyPasswords yes' /etc/ssh/sshd_config 2>/dev/null; then
        echo "🔴 CRITICAL: Empty passwords are permitted!"
    fi
else
    echo "SSH config not found or not readable"
fi
echo

# Failed Login Attempts
echo "--- Failed Login Attempts (Last 20) ---"
sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 | awk '{print $1, $2, $3, "User:", $9, "From:", $11}' || echo "No failed attempts or insufficient permissions"
echo
echo "Failed login summary by IP:"
sudo grep "Failed password" /var/log/auth.log 2>/dev/null | awk '{print $11}' | sort | uniq -c | sort -rn | head -10 || echo "No data available"
echo

# Successful Logins
echo "--- Recent Successful Logins ---"
last -n 10 | head -10
echo

# Open Ports
echo "--- Listening Ports ---"
echo "Service                 Port    Process"
sudo ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $NF}' | sed 's/.*://' | column -t | sort -n | head -20
echo

# Firewall Status
echo "--- Firewall Status ---"
if command -v ufw &> /dev/null; then
    sudo ufw status verbose 2>/dev/null || echo "UFW installed but need sudo"
elif command -v iptables &> /dev/null; then
    echo "iptables rules count: $(sudo iptables -L 2>/dev/null | grep -c 'Chain')"
    sudo iptables -L -n --line-numbers 2>/dev/null | head -20 || echo "Need sudo to view iptables"
else
    echo "⚠️  No firewall (ufw/iptables) detected"
fi
echo

# Running Services
echo "--- Running Services (non-system) ---"
systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -v '@' | head -15
echo

# Sudo Access
echo "--- Sudo Configuration ---"
echo "Users/groups with sudo access:"
sudo grep -E '^%sudo|^%wheel|^[^#].*ALL=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v '#' || echo "Need sudo to check"
echo

# World-Writable Files (security risk)
echo "--- World-Writable Files in /etc (Security Risk) ---"
sudo find /etc -type f -perm -0002 -ls 2>/dev/null | head -10 || echo "Need sudo to check"
echo

# SUID/SGID Files (potential privilege escalation)
echo "--- SUID/SGID Files (Potential Privilege Escalation) ---"
echo "Common SUID binaries:"
find /usr/bin /usr/sbin /bin /sbin -perm -4000 -type f 2>/dev/null | head -15
echo

# Package Security
echo "--- Package Security ---"
echo "Packages that can be upgraded:"
apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l
echo
echo "Security updates available:"
apt list --upgradable 2>/dev/null | grep -i security | head -10
echo

# Check for rootkits (if rkhunter/chkrootkit installed)
echo "--- Rootkit Detection ---"
if command -v rkhunter &> /dev/null; then
    echo "rkhunter is installed (run 'sudo rkhunter --check' for full scan)"
else
    echo "rkhunter not installed (recommended: sudo apt install rkhunter)"
fi
if command -v chkrootkit &> /dev/null; then
    echo "chkrootkit is installed (run 'sudo chkrootkit' for scan)"
else
    echo "chkrootkit not installed (optional: sudo apt install chkrootkit)"
fi
echo

# File Integrity Monitoring
echo "--- File Integrity Monitoring ---"
if command -v aide &> /dev/null; then
    echo "AIDE is installed ✓"
elif command -v tripwire &> /dev/null; then
    echo "Tripwire is installed ✓"
else
    echo "⚠️  No file integrity monitoring (AIDE/Tripwire) installed"
fi
echo

# Kernel Security
echo "--- Kernel Security Features ---"
echo "ASLR (Address Space Layout Randomization):"
ASLR=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null)
case $ASLR in
    0) echo "  ⚠️  Disabled" ;;
    1) echo "  ✓ Partial" ;;
    2) echo "  ✓ Full (recommended)" ;;
    *) echo "  Unknown" ;;
esac
echo

# Check for suspicious cron jobs
echo "--- Cron Jobs ---"
echo "System cron jobs:"
sudo ls -la /etc/cron.* 2>/dev/null | grep -v total | head -10
echo
echo "User cron jobs:"
sudo crontab -l -u $(whoami) 2>/dev/null || echo "No user cron jobs"
echo

# Check /tmp security
echo "--- /tmp Security ---"
mount | grep -E '\s/tmp\s' || echo "/tmp is not on a separate partition"
mount | grep -E '\s/tmp\s' | grep -E 'noexec|nosuid' && echo "✓ /tmp has security options" || echo "⚠️  /tmp missing noexec/nosuid options"
echo

# Unattended Upgrades
echo "--- Automatic Security Updates ---"
if dpkg -l | grep -q unattended-upgrades; then
    echo "✓ unattended-upgrades is installed"
    systemctl is-active unattended-upgrades 2>/dev/null && echo "✓ Service is active" || echo "⚠️  Service is not active"
else
    echo "⚠️  unattended-upgrades not installed (recommended)"
fi
echo

# Check for suspicious network connections
echo "--- Active Network Connections ---"
echo "Established connections to remote hosts:"
sudo ss -tnp state established 2>/dev/null | grep -v '127.0.0.1' | awk '{print $4, $5, $6}' | column -t | head -10
echo

# Check listening on all interfaces (potential security issue)
echo "--- Services Listening on All Interfaces (0.0.0.0) ---"
sudo ss -tlnp | grep '0.0.0.0' | awk '{print $4, $NF}' | column -t | head -10
echo

# AppArmor/SELinux status
echo "--- Mandatory Access Control ---"
if command -v aa-status &> /dev/null; then
    sudo aa-status --enabled 2>/dev/null && echo "✓ AppArmor is enabled" || echo "⚠️  AppArmor is not enabled"
elif command -v getenforce &> /dev/null; then
    echo "SELinux: $(getenforce 2>/dev/null)"
else
    echo "⚠️  No MAC system (AppArmor/SELinux) detected"
fi
echo

# Check for core dumps (can contain sensitive info)
echo "--- Core Dumps ---"
CORE_PATTERN=$(cat /proc/sys/kernel/core_pattern 2>/dev/null)
if [[ "$CORE_PATTERN" == "|/bin/false" ]] || [[ "$CORE_PATTERN" == "" ]]; then
    echo "✓ Core dumps disabled"
else
    echo "⚠️  Core dumps enabled: $CORE_PATTERN"
fi
echo

echo "=== Security Audit Complete ==="
echo
echo "📋 Quick Recommendations:"
echo "1. Review any ⚠️  warnings and 🔴 critical issues above"
echo "2. Check failed login attempts for suspicious activity"
echo "3. Ensure SSH is properly hardened (disable root login, use keys)"
echo "4. Consider installing: rkhunter, aide, fail2ban"
echo "5. Keep system updated with automatic security updates"
echo
