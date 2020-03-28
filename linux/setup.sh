#! /bin/bash

setup_wsl() {
    echo -e '\e[0;33mSetting up wsl specific stuff\e[0m'

    wslTmpDir=~/tmp/setup-wsl
    windowsUserName=$(powershell.exe '$env:UserName' | sed $'s/\r//')

    if [ ! -d "$wslTmpDir" ]; then
        mkdir --parents $wslTmpDir
    fi

    ## setup WSL config
    (
        echo '[automount]'
        echo 'enabled = true'
        echo 'root = /'
        echo 'options = "metadata"'
    )> "$wslTmpDir/wsl.conf"
    sudo mv "$wslTmpDir/wsl.conf" /etc/wsl.conf

    ## symlink go paths
    if [ ! -d "/c/User/$windowsUserName/go" ]; then
        echo -e '\e[1;33mIt appears Go is not installed in Windows, skipping symlink\e[0m'
    else
        ln -s "/c/User/$windowsUserName/go" ~/go
    fi

    ## Common aliases
    echo "" >> $HOME/.zshrc
    echo '# Aliases to useful Windows apps' >> $HOME/.zshrc
    echo "alias p=\"powershell.exe\"" >> $HOME/.zshrc
    echo "alias docker=\"docker.exe\"" >> $HOME/.zshrc
    echo "alias docker-compose=\"docker-compose.exe\"" >> $HOME/.zshrc

    # setup docker bridge
    # go get -d github.com/jstarks/npiperelay
    # GOOS=windows go build -o "/mnt/c/Users/$windowsUserName/go/bin/npiperelay.exe" github.com/jstarks/npiperelay

    # sudo ln -s "/mnt/c/Users/$windowsUserName/go/bin/npiperelay.exe" /usr/local/bin/npiperelay.exe

    # sudo apt install socat

    # echo '#!/bin/sh' >> ~/docker-relay
    # echo 'exec socat UNIX-LISTEN:/var/run/docker.sock,fork,group=docker,umask=007 EXEC:"npiperelay.exe -ep -s //./pipe/docker_engine",nofork' >> ~/docker-relay
    # chmod +x ~/docker-relay
    # sudo adduser ${USER} docker

    rm -rf $wslTmpDir
}

install_shell() {
    echo -e '\e[0;33mSetting up zsh as the shell\e[0m'

    ## zsh
    sudo apt-get install zsh -y

    curl -L http://install.ohmyz.sh | sh
    sudo chsh -s /usr/bin/zsh ${USER}
    wget https://raw.githubusercontent.com/aaronpowell/system-init/master/linux/.zshrc -O ~/.zshrc

    ## tmux
    sudo apt install tmux -y
}

install_docker() {
    echo -e '\e[0;33mSetting up docker\e[0m'

    sudo apt-get update
    sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common \
        -y

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository --yes \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable nightly test"

    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
    
    sudo groupadd docker
    sudo usermod -aG docker $USER
}

install_configs() {
    echo -e '\e[0;33mPreparing to download config files for core programs\e[0m'

    ## If Sublime Text is installed pull down user config
    if [ ! -d "/c/User/$windowsUserName/AppData/Roaming/Sublime Text 3/Packages/User" ]; then
        echo -e '\e[1;33mIt appears Sublime Text 3 is not installed in Windows, skipping\e[0m'
    else
        wget https://raw.githubusercontent.com/aspiziri/system-install/master/common/Preferences.Sublime-Settings -O "/c/User/$windowsUserName/AppData/Roaming/Sublime Text 3/Packages/User/Preferences.Sublime-Settings"
    fi


    ## If Windows Terminal is installed pull down theme/config
    if [ ! -d "/c/User/$windowsUserName/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/profiles.json" ]; then
        echo -e '\e[1;33mIt appears Windows Terminal is not installed in Windows, skipping\e[0m'
    else
        wget https://raw.githubusercontent.com/aspiziri/system-install/master/windows/profiles.json -O "/c/User/$windowsUserName/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/profiles.json"
    fi
}

echo -e '\e[0;33mPreparing to setup a linux machine from a base install\e[0m'

tmpDir=~/tmp/setup-base

if [ ! -d "$tmpDir" ]; then
    mkdir --parents $tmpDir
fi

## General updates
sudo apt-get update
sudo apt-get upgrade -y

## Utilities
sudo apt-get install unzip curl -y

install_shell
install_docker

rm -rf $tmpDir