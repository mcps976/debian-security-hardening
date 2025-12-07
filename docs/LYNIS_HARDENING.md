# Lynis Hardening Implementation

This document describes the additional hardening steps implemented based on Lynis recommendations.

## Implemented Hardening

### 1. auditd - System Auditing
**Package:** `auditd` and `audispd-plugins`

**Installation:**
```bash
sudo apt install auditd audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd
```

**Configuration:** `/etc/audit/rules.d/audit.rules`

**Monitors:**
- Time changes
- User/group modifications
- Network configuration changes
- SSH configuration changes
- Sudo usage
- Login/logout events
- Privileged command execution
- File deletions

**Verify:**
```bash
sudo auditctl -l
sudo systemctl status auditd
```

### 2. Process Accounting (acct)
**Package:** `acct`

**Installation:**
```bash
sudo apt install acct
sudo systemctl enable acct
sudo systemctl start acct
```

**Usage:**
```bash
# View accounting summary
sudo sa

# View last commands
sudo lastcomm | head -20

# View commands by user
sudo lastcomm username
```

### 3. System Statistics (sysstat)
**Package:** `sysstat`

**Installation:**
```bash
sudo apt install sysstat
```

**Configuration:** `/etc/default/sysstat`
- Set `ENABLED="true"`

**Enable:**
```bash
sudo systemctl enable sysstat
sudo systemctl start sysstat
```

### 4. Additional Kernel Hardening

**File:** `/etc/sysctl.d/99-security-hardening.conf`

**Additional parameters added:**
- SYN flood protection (enhanced)
- Source routing disabled (IPv4 + IPv6)
- ICMP redirect protection (IPv6)
- Broadcast protection
- TCP timeout optimization
- File descriptor limits

**Apply:**
```bash
sudo sysctl -p /etc/sysctl.d/99-security-hardening.conf
```

## Results

**Lynis Score Improvement:**
- Before: 70/100
- After: 75-78/100

**Not Implemented:**
- Legal banners (`/etc/issue`, `/etc/issue.net`) - Not required for homelab use
