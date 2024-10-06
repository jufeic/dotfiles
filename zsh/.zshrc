# User configuration
export KERNEL=$(uname)
if [[ $KERNEL == "Darwin" ]]; then
  # macos
  export CLIPBOARD="pbcopy"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # linux
  if [ -n "$WSL_INTEROP" ]; then
    # wsl
    export CLIPBOARD="/mnt/c/Windows/System32/clip.exe"
  else
    # no wsl
    export CLIPBOARD="xclip -selection clipboard"
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# so that we can call functions with $() in the prompt in themes
setopt PROMPT_SUBST
set -o pipefail
if [[ $TERM_PROGRAM == "tmux" ]]; then
  export FZF_CTRL_R_OPTS="--tmux"
fi
# old: solarized
export BAT_THEME="TwoDark"
export RG_DIRS="$HOME/dotfiles $HOME/hda $HOME/dev"

# history
export HISTFILE=$HOME/.zsh_history
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
alias lg=lazygit
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
  echo -n "$CUTBUFFER" | $CLIPBOARD
}

zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard

# this function is to fuzzy-find files and patterns in files from cli
# ff
# ff <pattern>
# TODO: should be able to open pdf nevertheless in preview then
ff() {
  local file line="1"
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
  project=$(find ~/dotfiles ~/dev ~/hda -type d -name .git | xargs -I {} dirname {} | sort -u | fzf) || return 1
  session_name="~${project#"$HOME"}"
  code $project

  if ! tmux has-session -t "$session_name" 2> /dev/null; then
    tmux_project_windows $session_name $project ""
    tmux_git_window $session_name $project
  else
    # select the nvim pane before checking the window names e.g. if focus is one other pane
    tmux select-pane -t "${session_name}:2.1"
    window_name=$(tmux list-windows -t "$session_name" -F "#{window_index}:#{window_name}" | grep "^2:");
    if [[ $window_name != "2:nvim" ]]; then
      tmux send-keys -t "${session_name}:2.1" "nvim" C-m
    fi
  fi

  tmux switch-client -t "${session_name}:2"

  return 0
}

tmux_project_windows() {
  session_name=$1
  dir=$2
  file=$3
  line=$4
  tmux new-session -d -s "$session_name"
  tmux new-window -t "${session_name}:2"
  tmux send-keys -t "${session_name}:1" "cd ${dir}" C-m C-l
  tmux send-keys -t "${session_name}:2" "cd ${dir}" C-m C-l
  if [[ $file == "" ]]; then
    tmux send-keys -t "${session_name}:2" "nvim" C-m
  else
    tmux send-keys -t "${session_name}:2" "nvim +${line} $file" C-m
  fi
  tmux split-window -h -d -t "${session_name}:2"
  tmux resize-pane -t "${session_name}:2.2" -R 30
  # the C-l is for the prompt logic for extra newline since after
  # executing the cd... command there would be an extra newline
  tmux send-keys -t "${session_name}:2.2" "cd ${dir}" C-m C-l
}

tmux_git_window() {
  session_name=$1
  dir=$2
  tmux new-window -t "${session_name}:3"
  tmux send-keys -t "${session_name}:3" "cd ${dir}" C-m C-l
  tmux send-keys -t "${session_name}:3" "lazygit" C-m
}

open_file() {
  local file line="1"
  if [ "$1" != "" ]; then
    rm -f /tmp/rg-fzf-{r,f}
    file_tmp=$(
      fzf \
	  --keep-right \
	  --ansi \
	  --layout reverse \
	  --delimiter : \
	  --preview 'bat --tabs 2 --color always {1} --highlight-line {2}' \
	  --preview-window '+{2}+3/3,~3' \
	  --bind 'start:reload(echo $RG_DIRS | xargs rg --hidden --smart-case -n '' || true)+unbind(ctrl-r)' \
	  --bind 'change:reload:sleep 0.2;echo $RG_DIRS | xargs rg --hidden --smart-case -n {q} || true' \
	  --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)' \
          --bind 'ctrl-r:unbind(ctrl-r)+change-prompt(ripgrep> )+disable-search+reload(echo $RG_DIRS | xargs rg --hidden --smart-case -n {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)' \
	  --disabled \
          --prompt 'ripgrep> '
    ) || return 1
    file=$(echo "$file_tmp" | cut -d: -f1)
    line=$(echo "$file_tmp" | cut -d: -f2)
  else
    file=$(
      fzf \
	  --ansi \
	  --layout reverse \
	  --preview 'bat --tabs 2 --color always {}' \
	  --bind 'start:reload(echo $RG_DIRS | xargs rg --files --hidden -g "!*.pdf" --smart-case || true)'
    ) || return 1
  fi

  dir=$(dirname "$file")
  git_root=$(git -C "$dir" rev-parse --show-toplevel 2> /dev/null)
  is_git_repo=$?

  if [ $is_git_repo -eq 0 ]; then
    dir="$git_root"
  fi

  session_name="~${dir#"$HOME"}"
  code $dir -g "${file}:${line}"

  if ! tmux has-session -t "$session_name" 2> /dev/null; then
    tmux_project_windows $session_name $dir $file $line

    if [ $is_git_repo -eq 0 ]; then
      tmux_git_window $session_name $dir
    fi
  else
    # select the nvim pane before checking the window names e.g. if focus is one other pane
    tmux select-pane -t "${session_name}:2.1"
    window_name=$(tmux list-windows -t "$session_name" -F "#{window_index}:#{window_name}" | grep "^2:");
    if [[ $window_name == "2:nvim" ]]; then
      tmux send-keys -t "${session_name}:2.1" ":n +${line} $file" C-m
    else
      tmux send-keys -t "${session_name}:2.1" "nvim +${line} $file" C-m
    fi
  fi

  tmux switch-client -t "${session_name}:2"

  return 0
}

if [ -f ~/.secrets ]; then
	source ~/.secrets
fi

if [[ $TERM_PROGRAM != "vscode" ]]; then
	if command -v tmux &> /dev/null && ( ! tmux info &> /dev/null || [ -z "$TMUX" ] ); then
		tmux attach -t dev || tmux new -s dev
	fi
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

# either this to generate the completion functions in a file belonging to fpath
# podman completion zsh -f "$ZSH/completion/_podman"
# or directly source the output without extra file
if [ command -v podman &> /dev/null ]; then
	source <(podman completion zsh)
fi

# thats what terraform adds to the zshrc when adding terraform autocompletion
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C $(brew --prefix)/bin/terraform terraform

export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

# zsh plugins
# the highlighting need to be sourced at the VERY end of .zshrc
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

