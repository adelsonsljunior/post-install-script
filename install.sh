#!/bin/bash

## VARIÁVEIS
DOWNLOADS_DIRECTORY="$HOME/Downloads/programas"
VSCODE_CONFIGS_DIRECTORY="$HOME/.config/Code/User"

DEP_PACKAGES=(
    https://download.virtualbox.org/virtualbox/7.1.6/virtualbox-7.1_7.1.6-167084~Ubuntu~jammy_amd64.deb
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    https://downloads.mongodb.com/compass/mongodb-compass_1.45.2_amd64.deb
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
)

FLATPAK_PROGRAMS=(
    org.localsend.localsend_app
    com.obsproject.Studio
    md.obsidian.Obsidian
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
)

## RESOLVENDO DEPENDÊNCIAS
for dependence in ${DEPENDENCIES[@]}; do
    if ! dpkg -l | grep -qw "$dependence"; then # Só instala se já não estiver instalado
        echo "[INFO] - $dependence não está instalado."
        echo "[INFO] - Instalando ${dependence}."
        sudo apt install $dependence -y
    else
        echo "[INFO] - $dependence já está instalado."
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
            echo "[INFO] - Baixando $package_name."
            curl -L --progress-bar -o "$DOWNLOADS_DIRECTORY/$(basename "$url")" "$url"
            echo "[INFO] - Instalando $package_name."
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
            echo "[INFO] - Instalando $program."
            sudo apt install $program -y
        else
            echo "[INFO] - $program já está instalado."
        fi
    done
}

ADD_EXTERN_REPOS() {
    #VAGRANT
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    #VSCODE
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
}

VSCODE_INSTALL_EXTENSIONS() {
    echo "[INFO] - Instalando extensões do vscode."
    cat ./configs/vscode/extensions.txt | xargs -L 1 code --install-extension
}

VSCODE_CONFIG() {
    [[ ! -d "$VSCODE_CONFIGS_DIRECTORY" ]] && mkdir -p "$VSCODE_CONFIGS_DIRECTORY"
    echo "[INFO] - Copiando configurações do vscode."
    cp ./configs/vscode/settings.json $HOME/.config/Code/User
}

INSTALL_FLATPAK_PROGRAMS() {
    for app in ${FLATPAK_PROGRAMS[@]}; do
        sudo flatpak install flathub $app -y
    done
}

INSTALL_DOCKER() {
    echo "[INFO] - Instalando Docker."
    curl -fsSL https://get.docker.com | sudo bash
    sudo groupadd docker
    sudo usermod -aG docker $USER
}

UP_PORTAINER() {
    echo "[INFO] - Subindo Portainer."
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
}

INSTALL_ASDF() {
    echo "[INFO] - Instalando asdf."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
    . "$HOME/.asdf/asdf.sh"
    echo -e '\n. $HOME/.asdf/asdf.sh' >>~/.bashrc
    echo -e '\n. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc
}

INSTALL_SDKMAN_JAVA() {
    echo "[INFO] - Instalando sdkman."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    echo "[INFO] - Instalando Java."
    sdk install java
}

INSTALL_OH_MY_ZSH() {
    echo "[INFO] - Instalando oh-my-zsh."
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

INSTALL_OH_MY_ZSH_PLUGINS() {
    echo "[INFO] - Instalando plugins do oh-my-zsh."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
}

ZSH_CONFIG() {
    echo "[INFO] - Copiando configurações do zsh."
    cp ./configs/zsh/.zshrc $HOME/.zshrc
}

GIT_CHANGE_DEFAULT_BRANCH_NAME() {
    echo "[INFO] - Alterando nome da branch padrão do git."
    git config --global init.defaultBranch main
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
VSCODE_INSTALL_EXTENSIONS
VSCODE_CONFIG
INSTALL_FLATPAK_PROGRAMS
INSTALL_DOCKER
UP_PORTAINER
INSTALL_ASDF
INSTALL_SDKMAN_JAVA
INSTALL_OH_MY_ZSH
INSTALL_OH_MY_ZSH_PLUGINS
ZSH_CONFIG
GIT_CHANGE_DEFAULT_BRANCH_NAME
UPDATE_AND_CLEAR_SYSTEM
