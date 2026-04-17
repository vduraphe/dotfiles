Push all modified dotfiles to the dotfiles repo with an inferred commit message.

## Process

1. Check what's changed:
   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status
   ```

2. Look at the diff to infer a short commit message:
   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME diff
   ```

3. Stage all modified tracked files:
   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME add -u
   ```

4. Commit with an inferred message based on what changed (short, lowercase, no period):
   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME commit -m "<inferred message>"
   ```

5. Push:
   ```bash
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME push
   ```

## Rules

- Infer the commit message from the actual changes — e.g. "update zshrc to guard macOS paths", "add ghost-write command"
- Keep the message short (under 60 chars), lowercase, no trailing period
- If there are untracked files that look like they should be added, mention them to the user but don't add them automatically
- If there's nothing to commit, say so
