#!/bin/bash
echo "Starting install.sh..."

echo "Updating dotfiles..."
function config {
  git --git-dir="${HOME}"/.dotfiles/ --work-tree="${HOME}" $@
}
config config status.showUntrackedFiles no
config checkout main .

echo "Installing packages..."
# Install whichever packages you'd like here
# It's useful to check if they're already installed first, since this script will run every time the container starts, not just when it's created
