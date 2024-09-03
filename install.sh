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

brew install zsh tmux fzf ripgrep lazygit bat stow neovim zsh-syntax-highlighting

if [[ $(uname) == "Linux" ]]; then
  chsh -s "$(brew --prefix)/bin/zsh"
fi

$(brew --prefix)/bin/stow -v 2 -d $HOME/dotfiles -t $HOME -S zsh tmux
