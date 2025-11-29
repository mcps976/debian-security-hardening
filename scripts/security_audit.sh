#!/bin/bash
# Debian Security Audit Script

echo "=== Comprehensive Security Audit ==="
echo "Date: $(date)"
echo

# System Info
echo "--- System Information ---"
uname -a
echo

# Security Updates
echo "--- Security Updates Available ---"
sudo apt list --upgradable 2>/dev/null | grep -i security || echo "No security updates pending"
echo

# SSH Configuration
echo "--- SSH Security Check ---"
echo "SSH Config: /etc/ssh/sshd_config.d/99-yubikey-hardening.conf"
if [ -f /etc/ssh/sshd_config.d/99-yubikey-hardening.conf ]; then
    grep -E "PasswordAuthentication|PubkeyAuthentication|PermitRootLogin" /etc/ssh/sshd_config.d/99-yubikey-hardening.conf
else
    echo "⚠ SSH hardening config not found"
fi
echo

# fail2ban Status
echo "--- fail2ban Status ---"
sudo fail2ban-client status
echo

# AIDE Status
echo "--- AIDE File Integrity ---"
if [ -f /var/lib/aide/aide.db ]; then
    ls -lh /var/lib/aide/aide.db
else
    echo "⚠ AIDE database not initialized"
fi
echo

# AppArmor Status
echo "--- AppArmor Status ---"
sudo aa-status 2>/dev/null | head -20 || echo "⚠ AppArmor not running"
echo

# Kernel Security
echo "--- Kernel Security Parameters ---"
echo "TCP SYN Cookies: $(sysctl -n net.ipv4.tcp_syncookies)"
echo "ASLR: $(sysctl -n kernel.randomize_va_space)"
echo "IP Forwarding: $(sysctl -n net.ipv4.ip_forward)"
echo

# Running Services
echo "--- Security-Related Services ---"
systemctl status fail2ban --no-pager | head -5
systemctl status ssh --no-pager | head -5
echo

# Open Ports
echo "--- Listening Ports ---"
sudo ss -tlnp | grep LISTEN
echo

# Recent Logins
echo "--- Recent Logins ---"
last -n 10
echo

echo "=== Audit Complete ==="
