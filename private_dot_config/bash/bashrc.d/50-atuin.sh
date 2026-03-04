if command -v atuin &>/dev/null; then
  eval "$(atuin init bash)"
else
  warn "atuin not installed. Install: https://github.com/atuinsh/atuin"
fi
