
if [[ "$(uname)" = Darwin ]]; then
  if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  fi

  #  alias docker=podman
  #  alias docker-compose=podman-compose

  # solarized dir_colors
  export CURRENTLOC=`dirname $0:A`
  #  eval $($(brew --prefix)/bin/gdircolors $XDG_DATA_HOME/dircolors-solarized/dircolors.256dark)

  source $(brew --prefix git-extras)/share/git-extras/git-extras-completion.zsh

  # iTerm2
  # Specify the preferences directory
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${XDG_CONFIG_HOME}/iterm2"

  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

  export PATH="$HOME/bin:$(brew --prefix)/bin:$PATH"

  if [ -d "$(brew --prefix)/opt/ruby/bin" ]; then
    export PATH=/opt/homebrew/opt/ruby/bin:$PATH
    export PATH=`gem environment gemdir`/bin:$PATH
  fi
fi

eval "$(zoxide init zsh)"

