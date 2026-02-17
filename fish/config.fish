set -U fish_greeting ""
if status is-interactive
    fish_add_path ~/.cargo/bin
    fish_add_path ~/.config/scripts
end

# uv
fish_add_path "/home/necheporenko_s_iu/.local/bin"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
