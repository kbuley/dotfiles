if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
else
  warn "fzf not installed. Install: brew install fzf"
fi
