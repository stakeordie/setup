#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

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

add_ubuntu_user() {
    useradd -m -d /home/username -s /bin/bash ubuntu
    usermod -aG sudo ubuntu
    mkdir -p /home/ubuntu/.ssh && touch /home/ubuntu/.ssh/authorized_keys
    echo $PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
}

install_pm2() {
    su - ubuntu
    echo "Installing pm2..."
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install nodejs -y
    npm install -g npm@9.8.0
    npm install -g pm2@latest
    exit
}

install_a1111() {
    su - ubuntu
    echo "Installing a1111..."
    cd ~
    # wget --user "$HUGGINGFACE_USER" --password "$HUGGINGFACE_PASSWORD" https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
    # wget --user 'sandy@stakeordie.com' --password 'ZUM2drp4vqj3xbn!ezm' https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
    cp -r /workspace/models ./models
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ~/auto3001
    cd ~/auto3001
    git reset --hard 68f336bd994bed5442ad95bad6b6ad5564a5409a
    cd models/Stable-diffusion
    ln -s ~/models/checkpoints/sd_xl_base_1.0.safetensors sd_xl_base_1.0.safetensors
    cd ../..
    rm -rf webui-user.sh
    cp ~/webui-user.sh webui-user.sh
    pm2 start --name auto::::3001 "./webui.sh"
    exit
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

start_nginx

execute_script "/pre_start.sh" "Running pre-start script..."

echo "Pod Started"

setup_ssh
#start_jupyter
export_env_vars

add_ubuntu_user

install_pm2

install_a1111

execute_script "/post_start.sh" "Running post-start script..."

echo "Start script(s) finished, pod is ready to use."

sleep infinity
