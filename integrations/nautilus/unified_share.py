import os

from gi import require_version

require_version("Nautilus", "4.1")

from gi.repository import GObject, Gio, Nautilus


class UnifiedShareAction(GObject.GObject, Nautilus.MenuProvider):
    def _helper(self):
        candidates = [
            os.path.expanduser(
                "~/.config/omarchy/plugins/rajaniraiyn.unified-share/bin/omarchy-unified-share"
            ),
            os.path.expanduser("~/Projects/omarchy-unified-share/bin/omarchy-unified-share"),
        ]
        return next((path for path in candidates if os.access(path, os.X_OK)), None)

    def _selected_paths(self, files):
        paths = []
        for selected in files:
            location = selected.get_location()
            path = location.get_path() if location else None
            if path and path not in paths:
                paths.append(path)
        return paths

    def _on_activate(self, _menu, paths):
        helper = self._helper()
        if helper:
            Gio.Subprocess.new(
                [helper, "share", "file", *paths], Gio.SubprocessFlags.NONE
            )

    def get_file_items(self, *args):
        files = args[0] if len(args) == 1 else args[1]
        paths = self._selected_paths(files)
        if not paths or not self._helper():
            return []
        label = "Share…" if len(paths) == 1 else "Share selected…"
        item = Nautilus.MenuItem(
            name="UnifiedShareNautilus::share",
            label=label,
            icon="folder-publicshare",
        )
        item.connect("activate", self._on_activate, paths)
        return [item]
