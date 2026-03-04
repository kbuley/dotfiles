if [[ "$(uname)" = Darwin ]]; then
  export CURRENTLOC=`dirname $0:A`

  # iTerm2
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${XDG_CONFIG_HOME}/iterm2"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

  test -e "${ZDOTDIR}/.iterm2_shell_integration.zsh" && source "${ZDOTDIR}/.iterm2_shell_integration.zsh"
fi
