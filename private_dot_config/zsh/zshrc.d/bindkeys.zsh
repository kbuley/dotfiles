bindkey -v # Enable vim mode

# Insert mode bindings (viins keymap)
bindkey "^[[1~" beginning-of-line               # Home
bindkey "^[[4~" end-of-line                     # End
bindkey "^[[2~" quoted-insert                   # Insert
bindkey "^[[3~" delete-char                     # Key Del
bindkey "^[[5~" beginning-of-buffer-or-history  # Key Page Up
bindkey "^[[6~" end-of-buffer-or-history        # Key Page Down
bindkey "^[[H" beginning-of-line                # Key Home
bindkey "^[[F" end-of-line                      # Key End
bindkey "^[[1;2C" forward-word	                # Shift right-arrow
bindkey "^[[1;2D" backward-word                 # Shift left-arrow

# Normal mode bindings (vicmd keymap)
bindkey -M vicmd "^[[1~" beginning-of-line       # Home
bindkey -M vicmd "^[[4~" end-of-line             # End
bindkey -M vicmd "^[[3~" delete-char             # Del
# bindkey -M vicmd "^[[5~" beginning-of-buffer-or-history  # Page Up, let atuin handle this
#bindkey -M vicmd "^[[6~" end-of-buffer-or-history        # Page Down, let atuin handle this

bindkey -M vicmd "^[[H" beginning-of-line        # Home
bindkey -M vicmd "^[[F" end-of-line              # End
bindkey -M vicmd "^[[1;2C" forward-word          # Shift+Right
bindkey -M vicmd "^[[1;2D" backward-word         # Shift+Left

# Additional useful normal mode bindings
# bindkey -M vicmd 'k' history-search-backward # let atuin handle this
# bindkey -M vicmd 'j' history-search-forward # let atuin handle this
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Have Page Up/Down do start/end of line instead of buffer
bindkey "^[[5~" beginning-of-line-hist
bindkey "^[[6~" end-of-line-hist
bindkey -M vicmd "^[[5~" beginning-of-line-hist
bindkey -M vicmd "^[[6~" end-of-line-hist

# Make backspace work in normal mode
bindkey -M vicmd "^?" backward-delete-char

