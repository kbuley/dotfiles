function gi() { curl -L -s https://www.gitignore.io/api/$@ ;}

function git-top() {
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$root" ]; then
        cd "$root"
    else
        echo "Not inside a Git repository."
        return 1
    fi
}

function git-root() {
    git_root=$(pwd)
    while [ "$git_root" != "/" ]; do
        if [ -e "$git_root/.bare" ]; then
            cd "$git_root"
            return 0
        fi
        git_root=$(dirname "$git_root")
    done
    if [ "$git_root" == "/" ]; then
        echo "You are not in a bare worktree."
        return 1
    fi
}


