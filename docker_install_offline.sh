#!/bin/sh
# -a - address of registry server (address)
# -d - IF INSTALLING DOCKER (docker path)
# -j - IF THIS IS MASTER install docker plugin (JENKINS HOME) the plugin is still docker-custom-build-environment.jpi
# -r - IF REGISTRY SERVER run as a registry (registry tar path, default registry.tar). if not -a, defaults to 5000


if [ $# == 0 ]; then
    echo "
USAGE:
- The docker rpm and registry tarfile must be in the working directory.
- If this is the Jenkins master, Jenkins must be set up already.
- If this is the Jenkins master, docker-custom-build-environment.jpi must be in directory.

To be run on each computer in the network. There should be a designated Jenkins master and registry server.
A normal node's setup should consist of -a and -d (install docker and point to the registry server). Master and server should include the -j or -r options, respectively, to install the Docker plugin or start the registry server.

	-a [host:port]
		IF STARTING A REGISTRY (this or another node)
	   	- Address of the registry server

	-d [.rpm for docker] 
		IF INSTALLING DOCKER
		 - \`ls docker-ce*\` outputs the .rpm name

	-j [path to Jenkins home]
		IF THIS IS MASTER NODE
		- Installs the Docker Jenkins plugin
		- Plugin must be in directory and named 
		   docker-custom-build-environment.jpi

	-r [registry tarfile]
		IF THIS IS REGISTRY HOST
		- Loads and runs registry image
		- Runs on port given in -a. If -a not set, default is 5000	
";
	exit 0
fi 

docker_path=''
jh_path=''
plugin='docker-custom-build-environment.jpi'
reg_addr=''
tar_path=''


while getopts ':a:d:j:r:' flag; do
  case "${flag}" in
	a) reg_addr=${OPTARG} ;;
	d) docker_path=${OPTARG} ;;
	j) jh_path=${OPTARG} ;;
    r) tar_path=${OPTARG} ;;
    *) echo "Unexpected option ${flag}" ; exit 1 ;;
  esac
done

# Install Docker
if [ $docker_path ]; then
	sudo yum install $docker_path
	sudo groupadd docker
	sudo gpasswd -a $USER docker
	newgrp docker
	sudo service docker start
fi

# Install Jenkins plugin
if [ $jh_path ]; then
	echo "Installing Jenkins plugin."
	cp $plguin $jh_path/plugins/$plugin
	sudo service jenkins restart || echo "Jenkins restart failed. Please restart manually." 
fi

# Add configuration for the registry server if applicable
if [ $reg_addr ]; then
	if [ -e /etc/docker/daemon.json ]; then
		sudo sed -i '$s/}/,\n"insecure-registries\":["'$reg_addr'"]}/' /etc/docker/daemon.json
	else
		sudo sh -c "echo '{\"insecure-registries\":[\"'$reg_addr'\"]}' > /etc/docker/daemon.json"
	fi
fi

# Run this guy as the registry server
if [ $tar_path ]; then
	echo "Installing docker-compose and starting registry."
	docker load -i $tar_path
	if [ -z $reg_addr ]; then echo "Using port 5000"; reg_addr='localhost:5000'; fi
	IFS=: read -r host port <<< $reg_addr
	docker run -d -p 5000:$port --restart=always --name registry registry:2
fi
