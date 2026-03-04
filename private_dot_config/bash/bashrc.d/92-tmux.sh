tmux() {
  local tmux_bin
  tmux_bin=$(command -v tmux)
  case "$1" in
    update-environment|update-env|env-update)
      local v
      while read -r v; do
        if [[ $v == -* ]]; then
          unset "${v/#-/}"
        else
          # Add quotes around the argument
          v="\"$v\""
          eval export "$v"
        fi
      done < <($tmux_bin show-environment)
      ;;
    *)
      $tmux_bin "$@"
      ;;
  esac
}
