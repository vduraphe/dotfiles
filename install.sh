#!/bin/bash
echo "Starting install.sh..."

echo "Updating dotfiles..."
function config {
  git --git-dir="${HOME}"/.dotfiles/ --work-tree="${HOME}" $@
}
config config status.showUntrackedFiles no
config checkout main .

# Restore tokenized push URL for ~/.dotfiles from ~/.git-credentials so
# `config push` works without going through the figma git credential helper
# (which only has Figma-org GitHub permissions). The credential file lives
# in persistent home storage, so this self-heals every workspace start as
# long as the PAT entry is present.
if [ -r "${HOME}/.git-credentials" ]; then
  pat_line=$(grep '^https://vduraphe:.*@github.com$' "${HOME}/.git-credentials" | head -1)
  if [ -n "${pat_line}" ]; then
    config remote set-url --push origin "${pat_line%@*}@github.com/vduraphe/dotfiles.git"
  fi
fi

echo "Setting up cockpit..."
COCKPIT_DIR="${HOME}/cockpit"
if [[ -d "${COCKPIT_DIR}/.git" ]]; then
  git -C "${COCKPIT_DIR}" pull
else
  git clone git@github.com:vaidehi-figma/cockpit.git "${COCKPIT_DIR}"
fi

echo "Installing packages..."
# Install whichever packages you'd like here
# It's useful to check if they're already installed first, since this script will run every time the container starts, not just when it's created

# beads (bd) — git-backed issue tracker used by /investigate and /implement.
# Installs to ~/.local/bin; skip if already present.
if ! command -v bd >/dev/null 2>&1; then
  echo "Installing beads (bd)..."
  curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
fi
