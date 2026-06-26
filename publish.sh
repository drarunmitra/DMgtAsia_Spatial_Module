#!/usr/bin/env bash
# Re-render the workshop site and publish it to the website repo.
#
# Two-repo setup:
#   - THIS repo (DMgtAsia_Spatial_Module) = clone-and-run R Project (source + data).
#   - The rendered site is force-pushed to DMgtAsia_Spatial_Module_site (GitHub Pages).
#
# NOTE: `quarto render` cleans docs/ on each run (removing any .git inside it), so we
# re-init a fresh single-commit tree in docs/ and force-push it. History stays small;
# the site is a generated artifact, so squashing each publish is intentional.
#
# Usage:  ./publish.sh
set -euo pipefail
cd "$(dirname "$0")"

SITE_REMOTE="https://github.com/drarunmitra/DMgtAsia_Spatial_Module_site.git"

echo "→ Rendering (freeze: auto — only changed chunks re-run)…"
quarto render

cd docs
touch .nojekyll                       # stop Pages stripping _files/ dirs
rm -rf .git
git init -q
git checkout -q -b main
git add -A
git -c user.name="Arun Mitra" -c user.email="dr.arunmitra@gmail.com" \
    commit -q -m "Publish site $(date +%Y-%m-%d)"
git push -q -f "$SITE_REMOTE" main
echo "→ Published → https://drarunmitra.github.io/DMgtAsia_Spatial_Module_site/"
