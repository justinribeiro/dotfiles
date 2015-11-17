# Custom aliases
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias i3config="nano ~/.i3/config"
alias google-chrome-scale="google-chrome --force-device-scale-factor=1.2"
alias zshrestart=". ~/.zshrc"

alias rdp-sv-ohfive="xfreerdp /u:justin.ribeiro /v:192.168.1.51 /w:1920 /h:1200 /fonts"
alias webcam="guvcview"
alias webcamconfig="guvcview -z"

heidisql() {
	wine ~/.wine/drive_c/Program\ Files\ \(x86\)/HeidiSQL_9.3_Portable/heidisql.exe &!
	exit 0
}

intel-xdk() {
  /opt/intel/XDK/xdk.sh &!
  exit 0
}

android-studio-noibus() {
  export XMODIFIERS=""
  /home/justinribeiro/.local/bin/android-studio
}

# docker functions + aliases
source $ZSH/custom/docker.functions.zsh
