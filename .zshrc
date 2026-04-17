export GOPATH="$HOME/go"
export PATH="$HOME/go/bin:$PATH"
export RACK_ENV=development
export PATH="$HOME/.cargo/bin:$PATH"
export AWS_CONFIG_FILE="$HOME/figma/figma/config/aws/sso_config"
export PATH="$HOME/.local/bin:$PATH"

if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="${HOMEBREW_PREFIX}/opt/openssl/bin:$PATH"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig:/usr/local/opt/zlib/lib/pkgconfig:$PKG_CONFIG_PATH"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:/usr/local/opt/openssl@3/lib/pkgconfig:$PKG_CONFIG_PATH"
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
  export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
  export JAVA_HOME=$(/usr/libexec/java_home)
  export MISE_ENV=macos # loads mise.macos.toml
  eval "$(rbenv init -)"
  eval "$(mise activate zsh)"
fi
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
export COCKPIT_DIR="$HOME/cockpit"

# Auto-start Claude in Coder containers
if [[ -n "${CODER_WORKSPACE_NAME}" ]] && [[ $- == *i* ]]; then
  claude --dangerously-skip-permissions
fi
