# Omarchy Unified Share

A native Omarchy shell panel for [Unified Share](https://github.com/Rajaniraiyn/unified-share).

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

- Shows every adapter and its honest readiness state.
- Uses the currently ready LocalSend migration adapter for files, folders, and clipboard text.
- Refreshes on panel open and with `R` or the refresh control.
- Will gain live discovery and transfer progress after the core exposes its local event socket.

## License

MIT. The separate Unified Share core is GPL-3.0-only.

