if command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
else
  warn "direnv not installed. Install: brew install direnv"
fi
