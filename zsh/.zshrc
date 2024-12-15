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
    export CLIPBOARD="clip.exe"
		alias open="powershell.exe start explorer.exe"
  else
    # no wsl
    export CLIPBOARD="xclip -selection clipboard"
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# avoid duplicates on path
typeset -U path
# so that we can call functions with $() in the prompt in themes
setopt PROMPT_SUBST
set -o pipefail
export FZF_DEFAULT_OPTS="--exact"
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
# to avoid the beep sound in the terminal
unsetopt BEEP

autoload -U colors && colors

# theme
export ZSH=$HOME/.zsh
fpath+=$ZSH/completion
source $ZSH/themes/jjcol.zsh-theme

# Preferred editor for local and remote sessions
export EDITOR='vi'

# aliases
alias k=kubectl
alias docker=podman
alias lg=lazygit
alias vi=nvim
alias vim=nvim
alias ll='ls -lahF --color'
alias rm='rm -I'
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
	# Save the current buffer (command) and the current prefix
	local prefix="❯ "
  local command="$BUFFER"

  # Clear the current line
  echo -ne "\033[2K\r"

  # Reprint the prefix without highlighting
  echo -ne "$prefix"

  # Highlight the command text
  echo -ne "\033[43m$command\033[0m"

  current_window_name=$(tmux display-message -p '#W')
	tmux setw automatic-rename off
	# we must use the disabling of automatic renaming of the title
	# in the tmux status line before renaming the window since otherwise
	# this command itself (tmux rename-window) would already trigger a
	# renaming (if we would have tried to just rename the window directly
	# after sleep)
	tmux rename-window "$current_window_name"
  # Wait for 200ms
  sleep 0.1

  # Redraw the original line (prefix and command without highlight)
  echo -ne "\033[2K\r$prefix$command"

  # Restore the zle prompt
  zle reset-prompt

	tmux setw automatic-rename on
}

zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard

# this function is to open playground main file in go to try out things very quick
test-go() {
	mkdir -p $HOME/dev/go/test
	truncate -s 0 $HOME/dev/go/test/main.go
	echo -e 'package main\n\nfunc main() {\n\n}' > $HOME/dev/go/test/main.go
	code $HOME/dev/go/test -g "$HOME/dev/go/test/main.go:4"
}

path=("$HOME/.scripts" $path)

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

if command -v kind &> /dev/null; then
	source <(kind completion zsh)
fi

# either this to generate the completion functions in a file belonging to fpath
# podman completion zsh -f "$ZSH/completion/_podman"
# or directly source the output without extra file
if command -v podman &> /dev/null; then
	source <(podman completion zsh)
fi

# thats what terraform adds to the zshrc when adding terraform autocompletion
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C $(brew --prefix)/bin/terraform terraform

path=($path /opt/homebrew/opt/node@20/bin)
path=(/usr/local/go/bin $path)
if command -v go &> /dev/null; then
	path=("$(go env GOPATH)/bin" $path)
fi

# zsh plugins
# the highlighting need to be sourced at the VERY end of .zshrc
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

