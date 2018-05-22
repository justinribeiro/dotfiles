#!/bin/bash
set -e
set -o pipefail

# install.sh
#
# This is a fork from Jess's:
# https://github.com/jessfraz/dotfiles/blob/6906726c172c5ebdc1ebb897ef95c710efe4d11b/bin/install.sh
#
# This is specific to my use case; YOU HAVE BEEN WARNED :-)

export DEBIAN_FRONTEND=noninteractive

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='Which user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
	fi
}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}

setup_sources_min() {
	apt update
	apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		lsb-release \
		software-properties-common \
		--no-install-recommends

	# git
	sudo add-apt-repository ppa:git-core/ppa

	# turn off translations, speed up apt update
	mkdir -p /etc/apt/apt.conf.d
	echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
}

# Add apt sources
#
# * TLP
# * Yubico
# * Google Cloud
# * Microsoft Azure
# * Google Chrome
# * Signal
# * i3
# * Visual Studio Code
#
setup_sources() {
	setup_sources_min;

	# tlp: Advanced Linux Power Management
	sudo add-apt-repository ppa:linrunner/tlp

	# Yubico
	sudo add-apt-repository ppa:yubico/stable

	# Create an environment variable for the correct distribution
	export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

	# Add the Cloud SDK distribution URI as a package source
	echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

	# Import the Google Cloud Platform public key
	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

	# Setup Azure
	AZ_REPO=$(lsb_release -cs)
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
		 sudo tee /etc/apt/sources.list.d/azure-cli.list

	# Import Microsoft signing keys
	sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
	curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

 	# Add the Google Chrome distribution URI as a package source
	echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

	# Import the Google Chrome public key
	curl https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

	# Signal Desktop
	echo "deb [arch=amd64] https://updates.signal.org/desktop/apt $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/signal.list
	curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -

	# i3 (TODO eventually sway and machine specific)
	/usr/lib/apt/apt-helper download-file http://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2018.01.30_all.deb keyring.deb SHA256:baa43dbbd7232ea2b5444cae238d53bebb9d34601cc000e82f11111b1889078a
	sudo dpkg -i ./keyring.deb
	echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" >> /etc/apt/sources.list.d/sur5r-i3.list

	# Visual Studio Code
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
	sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
}

base_min() {
	apt update
	apt -y upgrade

	apt install -y \
		adduser \
		automake \
		bc \
		bzip2 \
		coreutils \
		dnsutils \
		file \
		findutils \
		gcc \
		git \
		gnupg \
		gnupg2 \
		gnupg-agent \
		grep \
		gzip \
		hostname \
		indent \
		jq \
		less \
		libc6-dev \
		libimobiledevice6 \
		locales \
		lsof \
		htop \
		make \
		mount \
		net-tools \
		pinentry-curses \
		pinentry-tty \
		gnome-terminal \
		scdaemon \
		ssh \
		strace \
		sudo \
		tar \
		tree \
		tzdata \
		usbmuxd \
		unzip \
		xclip \
		xz-utils \
		zip \
		vim \
		zsh \
		zsh-common \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	install_scripts
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

	apt update
	apt -y upgrade

	apt install -y \
		alsa-utils \
		azure-cli \
		cgroupfs-mount \
		google-cloud-sdk \
		network-manager \
		code \
		google-chrome \
		firefox \
		signal-desktop \
		shutter \
		hugo \
		--no-install-recommends

	# install tlp with recommends
	apt install -y tlp tlp-rdw

	setup_sudo

	apt autoremove
	apt autoclean
	apt clean

	install_docker
}

