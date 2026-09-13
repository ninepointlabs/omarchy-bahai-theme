#!/bin/bash
# Copy this checkout into the Omarchy user theme directory and apply it.
# Re-run after editing; `omarchy theme set` re-reads the files.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.config/omarchy/themes/bahai"

mkdir -p "$dest/backgrounds"
cp "$src/colors.toml" "$src/icons.theme" "$src/README.md" "$dest/"
cp "$src/preview.png" "$src/unlock.png" "$src/preview-unlock.png" "$dest/" 2>/dev/null || true
rm -f "$dest/backgrounds/"*.{png,jpg}
cp "$src/backgrounds/"*.{png,jpg} "$dest/backgrounds/"

echo "Installed to $dest"
if [[ "${1:-}" == "--apply" ]]; then
  omarchy theme set bahai
fi
