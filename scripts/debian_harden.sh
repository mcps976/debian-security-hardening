#!/bin/bash
# Debian Security Hardening Script
# Tailored for: OPNsense-protected network + YubiKey SSH authentication

echo "=========================================="
echo "  Debian Security Hardening"
echo "  Network: Protected by OPNsense + Suricata"
echo "  SSH Auth: YubiKey-only"
echo "=========================================="
echo

# Verify we're not about to lock ourselves out
echo "--- Pre-flight Checks ---"
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "❌ ERROR: No authorized_keys file found!"
    echo "   You would be locked out after hardening SSH"
    exit 1
fi

echo "✓ Found authorized_keys with $(wc -l < ~/.ssh/authorized_keys) key(s)"
echo

# Backup critical configs
echo "--- Creating Backups ---"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d) 2>/dev/null
echo "✓ SSH config backed up"
echo

# ============================================
# 1. SSH HARDENING - YubiKey Only
# ============================================
echo "=== Step 1: SSH Hardening (YubiKey-Only) ==="

cat << 'EOF' | sudo tee /etc/ssh/sshd_config.d/99-yubikey-hardening.conf
# YubiKey-Only Authentication - NO PASSWORDS
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# Only public key authentication
PubkeyAuthentication yes
AuthenticationMethods publickey

# Disable PAM to prevent password prompts
UsePAM no

# Access control
PermitRootLogin no
AllowUsers swine

# Connection limits
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 30

# Keepalive settings
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable unnecessary features
X11Forwarding no
PrintMotd no
PermitTunnel no
AllowAgentForwarding yes
AllowTcpForwarding yes

# Strong cryptography only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
EOF

# Test SSH config
if sudo sshd -t 2>/dev/null; then
    echo "✓ SSH configuration valid"
else
    echo "❌ SSH config has errors - removing hardening config"
    sudo rm /etc/ssh/sshd_config.d/99-yubikey-hardening.conf
    exit 1
fi
echo

# ============================================
# 2. INSTALL SECURITY TOOLS
# ============================================
echo "=== Step 2: Installing Security Tools ==="

sudo apt update
sudo apt install -y \
    fail2ban \
    rkhunter \
    aide \
    aide-common \
    unattended-upgrades \
    apt-listchanges \
    needrestart \
    debsums \
    lynis \
    libpam-tmpdir \
    apt-show-versions

echo "✓ Security tools installed"
echo

# ============================================
# 3. FAIL2BAN - Intrusion Prevention
# ============================================
echo "=== Step 3: Configuring fail2ban ==="

cat << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
# Ban settings
bantime = 1h
findtime = 10m
maxretry = 5

# Don't ban local networks or Tailscale
ignoreip = 127.0.0.1/8 10.54.10.0/24 100.64.0.0/10

# Logging
logtarget = /var/log/fail2ban.log

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
findtime = 15m

# Additional protection against SSH attacks
[sshd-ddos]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 6
findtime = 60
bantime = 10m
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo "✓ fail2ban configured and running"
echo

# ============================================
# 4. AUTOMATIC SECURITY UPDATES
# ============================================
echo "=== Step 4: Configuring Automatic Security Updates ==="

cat << 'EOF' | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
// Automatically upgrade packages from these origins
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};

// List of packages to not update
Unattended-Upgrade::Package-Blacklist {
};

// Automatically fix interrupted dpkg
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Minimal steps for upgrade
Unattended-Upgrade::MinimalSteps "true";

// Remove unused kernel packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatic reboot (disabled by default - enable if desired)
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Email notifications (configure if desired)
//
