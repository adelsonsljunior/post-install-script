#!/bin/bash

## VARIÁVEIS
DOWNLOADS_DIRECTORY="$HOME/Downloads/programas"
VSCODE_CONFIGS_DIRECTORY="$HOME/.config/Code/User"
WALLPAPER_DIRECTORY="$HOME/Imagens/wallpapers"

DEP_PACKAGES=(
    https://download.virtualbox.org/virtualbox/7.1.6/virtualbox-7.1_7.1.6-167084~Ubuntu~jammy_amd64.deb
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
)

APT_PROGRAMS=(
    vim
    htop
    tree
    build-essential
    code
    vagrant
    zsh
    bruno
    tilix
)

FLATPAK_PROGRAMS=(
    com.obsproject.Studio
    org.kde.okular
    org.telegram.desktop
    dev.vencord.Vesktop
)

DEPENDENCIES=(
    curl
    software-properties-common
    apt-transport-https
    zip
    unzip
    git
    dconf
)

GREEN='\e[0;32m'
RED='\e[0;31m'
DEFAULT='\e[0m'

## RESOLVENDO DEPENDÊNCIAS
for dependence in ${DEPENDENCIES[@]}; do
    if ! dpkg -l | grep -qw "$dependence"; then # Só instala se já não estiver instalado
        echo -e "${RED}[ERRO] - $dependence não está instalado.${DEFAULT}"
        echo -e "${GREEN}[INFO] - Instalando ${dependence}.${DEFAULT}"
        sudo apt install $dependence -y > /dev/null
    else
        echo -e "${GREEN}[INFO] - $dependence já está instalado.${DEFAULT}"
    fi
done

## FUNÇÕES
REMOVE_LOCKS() {
    sudo rm /var/lib/dpkg/lock-frontend
    sudo rm /var/cache/apt/archives/lock
}

INSTALL_DEB_PROGRAMS() {
    [[ ! -d "$DOWNLOADS_DIRECTORY" ]] && mkdir -p "$DOWNLOADS_DIRECTORY"

    for url in ${DEP_PACKAGES[@]}; do
        package_name=$(basename "$url" | cut -d _ -f1)
        if ! dpkg -l | grep -iq $package_name; then
            echo -e "${GREEN}[INFO] - Baixando $package_name.${DEFAULT}"
            curl -L --progress-bar -o "$DOWNLOADS_DIRECTORY/$(basename "$url")" "$url"
            echo -e "${GREEN}[INFO] - Instalando $package_name.${DEFAULT}"
            sudo dpkg -i "$DOWNLOADS_DIRECTORY/$(basename "$url")"
            sudo apt install -f -y # Corrigir dependências quebradas
        else
            echo "[INFO] - $package_name já está instalado."
        fi
    done
}

APT_UPDATE() {
    sudo apt update -y
}

INSTALL_APT_PROGRAMS() {
    for program in ${APT_PROGRAMS[@]}; do
        if ! dpkg -l | grep -iq $program; then
            echo -e "${GREEN}[INFO] - Instalando $program.${DEFAULT}"
            sudo apt install $program -y
        else
            echo -e "${GREEN}[INFO] - $program já está instalado.${DEFAULT}"
        fi
    done
}

ADD_EXTERN_REPOS() {
    #VAGRANT
    echo -e "${GREEN}[INFO] - Adicionando repositório do Vagrant.${DEFAULT}"
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    #VSCODE
    echo -e "${GREEN}[INFO] - Adicionando repositório do Visual Studio Code.${DEFAULT}"
    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg

    #BRUNO
    echo -e "${GREEN}[INFO] - Adicionando repositório do Bruno.${DEFAULT}"
    sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/bruno.gpg --keyserver keyserver.ubuntu.com --recv-keys 9FA6017ECABE0266
    echo "deb [signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" | sudo tee /etc/apt/sources.list.d/bruno.list 
}

VSCODE_INSTALL_EXTENSIONS() {
    echo -e "${GREEN}[INFO] - Instalando extensões do vscode.${DEFAULT}"
    cat ./configs/vscode/extensions.txt | xargs -L 1 code --install-extension
}

