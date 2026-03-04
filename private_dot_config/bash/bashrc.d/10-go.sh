if command -v brew &>/dev/null; then
  export GOROOT="$(brew --prefix golang)/libexec"
fi

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH="$PATH:${GOBIN}:${GOROOT}/bin"

test -d "${GOPATH}" || mkdir "${GOPATH}"
test -d "${GOPATH}/src/github.com" || mkdir -p "${GOPATH}/src/github.com"
