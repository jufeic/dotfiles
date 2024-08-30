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

precmd_functions+=(set_return_code_color)

PROMPT='${BLUE}%d${RESET} $(git_branch)${NEWLINE}${RETURN_PROMPT_COLOR}${PROMPT_CHAR}${RESET} '
RPROMPT=''
