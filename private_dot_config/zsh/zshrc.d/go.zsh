if [[ "$(uname)" = Darwin ]]; then
  export GOROOT="$(brew --prefix golang)/libexec"
fi

export GOPATH=$HOME/go
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

test -d "${GOPATH}" || mkdir "${GOPATH}"
test -d "${GOPATH}/src/github.com" || mkdir -p "${GOPATH}/src/github.com"
