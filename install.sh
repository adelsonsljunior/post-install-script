#!/bin/bash

## VARIÁVEIS
DOWNLOADS_DIRECTORY="/tmp/programas"
VSCODE_CONFIGS_DIRECTORY="$HOME/.config/Code/User"
WALLPAPER_DIRECTORY="$HOME/Imagens/wallpapers"
FONTS_DIRECTORY="$HOME/.local/share/fonts"

DEP_PACKAGES=(
    "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
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
    tilix
)

FLATPAK_PROGRAMS=(
    com.obsproject.Studio
    org.telegram.desktop
    dev.vencord.Vesktop
)

DEPENDENCIES=(
    software-properties-common
    apt-transport-https
    zip
    unzip
    dconf-cli
)

GREEN='\e[0;32m'
DEFAULT='\e[0m'

## RESOLVENDO DEPENDÊNCIAS
for dependence in ${DEPENDENCIES[@]}; do
    echo -e "${GREEN}[INFO] - Instalando ${dependence}.${DEFAULT}"
    sudo apt-get install $dependence -y > /dev/null
done

## FUNÇÕES
REMOVE_LOCKS() {
    sudo rm /var/lib/dpkg/lock-frontend
    sudo rm /var/cache/apt/archives/lock
}

INSTALL_DEB_PROGRAMS() {
    echo -e "${GREEN}[INFO] - Instalando pacotes .deb.${DEFAULT}"
    [[ ! -d "$DOWNLOADS_DIRECTORY" ]] && mkdir -p "$DOWNLOADS_DIRECTORY"

     for url in "${DEP_PACKAGES[@]}"; do
        if [[ "$url" == *"code.visualstudio.com"* ]]; then
            filename="vscode_latest_amd64.deb" # Nome personalizado para o VS Code
            filepath="$DOWNLOADS_DIRECTORY/$filename"
            echo -e "${GREEN}[INFO] - Baixando VS Code...${DEFAULT}"
            curl -sSL --progress-bar -o "$filepath" -J "$url"  # -J para pegar o nome real do arquivo
        else
            filename=$(basename "$url")
            filepath="$DOWNLOADS_DIRECTORY/$filename"
            echo -e "${GREEN}[INFO] - Baixando $filename...${DEFAULT}"
            curl -sSL --progress-bar -o "$filepath" "$url"
        fi

        echo -e "${GREEN}[INFO] - Instalando $filename...${DEFAULT}"
        sudo dpkg -i "$filepath" > /dev/null
        sudo apt-get install -f -y > /dev/null  # Corrige dependências
    done
}

APT_UPDATE() {
    sudo apt-get update -y
}

INSTALL_APT_PROGRAMS() {
    for program in ${APT_PROGRAMS[@]}; do
        echo -e "${GREEN}[INFO] - Instalando $program.${DEFAULT}"
        sudo apt-get install $program -y > /dev/null
    done
}

ADD_EXTERN_REPOS() {
    #VAGRANT
    echo -e "${GREEN}[INFO] - Adicionando repositório do Vagrant.${DEFAULT}"
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
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
    for program in ${FLATPAK_PROGRAMS[@]}; do
        echo -e "${GREEN}[INFO] - Instalando $program."
        sudo flatpak install flathub $program -y > /dev/null
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
    dconf load /com/gexperts/Tilix/ < ./configs/tilix/tilix.dconf
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

SET_DEFAULT_TERMINAL() {
    echo -e "${GREEN}[INFO] - Definindo terminal padrão.${DEFAULT}"
    echo "2" | sudo update-alternatives --config x-terminal-emulator > /dev/null
}

INSTALL_MESLO_NF(){
    echo -e "${GREEN}[INFO] - Instalando fonte Meslo NF.${DEFAULT}"
    [[ ! -d "$FONTS_DIRECTORY" ]] && mkdir -p "$FONTS_DIRECTORY"
    curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip" -o /tmp/Meslo.zip
    unzip -o /tmp/Meslo.zip -d "$FONTS_DIRECTORY" > /dev/null
    fc-cache -fv > /dev/null
}

UPDATE_AND_CLEAR_SYSTEM() {
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get autoclean -y
    sudo apt-get autoremove -y
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
INSTALL_MESLO_NF
SET_DEFAULT_TERMINAL
UPDATE_AND_CLEAR_SYSTEM
