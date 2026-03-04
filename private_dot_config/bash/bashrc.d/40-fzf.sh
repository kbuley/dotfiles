if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
else
  warn "fzf not installed. Install: brew install fzf"
fi
