#!/usr/bin/env bash
# Re-render the workshop site and publish it to the website repo.
#
# Two-repo setup:
#   - THIS repo (DMgtAsia_Spatial_Module) = the clone-and-run R Project (source + data).
#   - docs/ is its own git repo pointing at DMgtAsia_Spatial_Module_site (GitHub Pages).
#
# Usage:  ./publish.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "→ Rendering site (freeze: auto — only changed chunks re-run)…"
quarto render

cd docs
touch .nojekyll                      # keep Pages from stripping _files/ dirs
git add -A
if git diff --cached --quiet; then
  echo "→ No site changes to publish."
else
  git commit -m "Update site $(date +%Y-%m-%d)"
  git push origin main
  echo "→ Published. Live at https://drarunmitra.github.io/DMgtAsia_Spatial_Module_site/"
fi
