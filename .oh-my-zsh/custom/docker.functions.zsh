# 
# Helper Functions
#
dcleanup(){
	docker rm $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
	docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}
del_stopped(){
	local name=$1
	local state=$(docker inspect --format "{{.State.Running}}" $name 2>/dev/null)

	if [[ "$state" == "false" ]]; then
		docker rm $name
	fi
}
relies_on(){
	local containers=$@

	for container in $containers; do
		local state=$(docker inspect --format "{{.State.Running}}" $container 2>/dev/null)

		if [[ "$state" == "false" ]] || [[ "$state" == "" ]]; then
			echo "$container is not running, starting it for you."
			$container
		fi
	done
}
torch() {
	docker rm `docker ps --no-trunc -aq`
}

skype(){
	del_stopped skype
	
	uid=$(id -u)

	docker run -d \
		-v /etc/localtime:/etc/localtime:ro \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=unix$DISPLAY \
		--device /dev/video0 \
		--device /dev/snd:/dev/snd \
    		-v /dev/shm:/dev/shm \
		-v /etc/machine-id:/etc/machine-id \
		-v /run/user/$uid/pulse:/run/user/$uid/pulse \
		-v /var/lib/dbus:/var/lib/dbus \
		-v ~/.pulse:/home/justinribeiro/.pulse \
		--name skype \
		jess/skype
}

rainbowstream(){
	docker run -it --rm \
		-v /etc/localtime:/etc/localtime \
		-v $HOME/.rainbow_oauth:/root/.rainbow_oauth \
		-v $HOME/.rainbow_config.json:/root/.rainbow_config.json \
		--name rainbowstream \
		jess/rainbowstream
}

rdp(){
	del_stopped chrome

	# one day remove /etc/hosts bind mount when effing
	# overlay support inotify, such bullshit
	docker run -d \
		--net host \
		-v /etc/localtime:/etc/localtime:ro \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=unix$DISPLAY \
		--name rdp \
		jess/rdesktop
}

chrome-beta(){

        del_stopped chrome_beta	

        docker run -d \
                --memory 4gb \
                --net host \
                -v /etc/localtime:/etc/localtime:ro \
                -v="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                -e DISPLAY=unix$DISPLAY \
                -v $HOME/Downloads:/root/Downloads \
                -v $HOME/.chrome-beta:/data \
		-v /var/run/dbus:/var/run/dbus \
                --device /dev/dri/card0 \
                --device /dev/snd \
                --device /dev/video0 \
                --device /dev/nvidia0 \
                --device /dev/nvidiactl \
                --name chrome_beta \
                justinribeiro/chrome:beta --user-data-dir=/data --force-device-scale-factor=1.2 "$@"

}

chrome-canary(){

        del_stopped chrome_canary

        docker run -d \
                --memory 4gb \
                --net host \
                -v /etc/localtime:/etc/localtime:ro \
                -v="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                -e DISPLAY=unix$DISPLAY \
                -v $HOME/Downloads:/root/Downloads \
                -v $HOME/.chrome-canary:/data \
		-v /var/run/dbus:/var/run/dbus \
                --device /dev/dri/card0 \
                --device /dev/snd \
                --device /dev/video0 \
                --device /dev/nvidia0 \
                --device /dev/nvidiactl \
		--name chrome_canary \
                justinribeiro/chrome:unstable --user-data-dir=/data --force-device-scale-factor=1.2 "$@"

}



###
### Awesome sauce by @jpetazzo
###
command_not_found_handle () {
	# Check if there is a container image with that name
	if ! docker inspect --format '{{ .Author }}' "$1" >&/dev/null ; then
		echo "$0: $1: command not found"
		return
	fi

	# Check that it's really the name of the image, not a prefix
	if docker inspect --format '{{ .Id }}' "$1" | grep -q "^$1" ; then
		echo "$0: $1: command not found"
		return
	fi

	docker run -ti -u $(whoami) -w "$HOME" \
		$(env | cut -d= -f1 | awk '{print "-e", $1}') \
		--device /dev/snd \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-v /etc/localtime:/etc/localtime:ro \
		-v /home:/home \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		"jess/$@"
}
