if not contains "$HOME/Documents/nfl-toolbox/.uv" $PATH
    # Prepending path in case a system-installed binary needs to be overridden
    set -x PATH "$HOME/Documents/nfl-toolbox/.uv" $PATH
end
