# Raspberry Pi first boot

Edemint Raspberry Pi images do not ship a default username or password.
`greetd` and SSH are gated by `edemint-firstboot-provision.service` until an
owner account has been created.

## Local setup

Connect a display and keyboard. On the first boot, tty1 asks for a lowercase
username and password. The graphical login starts only after setup succeeds.
SSH remains disabled.

## Headless setup

Before first boot, place `edemint-firstboot.conf` in the FAT firmware partition.
The file is parsed as data; it is never executed or sourced.

```ini
USERNAME=alice
PASSWORD_HASH=$y$j9T$replace-with-a-real-yescrypt-hash
SSH_PUBLIC_KEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... alice@example
ENABLE_SSH=1
HOSTNAME=edemint-pi
TIMEZONE=Europe/Berlin
LOCALE=de_DE.UTF-8
KEYMAP=de
```

Generate a yescrypt password hash on a trusted Linux machine with
`mkpasswd --method=yescrypt`. Do not put a plaintext password in the file.
For an SSH-only account, omit `PASSWORD_HASH`; the local password remains
locked. `ENABLE_SSH=1` is accepted only when `SSH_PUBLIC_KEY` is present.

After successful provisioning, Edemint removes the preseed from the firmware
partition, locks root, and records `/var/lib/edemint/provisioned`. Because FAT
storage cannot guarantee secure erasure, do not reuse or distribute media that
contained a sensitive password hash without reformatting it first.
