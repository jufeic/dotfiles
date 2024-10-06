#!/bin/bash

cd $HOME
if [ ! -d $HOME/dotfiles ]; then
	echo "Cloning dotfiles"
	git clone https://github.com/juliusjjj/dotfiles.git
else
	echo "Dotfiles already cloned"
fi

if [ ! command -v brew &> /dev/null ]; then
	echo "Install homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew already installed"
fi

if [[ $(uname) == "Darwin" ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew install tmux fzf ripgrep lazygit bat stow neovim zsh-syntax-highlighting terraform

if [[ $(uname) == "Linux" ]]; then
	# in macos zsh is already preinstalled
	brew install zsh
	chsh -s "$(brew --prefix)/bin/zsh"
fi

$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t $HOME -S zsh tmux ripgrep
# distinguish between OS and separately apply the stow vscode config
# set a different target directory for vscode config so dont try to set the whole
# path just generalize it under a vscode folder and the target is then dependent on OS
if [[ $(uname) == "Darwin" ]]; then
	$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t "$HOME/Library/Application Support/Code/User" -S vscode
fi

# install vscode extensions
xargs -n 1 code --install-extension < $HOME/dotfiles/vscode/vscode-extensions.txt

touch $HOME/.zsh_history
