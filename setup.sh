#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cargar_entornos() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    export SDKMAN_DIR="$HOME/.sdkman"
    [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && \. "$SDKMAN_DIR/bin/sdkman-init.sh"
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
}

actualizar_sistema() {
    sudo apt-get update && sudo apt-get install -y \
        curl git unzip zip build-essential libssl-dev zlib1g-dev \
        wget ca-certificates gnupg lsb-release libffi-dev libsqlite3-dev
}

instalar_docker() {
    if ! command -v docker &> /dev/null; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $USER
    fi
}

instalar_java() {
    [ ! -d "$HOME/.sdkman" ] && curl -s "https://get.sdkman.io" | bash
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 21.0.2-graal || echo "Java presente"
    sdk use java 21.0.2-graal
}

instalar_node() {
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
}

instalar_python() {
    if [ ! -d "$HOME/.pyenv" ]; then
        curl https://pyenv.run | bash
    fi
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
}

configurar_react_shadcn() {
    cargar_entornos
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: Instala Node primero.${NC}"
        return
    fi
    npm install -g lucide-react tailwind-merge clsx tailwindcss-animate
}

configurar_angular() {
    cargar_entornos
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: Instala Node primero.${NC}"
        return
    fi
    npm install -g @angular/cli
}

configurar_cloud_clis() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip && sudo ./aws/install --update
    rm -rf aws awscliv2.zip
    if ! command -v gcloud &> /dev/null; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        sudo apt-get update && sudo apt-get install -y google-cloud-cli
    fi
}

crear_carpetas() {
    local base_dir="$HOME/workspace"
    echo -e "${BLUE}➡️ Creando base en: $base_dir${NC}"
    mkdir -p "$base_dir"
    for folder in back front master portfolio; do
        mkdir -p "$base_dir/$folder"
        if [ -d "$base_dir/$folder" ]; then
            echo -e "${GREEN}✅ Creada: $base_dir/$folder${NC}"
        else
            echo -e "${RED}❌ Falló la creación de: $folder${NC}"
        fi
    done
}

configurar_ssh() {
    read -p "Email GitHub: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    cat "$HOME/.ssh/id_ed25519.pub"
}

while true; do
    echo -e "\n${GREEN}==============================================${NC}"
    echo -e "${GREEN}      CV-NOC ULTIMATE MANAGER v14.0          ${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo "1) FULL SETUP"
    echo "2) Actualizar Sistema"
    echo "3) Docker & Compose"
    echo "4) Java (GraalVM 21)"
    echo "5) Node.js (LTS)"
    echo "6) Python (Pyenv)"
    echo "7) React Core Libs"
    echo "8) Angular CLI"
    echo "9) Cloud CLIs (AWS/GCP)"
    echo "10) Crear Carpetas Workspace"
    echo "11) Configurar Llave SSH"
    echo "12) Salir y Refrescar"
    echo -e "${GREEN}==============================================${NC}"
    read -p "Opción: " opcion

    case $opcion in
        1) actualizar_sistema; instalar_docker; instalar_java; instalar_node; instalar_python; configurar_react_shadcn; configurar_angular; configurar_cloud_clis; crear_carpetas; configurar_ssh ;;
        2) actualizar_sistema ;;
        3) instalar_docker ;;
        4) instalar_java ;;
        5) instalar_node ;;
        6) instalar_python ;;
        7) configurar_react_shadcn ;;
        8) configurar_angular ;;
        9) configurar_cloud_clis ;;
        10) crear_carpetas ;;
        11) configurar_ssh ;;
        12) exec bash; break ;;
        *) echo "Invalido" ;;
    esac
done