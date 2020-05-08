ZSH_THEME="oxide"

CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_AUTO_UPDATE="true"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

plugins=(
  docker
  history
  systemd
  extract
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-navigation-tools
  history-substring-search
  common-aliases
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
