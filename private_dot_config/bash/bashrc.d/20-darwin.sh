if [[ "$(uname)" = Darwin ]]; then
  # iTerm2 preferences
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${XDG_CONFIG_HOME}/iterm2"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

  # iTerm2 shell integration for bash
  if [[ -e "${HOME}/.iterm2_shell_integration.bash" ]]; then
    source "${HOME}/.iterm2_shell_integration.bash"
  elif [[ -e "${XDG_CONFIG_HOME}/iterm2/shell_integration.bash" ]]; then
    source "${XDG_CONFIG_HOME}/iterm2/shell_integration.bash"
  fi
fi
