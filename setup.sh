#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

while getopts "f:" flag > /dev/null 2>&1
do
    case ${flag} in
        f) functions="${OPTARG}" ;;
        *) break;; 
    esac
done

# Start nginx service
start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
        service ssh start
    fi
}

# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc
}
# scp -P {{IP}} ~/code/auto1111/doker/proxy/.env root@{{IP}}:/root/.env
init_setup(){
    echo 'source /root/.env' >> /root/.bashrc
    source .bashrc
    git clone https://github.com/stakeordie/setup.git /root/setup
}

initialize() {
    apt update
    apt install sudo nano nvtop -y
    apt-get install libgoogle-perftools-dev -y
    apt install libcairo2-dev pkg-config python3-dev -y
}

add_ubuntu_user() {
    if [ -d "/home/ubuntu" ]; then
        ### Take action if $DIR exists ###
        echo "User Exists"
    else
        useradd -m -d /home/ubuntu -s /bin/bash ubuntu
        usermod -aG sudo ubuntu
        mkdir -p /home/ubuntu/.ssh && touch /home/ubuntu/.ssh/authorized_keys
        echo $MY_PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys
        chown -R ubuntu:ubuntu /home/ubuntu/.ssh
        touch /etc/ssh/sshd_config.d/ubuntu.conf \
        && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.d/ubuntu.conf \
        && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.d/ubuntu.conf
        service ssh restart
        sudo cp /etc/sudoers /etc/sudoers.bak
        echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
    fi
}

configure_nginx() {
    echo "Configuring Nginx..."
    rm -rf /etc/nginx/ngix.conf && cp ./proxy/nginx.conf /etc/nginx/nginx.conf
    rm -rf /etc/nginx/sites-enabled/default && cp ./proxy/nginx-default /etc/nginx/sites-enabled/default
    service nginx restart
}

install_pm2() {
    echo "Installing pm2..."
    apt-get install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install nodejs -y
    npm install -g npm@9.8.0
    npm install -g pm2@latest
    pm2 status
    cp ./proxy/error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh
}

install_a1111() {
    echo "Installing a1111..."
    if [ -d "/workspace/checkpoints" ]; then
        echo "Models Found"
        cp -r /workspace/checkpoints /home/ubuntu/checkpoints/
    else
        echo "Downloading Models"
        mkdir -p /home/ubuntu/checkpoints/
        cd /home/ubuntu/checkpoints/
        wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
    fi
    apt-get install git-lfs
    git lfs install
    runuser -l ubuntu -c 'git lfs install'
    git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/models/
    ln -s /home/ubuntu/checkpoints /home/ubuntu/models/Stable-diffusion
    touch Put Stable Diffusion checkpoints here.txt
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto3.0
    cd /home/ubuntu/auto3.0
    git reset --hard 68f336bd994bed5442ad95bad6b6ad5564a5409a
    cd ~
    rm -rf /home/ubuntu/auto3.0/models && cp -r /home/ubuntu/models /home/ubuntu/auto3.0/models
    rm -rf /home/ubuntu/auto3.0/webui-user.sh && cp ./proxy/webui-user.sh /home/ubuntu/auto3.0/webui-user.sh
    rm -rf /home/ubuntu/auto3.0/webui.sh && cp ./proxy/webui.sh /home/ubuntu/auto3.0/webui.sh && chmod 755 /home/ubuntu/auto3.0/webui.sh
    chown -R ubuntu:ubuntu /home/ubuntu
    runuser -l ubuntu -c 'cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"'
    runuser -l ubuntu -c 'cd /home/ubuntu/auto3.0 && pm2 start --name auto::::3000 "./webui.sh -p 3000"'
    echo "sleeping 3m..."
    sleep 3m
    echo "awake"
    runuser -l ubuntu -c 'cd /home/ubuntu/auto3.0 && pm2 start --name auto::::3000 "./webui.sh -p 3001"'
    runuser -l ubuntu -c 'cd /home/ubuntu/auto3.0 && pm2 start --name auto::::3000 "./webui.sh -p 3002"'
    runuser -l ubuntu -c 'curl 0.0.0.0:3000 >> /home/ubuntu/auto3.0/junk.html'
}

install_controlnet() {
    echo "Installing controlnet..."
    apt-get install git-lfs
    git lfs install
    runuser -l ubuntu -c 'git lfs install'
    git clone https://huggingface.co/lllyasviel/ControlNet /home/ubuntu/controlnet_models/
    git clone https://huggingface.co/lllyasviel/sd_control_collection /home/ubuntu/controlnet_models_2/
    git clone https://github.com/Mikubill/sd-webui-controlnet.git /home/ubuntu/controlnet
    rm -rf /home/ubuntu/controlnet/models && ln -s /home/ubuntu/controlnet_models/models /home/ubuntu/controlnet/models
    cp -r /home/ubuntu/controlnet /home/ubuntu/auto3.0/extensions/sd_webui_controlnet
    chown -R ubuntu:ubuntu /home/ubuntu
}
# Start jupyter lab
# start_jupyter() {
#     if [[ $JUPYTER_PASSWORD ]]; then
#         echo "Starting Jupyter Lab..."
#         mkdir -p /workspace && \
#         cd / && \
#         nohup jupyter lab --allow-root --no-browser --port=8888 --ip=* --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --ServerApp.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
#         echo "Jupyter Lab started"
#     fi
# }

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

#start_nginx

#execute_script "/pre_start.sh" "Running pre-start script..."

#echo "Pod Started"

#setup_ssh
#start_jupyter
#export_env_vars

#clone_setup
echo $functions

#initialize

#add_ubuntu_user

#configure_nginx

#install_pm2

#install_a1111

# install_controlnet

# sleep infinity
