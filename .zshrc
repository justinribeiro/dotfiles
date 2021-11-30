ZSH_THEME="oxide"

CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_AUTO_UPDATE="true"

export LANG=en_US.utf8
export LC_ALL=en_US.utf8
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

plugins=(
  docker
  history
  systemd
  extract
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-navigation-tools
  zsh-history-substring-search
  common-aliases
  gcloud
)

# Load up the goods
source ${HOME}/.path
source ${HOME}/.exports
source ${HOME}/.functions
source ${HOME}/.aliases
source ${HOME}/.docker-functions
source ${HOME}/.oh-my-zsh/oh-my-zsh.sh
unsetopt correct_all

# start the gpg-agent
gpg-agent-start

# 6559816046fdf8dd8ca6371f1f6434c3773642c6

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
