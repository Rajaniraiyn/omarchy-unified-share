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

- Opens on Quick Share and scans for visible Android or Windows recipients.
- Keeps Browser / QR and LocalSend as explicit fallback routes instead of mixing their state into the main flow.
- Closes before the native file picker appears, then reopens as soon as selection completes.
- Streams the Quick Share confirmation code into the panel while consent is pending.
- Creates private, expiring Browser / QR links and can stop an active link early.
- Runs discovery and transfer work only on demand; the panel does not add a background sharing daemon.

## License

MIT. The separate Unified Share core is GPL-3.0-only.
