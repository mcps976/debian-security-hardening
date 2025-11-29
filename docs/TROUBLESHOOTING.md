# Troubleshooting Guide

## SSH Issues

### Cannot SSH after hardening

1. Access via console
2. Check: `sudo systemctl status ssh`
3. Check config: `sudo sshd -t`
4. Review: `sudo journalctl -u ssh -n 50`

### YubiKey not working

1. Verify YubiKey inserted
2. Check: `ssh-add -L`
3. Test locally first

## AIDE Issues

### AIDE taking too long

AIDE initialization takes 10-20 minutes on first run. This is normal.

### AIDE database missing

Run: `sudo aideinit`

## fail2ban Issues

### Too many bans

Adjust `/etc/fail2ban/jail.local` maxretry values
