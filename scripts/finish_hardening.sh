#!/bin/bash
# Complete the remaining hardening steps

echo "=== Finishing Security Hardening ==="
echo

# Step 4: Fix unattended-upgrades config
echo "--- Step 4: Configuring Automatic Updates ---"
cat > /tmp/50unattended-upgrades << 'ENDOFFILE'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
ENDOFFILE

sudo mv /tmp/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
sudo systemctl restart unattended-upgrades
echo "✓ Auto-updates configured"
echo

# Step 5: Initialize AIDE
echo "--- Step 5: Initializing AIDE ---"
echo "This takes 5-10 minutes..."
sudo aideinit
if [ -f /var/lib/aide/aide.db.new ]; then
    sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    echo "✓ AIDE database created"
fi

# Weekly AIDE check
sudo mkdir -p /var/log/aide
cat > /tmp/aide-check << 'ENDOFFILE'
#!/bin/bash
LOGFILE="/var/log/aide/aide-check-$(date +%Y%m%d).log"
/usr/bin/aide --check > "$LOGFILE" 2>&1
ENDOFFILE

sudo mv /tmp/aide-check /etc/cron.weekly/aide-check
sudo chmod +x /etc/cron.weekly/aide-check
echo "✓ Weekly AIDE checks scheduled"
echo

# Step 6: Configure rkhunter
echo "--- Step 6: Configuring rkhunter ---"
sudo rkhunter --update
sudo rkhunter --propupd

sudo mkdir -p /var/log/rkhunter
cat > /tmp/rkhunter-scan << 'ENDOFFILE'
#!/bin/bash
LOGFILE="/var/log/rkhunter/rkhunter-scan-$(date +%Y%m%d).log"
/usr/bin/rkhunter --update --skip-keypress
/usr/bin/rkhunter --check --skip-keypress --report-warnings-only > "$LOGFILE" 2>&1
ENDOFFILE

sudo mv /tmp/rkhunter-scan /etc/cron.weekly/rkhunter-scan
sudo chmod +x /etc/cron.weekly/rkhunter-scan
echo "✓ Weekly rkhunter scans scheduled"
echo

# Step 7: Disable core dumps
echo "--- Step 7: Disabling Core Dumps ---"
if ! grep -q "hard core 0" /etc/security/limits.conf; then
    echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
fi
if ! grep -q "kernel.core_pattern" /etc/sysctl.conf; then
    echo "kernel.core_pattern=|/bin/false" | sudo tee -a /etc/sysctl.conf
fi
sudo mkdir -p /etc/systemd/coredump.conf.d
echo "[Coredump]" | sudo tee /etc/systemd/coredump.conf.d/disable.conf
echo "Storage=none" | sudo tee -a /etc/systemd/coredump.conf.d/disable.conf
sudo systemctl daemon-reload
echo "✓ Core dumps disabled"
echo

# Step 8: Install & enable AppArmor
echo "--- Step 8: AppArmor ---"
sudo apt install -y apparmor apparmor-utils apparmor-profiles
sudo systemctl enable apparmor
sudo systemctl start apparmor
echo "✓ AppArmor enabled"
echo

# Step 9: Kernel hardening
echo "--- Step 9: Kernel Hardening ---"
cat > /tmp/99-security-hardening.conf << 'ENDOFFILE'
net.ipv4.ip_forward = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_rfc1337 = 1
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.unprivileged_bpf_disabled = 1
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
ENDOFFILE

sudo mv /tmp/99-security-hardening.conf /etc/sysctl.d/99-security-hardening.conf
sudo sysctl -p /etc/sysctl.d/99-security-hardening.conf
echo "✓ Kernel hardening applied"
echo

# Step 10: Secure shared memory
echo "--- Step 10: Secure Shared Memory ---"
if ! grep -q "/run/shm" /etc/fstab; then
    echo "tmpfs /run/shm tmpfs defaults,noexec,nodev,nosuid 0 0" | sudo tee -a /etc/fstab
    echo "✓ Added (applies after reboot)"
else
    echo "✓ Already configured"
fi
echo

echo "=========================================="
echo "  ✅ HARDENING COMPLETE!"
echo "=========================================="
echo
echo "🔴 CRITICAL: Test SSH NOW"
echo
echo "1. Keep THIS session open"
echo "2. From MacBook, open NEW terminal:"
echo "   ssh swine@10.54.10.20"
echo "3. Touch YubiKey when prompted"
echo "4. If successful, in THIS session:"
echo "   sudo systemctl restart ssh"
echo "5. Test new connection again"
echo "6. Close this session only after success"
echo
echo "📊 Verify Everything:"
echo "  sudo fail2ban-client status sshd"
echo "  systemctl status unattended-upgrades"
echo "  sudo aa-status"
echo "  ls -lh /var/lib/aide/aide.db"
echo

