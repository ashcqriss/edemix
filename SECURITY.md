# Security policy

## Reporting a vulnerability

Open a private report via GitHub Security Advisories:

  https://github.com/ashcqriss/edemint/security/advisories/new

Please don't open a public GitHub issue for security problems until a
fix is shipped.

## Threat model

Edemint defaults assume a desktop attacker who has either:

- physical access to a powered-off machine,
- network access (LAN or internet),
- or unprivileged shell access (curl-piped script, malicious Flatpak).

The defaults below are the minimum, **not** the maximum — you can
tighten further. None of them are tuned for a nation-state adversary
or for production servers.

## Security defaults

| Surface | Default | Notes |
|---|---|---|
| Firewall | nftables, default-deny inbound | `/etc/nftables.conf` |
| MAC | AppArmor enabled, Debian profiles loaded | no custom profiles yet |
| Root account | locked (`passwd -l root`) on install | Calamares finalize asserts |
| sudo | password-gated; never NOPASSWD on installed disk | live ISO is passwordless for installer convenience only |
| Disk encryption | LUKS2 by default in Calamares | flip off only with intent |
| Secure Boot | Debian's signed shim → grub → kernel chain on amd64 | N/A on Pi |
| Apt | Debian official archives signed; Edemint repo Signed-By a per-build key | private key never in repo |
| Unattended updates | enabled, Debian-security only | not auto-reboot |
| Keyring | gnome-keyring auto-unlocked at login (PAM) | AI keys live here, never on disk in plaintext |
| CUPS | listens on localhost only | sharing/printing opt-in |
| Bluetooth | non-discoverable, AutoEnable=false | pair on demand |
| DNS | DNS-over-TLS via systemd-resolved (Quad9 + Cloudflare) | per-network override in NM |
| AR udev | group-scoped (edemint-ar), mode 0660 | never world-readable |
| AI cloud calls | OFF by default; `local_only` switch forbids all cloud backends | Waybar pill turns red while a call is in flight |
| btrfs snapshots | pre/post snapshot on every apt invocation | `edemint-rollback` walks back |

## XR driver supply chain

The XR driver hook (`shared/hooks/normal/0200-xr-driver.hook.chroot`)
pins XRLinuxDriver to a tagged commit AND verifies a recorded SHA-256
before building. SHA mismatch → skip build, do not ship a tampered
binary. The placeholder SHA in the repo deliberately trips this path
until a real hash is committed.

## Reproducibility

Image builds happen in CI on `ubuntu-latest` runners. Both metapackages
are deterministic given the same `*.list.chroot` files; the rest of the
image inherits Debian's reproducibility properties.

## What we don't do

- We don't run secret/credential scanners on every push (CI is in scope
  for the publish job's signing key only).
- We don't ship an HSM-backed signing flow yet.
- We don't ship a hardened kernel variant. Use `linux-image-hardened`
  from Debian if you need one; it should drop in.
