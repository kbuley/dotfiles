# Respect NO_COLOR (https://no-color.org) and non-interactive terminals
if [[ -z "$NO_COLOR" && -t 1 ]]; then
  RED=$'\e[31m'
  GREEN=$'\e[32m'
  YELLOW=$'\e[33m'
  BLUE=$'\e[34m'
  MAGENTA=$'\e[35m'
  CYAN=$'\e[36m'
  BOLD=$'\e[1m'
  DIM=$'\e[2m'
  RESET=$'\e[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN=''
  BOLD='' DIM='' RESET=''
fi

info()  { printf '%s\n' "${BLUE}[info]${RESET}  $*"; }
warn()  { printf '%s\n' "${YELLOW}[warn]${RESET}  $*" >&2; }
error() { printf '%s\n' "${RED}[error]${RESET} $*" >&2; }
debug() { [[ -n "$DEBUG" ]] && printf '%s\n' "${DIM}[debug]${RESET} $*" >&2 || true; }
