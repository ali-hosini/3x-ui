#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && exit 1 ;;
    esac
}

# Installing dependencies
install_base() {
    apt-get update && apt-get install -y -q wget curl tar tzdata
}

install_x-ui2() {
    cd /usr/local/

    # Fetching latest version from GitHub
    tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo -e "Got x-ui latest version: ${tag_version}, beginning the installation..."
    wget -N --no-check-certificate -O /usr/local/x-ui2-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz

    # Remove any existing x-ui2 directory
    if [[ -e /usr/local/x-ui2/ ]]; then
        systemctl stop x-ui2
        rm -rf /usr/local/x-ui2/
    fi

    # Extract files and configure for the second panel
    mkdir /usr/local/x-ui2
    tar zxvf x-ui2-linux-$(arch).tar.gz -C /usr/local/x-ui2/
    rm -f x-ui2-linux-$(arch).tar.gz
    cd /usr/local/x-ui2
    chmod +x x-ui

    # Copy and modify the service file for x-ui2
    cp /usr/local/x-ui2/x-ui2.service /etc/systemd/system/x-ui2.service
    sed -i 's:x-ui:x-ui2:g' /etc/systemd/system/x-ui2.service
    sed -i 's:/usr/local/x-ui2/:/usr/local/x-ui2/:g' /etc/systemd/system/x-ui2.service

    # Set up x-ui2 executable
    wget --no-check-certificate -O /usr/bin/x-ui2 https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
    chmod +x /usr/bin/x-ui2

    # Reload and start the new service
    systemctl daemon-reload
    systemctl enable x-ui2
    systemctl start x-ui2
    echo -e "${green}x-ui2 ${tag_version}${plain} installation finished, it is running now..."
}

echo -e "${green}Running...${plain}"
install_base
install_x-ui2
