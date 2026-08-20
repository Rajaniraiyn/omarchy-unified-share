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

The development helper also discovers `~/Projects/unified-share/target/{release,debug}/unified-share`, so no system-wide install is required.

## Current behavior

- Replaces Omarchy's LocalSend-only Share actions with a native route/recipient chooser for files, folders, and clipboard text.
- Adds a Nautilus `Share…` context action while retaining LocalSend as a fallback provider.
- Shows only discovered Quick Share recipients; actions never silently run without a target.
- Stages folders as temporary ZIP files for file-only routes and passes folders directly to LocalSend.
- Keeps the shell plugin on demand as a centered device-name and private-history surface instead of a permanent bar widget.
- Runs discovery and transfers only after an explicit share action; no additional sharing daemon stays resident.

## License

MIT. The separate Unified Share core is GPL-3.0-only.
