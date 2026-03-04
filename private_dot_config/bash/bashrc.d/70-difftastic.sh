if command -v difft &>/dev/null; then
  export DFT_DISPLAY=side-by-side-show-both
  export DFT_SKIP_UNCHANGED=true
else
  warn "difftastic not installed. Install: brew install difftastic"
fi
