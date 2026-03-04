if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
else
  warn "zoxide not installed. Install: brew install zoxide"
fi
