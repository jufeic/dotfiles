# Define color codes
BLUE='%F{blue}'
GREEN='%F{green}'
RED='%F{red}'
YELLOW='%F{yellow}'
RESET='%f'
PROMPT_CHAR='❯'
NEWLINE=$'\n'

# Function to get the current Git branch
git_branch() {
    local branch
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            branch="${RED}${branch}${RESET}"
            if [[ -n $(git status --porcelain) ]]; then
                echo "$branch ${YELLOW}*${RESET}"
            else
                echo "$branch"
            fi
        fi
    fi
}

set_return_code_color() {
    if [[ $? -eq 0 ]]; then
        RETURN_PROMPT_COLOR=$GREEN  # Green if the last command succeeded
    else
        RETURN_PROMPT_COLOR=$RED    # Red if the last command failed
    fi
}

EXTRA_NEWLINE=""
screen_cleared=true

# Define a ZLE function to handle screen clearing
zle -N clear_screen
clear_screen() {
    # set the extra newline here because precmd functions not called for ctrl-l but
    # the prompt is new loaded
    EXTRA_NEWLINE=""
    screen_cleared=false
    zle clear-screen
}

# Set up key binding for Ctrl-L to use the custom clear_screen function
bindkey '^L' clear_screen

add_newline() {
    if [[ $screen_cleared == true ]]; then
        EXTRA_NEWLINE=""
        screen_cleared=false
    else
        EXTRA_NEWLINE=$'\n'
    fi
}

precmd_functions+=(set_return_code_color add_newline)

PROMPT='${EXTRA_NEWLINE}${BLUE}%d${RESET} $(git_branch)${NEWLINE}${RETURN_PROMPT_COLOR}${PROMPT_CHAR}${RESET} '
RPROMPT=''