# setup sudo for a user
# because fuck typing that shit all the time
# just have a decent password
# and lock your computer when you aren't using it
# if they have your password they can sudo anyways
# so its pointless
# i know what the fuck im doing ;)
setup_sudo() {
	# add user to sudoers
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a "$TARGET_USER" systemd-journal
	gpasswd -a "$TARGET_USER" systemd-network

	# add go path to secure path
	{ \
		echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${USERNAME}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\""; \
		echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
		echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers

}

# install/update golang from source
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.${kernel}-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	local user="$USER"
	# rebuild stdlib for faster builds
	sudo chown -R "${user}" /usr/local/go/pkg
	CGO_ENABLED=0 go install -a -installsuffix cgo std
	)

	# get commandline tools
	(
	set -x
	set +e
	go get github.com/golang/lint/golint
	go get golang.org/x/tools/cmd/cover
	go get golang.org/x/review/git-codereview
	go get golang.org/x/tools/cmd/goimports
	go get golang.org/x/tools/cmd/gorename
	go get golang.org/x/tools/cmd/guru

	go get github.com/genuinetools/amicontained
	go get github.com/genuinetools/apk-file
	go get github.com/genuinetools/audit
	go get github.com/genuinetools/certok
	go get github.com/genuinetools/img
	go get github.com/genuinetools/netns
	go get github.com/genuinetools/pepper
	go get github.com/genuinetools/reg
	go get github.com/genuinetools/udict
	go get github.com/genuinetools/weather

	go get github.com/axw/gocov/gocov
	go get github.com/crosbymichael/gistit
	go get github.com/davecheney/httpstat
	go get honnef.co/go/tools/cmd/staticcheck
	go get github.com/google/gops
	go get github.com/hyleung/docker-stats
	go get github.com/GoogleChrome/simplehttp2server

	)
}

# installs docker master
# and adds necessary items to boot params
install_docker() {
	# create docker group
	sudo groupadd docker
	sudo gpasswd -a "$TARGET_USER" docker

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	sudo add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) \
		stable"

	sudo apt update
	sudo apt install docker-ce

	systemctl daemon-reload
	systemctl enable docker

	# update grub with docker configs and power-saving items
	# harden
	sed -i.bak 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1 page_poison=1 slab_nomerge vsyscall=none"/g' /etc/default/grub
	echo "Docker has been installed. If you want memory management & swap"
	echo "run update-grub & reboot"
}

# my dotfiles have the existing reference (which is not the stock location)
install_node() {
	# uses https://github.com/mklement0/n-install
	# quiet install
	curl -sL https://git.io/n-install | N_PREFIX=~/.local/n bash -s -- -q -n

	# install yarn
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

	install_web_tooling
}

# i3 window manager
install_wmapps() {
	local pkgs=( feh i3 i3lock i3status scrot suckless-tools dmenu)
	apt install -y "${pkgs[@]}" --no-install-recommends
}

# web tooling for dev
install_web_tooling() {
	yarn global add polymer-cli
	yarn global add eslint
	yarn global add firebase-tools
	yarn global add vsce
	yarn global add bower
}

# install wifi drivers
install_wifi() {
	local system=$1

	if [[ -z "$system" ]]; then
		echo "You need to specify whether it's broadcom or intel"
		exit 1
	fi

	if [[ $system == "broadcom" ]]; then
		local pkg="broadcom-sta-dkms"

		apt install -y "$pkg" --no-install-recommends
	else
		update-iwlwifi
	fi
}

# install wifi drivers
install_wifi() {
	local system=$1

	if [[ -z "$system" ]]; then
		echo "You need to specify whether it's broadcom or intel"
		exit 1
	fi

	if [[ $system == "broadcom" ]]; then
		local pkg="broadcom-sta-dkms"

		apt install -y "$pkg" --no-install-recommends
	else
		update-iwlwifi
	fi
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	# install dotfiles from repo
	git clone git@github.com:justinribeiro/dotfiles.git "${HOME}/dotfiles"
	cd "${HOME}/dotfiles"

	# installs all the things
	make
	)
}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
	echo "Usage:"
	echo "  base                                - setup sources & install base pkgs"
	echo "  basemin                             - setup sources & install base min pkgs"
	echo "  wifi {broadcom, intel}              - install wifi drivers"
	echo "  graphics {intel, geforce, optimus}  - install graphics drivers"
	echo "  wm                                  - install i3 window manager/desktop pkgs"
	echo "  dotfiles                            - get dotfiles"
	echo "  golang                              - install golang and packages"
	echo "  node                                - install node and packages"
	echo "  scripts                             - install scripts"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources

		base
	elif [[ $cmd == "basemin" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_min

		base_min
	elif [[ $cmd == "wifi" ]]; then
		install_wifi "$2"
	elif [[ $cmd == "graphics" ]]; then
		check_is_sudo

		install_graphics "$2"
	elif [[ $cmd == "wm" ]]; then
		check_is_sudo

		install_wmapps
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		get_dotfiles
	elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
 	elif [[ $cmd == "node" ]]; then
		install_node
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	else
		usage
	fi
}

main "$@"