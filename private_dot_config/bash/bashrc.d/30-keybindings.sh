# Enable vim mode (equivalent of bindkey -v in zsh)
set -o vi

# Insert mode bindings (readline vi-insert keymap)
bind '"\e[1~": beginning-of-line'          # Home
bind '"\e[4~": end-of-line'                # End
bind '"\e[2~": quoted-insert'              # Insert
bind '"\e[3~": delete-char'                # Del
bind '"\e[5~": beginning-of-history'       # Page Up
bind '"\e[6~": end-of-history'             # Page Down
bind '"\e[H": beginning-of-line'           # Home (alt)
bind '"\e[F": end-of-line'                 # End (alt)
bind '"\e[1;2C": forward-word'             # Shift+Right
bind '"\e[1;2D": backward-word'            # Shift+Left

# Normal (command) mode bindings (vi-command keymap)
bind -m vi-command '"\e[1~": beginning-of-line'    # Home
bind -m vi-command '"\e[4~": end-of-line'          # End
bind -m vi-command '"\e[3~": delete-char'          # Del
bind -m vi-command '"\e[H": beginning-of-line'     # Home (alt)
bind -m vi-command '"\e[F": end-of-line'           # End (alt)
bind -m vi-command '"\e[1;2C": forward-word'       # Shift+Right
bind -m vi-command '"\e[1;2D": backward-word'      # Shift+Left

# Search in normal mode
bind -m vi-command '"/": reverse-search-history'
bind -m vi-command '"?": forward-search-history'

# Copybuffer: Ctrl+O copies the current line to clipboard (macOS pbcopy)
# Equivalent of oh-my-zsh copybuffer plugin
if [[ "$(uname)" = Darwin ]]; then
  _copy_line_to_clipboard() {
    printf '%s' "${READLINE_LINE}" | pbcopy
  }
  bind -x '"\C-o": _copy_line_to_clipboard'
fi

# Reduce mode switching delay (10ms instead of default 500ms)
bind 'set keyseq-timeout 50'

# Show vim mode in prompt (visual indicator)
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string \1\e[6 q\2'
bind 'set vi-cmd-mode-string \1\e[2 q\2'
