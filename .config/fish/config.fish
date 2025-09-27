function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'
    

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end

# tmux aliases
alias tmuxd 'tmux detach'
alias tmux0 'tmux attach -t 0'
alias tmux1 'tmux attach -t 1'
alias tmux2 'tmux attach -t 2'
alias tmux3 'tmux attach -t 3'
alias tmux4 'tmux attach -t 4'
alias tmux5 'tmux attach -t 5'
alias tmux6 'tmux attach -t 6'
alias tmux7 'tmux attach -t 7'
alias tmux8 'tmux attach -t 8'
alias tmux9 'tmux attach -t 9'
