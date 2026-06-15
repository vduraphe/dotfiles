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

6. Close the tracking task (if any): this is a utility chore, so do not create a Beads task. If a `bd` task id was passed in `$ARGUMENTS` (e.g. you ran `/dotfiles-push bd-1234`), close it after the push succeeds:
   ```bash
   bd close <id>
   ```
   If `bd` is unavailable or no id was passed, skip this silently.

## Rules

- Infer the commit message from the actual changes — e.g. "update zshrc to guard macOS paths", "add ghost-write command"
- Keep the message short (under 60 chars), lowercase, no trailing period
- If there are untracked files that look like they should be added, mention them to the user but don't add them automatically
- If there's nothing to commit, say so
- **Never create a Beads task here** — `/dotfiles-push` is a utility; it only closes a task id explicitly passed in, and only after the push succeeds
