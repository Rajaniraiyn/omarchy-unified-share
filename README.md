# Omarchy Unified Share

A native Omarchy Share provider and optional history/settings panel for [Unified Share](https://github.com/Rajaniraiyn/unified-share).

The plugin is intentionally thin. It uses Omarchy's file picker and shell UI components, reads the core's versioned JSON status, and launches sharing actions on demand. It does not run a second discovery daemon or implement network protocols in QML.

## Install

Build the core first:

```bash
git clone https://github.com/Rajaniraiyn/unified-share ~/Projects/unified-share
cargo build --release --manifest-path ~/Projects/unified-share/Cargo.toml
```

Then install this plugin through Omarchy:

```bash
omarchy plugin add https://github.com/Rajaniraiyn/omarchy-unified-share.git --enable
```

The native `Super+Ctrl+S` integration currently uses Omarchy's single user menu-extension file. Merge the entries from `integrations/omarchy-menu.jsonc` into `~/.config/omarchy/extensions/omarchy-menu.jsonc`; they keep the stock keybinding and replace only the Share submenu rows.

The development helper also discovers `~/Projects/unified-share/target/{release,debug}/unified-share`, so no system-wide install is required.

## Current behavior

- Replaces Omarchy's LocalSend-only Share actions with a native route/recipient chooser for files, folders, and clipboard text.
- Adds a Nautilus `Share…` context action while retaining LocalSend as a fallback provider.
- Opens the sharing-method chooser immediately; Quick Share discovery runs only after selecting **Quick Share device** and shows explicit scanning, retry, and back states.
- Generates a scannable QR notification and copies the same private link for iPhone, Android, macOS, Windows, and Linux browsers on the same Wi-Fi. This route does not depend on Quick Share contact or visibility settings.
- Keeps LocalSend as a clearly labelled compatibility fallback when a native recipient is unavailable.
- Stages folders as temporary ZIP files for file-only routes and passes folders directly to LocalSend.
- Keeps the shell plugin on demand as a centered device-name and private-history surface instead of a permanent bar widget.
- Runs discovery and transfers only after an explicit share action; no additional sharing daemon stays resident.

## Preferences

Open **Share → Sharing preferences** from Omarchy's `Super+Ctrl+S` menu to change:

- the computer name advertised to nearby devices;
- Quick Share scan time (3, 5, or 8 seconds);
- private QR/link lifetime (10, 30, or 60 minutes).

The Omarchy-specific timing preferences live in `~/.config/omarchy/unified-share.json`. Protocol-independent identity remains owned by the core in `~/.config/unified-share/settings.json`.

## License

MIT. The separate Unified Share core is GPL-3.0-only.
