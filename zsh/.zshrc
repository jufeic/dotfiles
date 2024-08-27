# User configuration
export KERNEL=$(uname)
if [[ $KERNEL == "Darwin" ]]; then
  # macos
  export CLIPBOARD="pbcopy"
else
  # linux
  export CLIPBOARD="xclip -selection clipboard"
fi

# so that we can call functions with $() in the prompt in themes
setopt PROMPT_SUBST

# history
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt INC_APPEND_HISTORY
# to avoid the % char e.g. if tmux sends keys before completely loaded
unsetopt PROMPT_SP

autoload -U colors && colors

# theme
export ZSH=$HOME/.zsh
fpath+=$ZSH/completion
source $ZSH/themes/jjcol.zsh-theme

# Preferred editor for local and remote sessions
export EDITOR='vi'

# aliases
alias docker=podman
alias vi=nvim
alias vim=nvim
alias ll='ls -lah --color'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
-() {
  cd -
}

# load this module to be able to bind keys for selecting stuff from completion menu
zmodload zsh/complist
bindkey -v
export KEYTIMEOUT=1
bindkey -M viins "^?" backward-delete-char
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# surrounding functionality
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# visually select inside quotes/brackets functionality
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km -- $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km -- $c select-bracketed
  done
done

cursor_mode() {
  # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
  cursor_block='\e[2 q'
  cursor_beam='\e[6 q'

  zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] ||
	[[ $1 = 'block' ]]; then
	echo -ne $cursor_block
    elif [[ ${KEYMAP} == main ]] ||
	  [[ ${KEYMAP} == viins ]] ||
	  [[ ${KEYMAP} = '' ]] ||
	  [[ $1 = 'beam' ]]; then
	echo -ne $cursor_beam
    fi
  }

  zle-line-init() {
    echo -ne $cursor_beam
  }

  zle -N zle-keymap-select
  zle -N zle-line-init
}

cursor_mode

vi-yank-clipboard() {
  zle vi-yank
  echo "$CUTBUFFER" | $CLIPBOARD
}

zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard

# this function is to fuzzy-find files and patterns in files from cli
# ff
# ff <pattern>
# TODO: should be able to open pdf nevertheless in preview then
ff() {
  local file line="1"
  set -o pipefail
  if [ "$1" != "" ]; then
    file_tmp=$(rg --hidden -n "$1" ~/dev ~/hda ~/dotfiles | fzf) || return 1
    file=$(echo "$file_tmp" | cut -d: -f1)
    line=$(echo "$file_tmp" | cut -d: -f2)
  else
    file=$(rg --files --hidden -g '!.git' -g '!.git/**' -g '!*.pdf' ~/dev ~/hda ~/dotfiles | fzf) || return 1
  fi

  dir=$(dirname "$file")
  git_root=$(git -C "$dir" rev-parse --show-toplevel 2> /dev/null)

  if [ $? -eq 0 ]; then
    cd "$git_root"
    pane_id=$(tmux list-panes -t "dev:lazygit" -F "#{pane_id}" 2> /dev/null | head -n 1)
    tmux send-keys -t "$pane_id" q
    tmux send-keys -t "$pane_id" "cd $git_root" C-m
    tmux send-keys -t "$pane_id" "lazygit" C-m
  fi

  nvim +"$line" "$file"

  return 0
}

open_project() {
  local file line="1"
  set -o pipefail
  if [ "$1" != "" ]; then
    file_tmp=$(rg --hidden -n "$1" ~/dev ~/hda ~/dotfiles | fzf) || return 1
    file=$(echo "$file_tmp" | cut -d: -f1)
    line=$(echo "$file_tmp" | cut -d: -f2)
  else
    file=$(rg --files --hidden -g '!.git' -g '!.git/**' -g '!*.pdf' ~/dev ~/hda ~/dotfiles | fzf) || return 1
  fi

  dir=$(dirname "$file")
  git_root=$(git -C "$dir" rev-parse --show-toplevel 2> /dev/null)
  is_git_repo=$?

  if [ $is_git_repo -eq 0 ]; then
    dir="$git_root"
  fi

  session_name="~${dir#"$HOME"}"

  tmux new-session -d -s "$session_name"
  tmux new-window -t "${session_name}:2"
  tmux send-keys -t "${session_name}:1" "cd ${dir} && clear" C-m
  tmux send-keys -t "${session_name}:2" "cd ${dir} && clear" C-m
  tmux send-keys -t "${session_name}:2" "nvim +1 $file" C-m
  tmux split-window -h -d -t "${session_name}:2"
  tmux resize-pane -t "${session_name}:2.2" -R 30
  tmux send-keys -t "${session_name}:2.2" "cd ${dir} && clear" C-m

  if [ $is_git_repo -eq 0 ]; then
    tmux new-window -t "${session_name}:3"
    tmux send-keys -t "${session_name}:3" "cd ${dir} && clear" C-m
    tmux send-keys -t "${session_name}:3" "lazygit" C-m
  fi

  tmux switch-client -t "${session_name}:2"

  return 0
}

if [ -f ~/.secrets ]; then
	source ~/.secrets
fi

# custom commands
# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
if command -v tmux &> /dev/null && ( ! tmux info &> /dev/null || [ -z "$TMUX" ] ); then
  tmux attach -t dev || tmux new -s dev
fi

# configure completion
autoload -Uz compinit
compinit
# enables the behavior for: cd <Tab><Tab> to get an menu to select from completion
zstyle ':completion:*' menu select
# also consider dotfiles when doing e.g. vi <Tab>
_comp_options+=(globdots)

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

podman completion zsh -f "$ZSH/completion/_podman"

# thats what terraform adds to the zshrc when adding terraform autocompletion
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# zsh plugins
# the highlighting need to be sourced at the very end of .zshrc
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