VSCODE_CONFIG() {
    [[ ! -d "$VSCODE_CONFIGS_DIRECTORY" ]] && mkdir -p "$VSCODE_CONFIGS_DIRECTORY"
    echo -e "${GREEN}[INFO] - Copiando configurações do vscode.${DEFAULT}"
    cp ./configs/vscode/settings.json $HOME/.config/Code/User
}

INSTALL_FLATPAK_PROGRAMS() {
    for app in ${FLATPAK_PROGRAMS[@]}; do
        echo -e "${GREEN}[INFO] - Instalando $program."
        sudo flatpak install flathub $app -y
    done
}

INSTALL_DOCKER() {
    echo -e "${GREEN}[INFO] - Instalando Docker.${DEFAULT}"
    curl -fsSL https://get.docker.com | sudo bash > /dev/null
    sudo groupadd docker
    sudo usermod -aG docker $USER
}

UP_PORTAINER() {
    echo -e "${GREEN}[INFO] - Subindo Portainer.${DEFAULT}"
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts > /dev/null
}

INSTALL_ASDF() {
    echo -e "${GREEN}[INFO] - Instalando asdf.${DEFAULT}"
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0 > /dev/null
    . "$HOME/.asdf/asdf.sh"
    echo '\n. $HOME/.asdf/asdf.sh' >>~/.bashrc
    echo '\n. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc
}

INSTALL_SDKMAN_JAVA() {
    echo -e "${GREEN}[INFO] - Instalando sdkman.${DEFAULT}"
    curl -s "https://get.sdkman.io" | bash > /dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    echo "[INFO] - Instalando Java.${DEFAULT}"
    sdk install java > /dev/null
}

INSTALL_UV(){
    echo -e "${GREEN}[INFO] - Instalando uv.${DEFAULT}"
    curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null
}

INSTALL_OH_MY_ZSH() {
    echo -e "${GREEN}[INFO] - Instalando oh-my-zsh.${DEFAULT}"
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" > /dev/null
}

INSTALL_OH_MY_ZSH_PLUGINS() {
    echo -e "${GREEN}[INFO] - Instalando plugins do oh-my-zsh.${DEFAULT}"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting > /dev/null
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions > /dev/null
}

ZSH_CONFIG() {
    echo -e "${GREEN}[INFO] - Copiando configurações do zsh.${DEFAULT}"
    cp ./configs/zsh/.zshrc $HOME/.zshrc
}

GIT_CHANGE_DEFAULT_BRANCH_NAME() {
    echo -e "${GREEN}[INFO] - Alterando nome da branch padrão do git.${DEFAULT}"
    git config --global init.defaultBranch main
}

TILIX_CONFIG() {
    echo -e "${GREEN}[INFO] - Copiando configurações do Tilix.${DEFAULT}"
    dconf load /com/gexperts/Tilix/ < .config/tilix/tilix.dconf
}

COPY_WALLPAPERS() {
    echo -e "${GREEN}[INFO] - Copiando wallpapers.${DEFAULT}"
    [[ ! -d "$WALLPAPER_DIRECTORY" ]] && mkdir -p "$WALLPAPER_DIRECTORY"
    cp ./configs/wallpapers/* $WALLPAPER_DIRECTORY
}

SET_WALLPAPER() {
    echo -e "${GREEN}[INFO] - Definindo wallpaper.${DEFAULT}"
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DIRECTORY/eva01.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DIRECTORY/eva01.png"
}

UPDATE_AND_CLEAR_SYSTEM() {
    sudo apt update -y && sudo apt upgrade -y
    sudo apt autoclean -y
    sudo apt autoremove -y
}

## EXECUÇÃO
REMOVE_LOCKS
INSTALL_DEB_PROGRAMS
ADD_EXTERN_REPOS
APT_UPDATE
INSTALL_APT_PROGRAMS
INSTALL_FLATPAK_PROGRAMS
VSCODE_INSTALL_EXTENSIONS
VSCODE_CONFIG
TILIX_CONFIG
INSTALL_DOCKER
UP_PORTAINER
INSTALL_ASDF
INSTALL_SDKMAN_JAVA
INSTALL_UV
INSTALL_OH_MY_ZSH
INSTALL_OH_MY_ZSH_PLUGINS
ZSH_CONFIG
GIT_CHANGE_DEFAULT_BRANCH_NAME
COPY_WALLPAPERS
SET_WALLPAPER
UPDATE_AND_CLEAR_SYSTEM
