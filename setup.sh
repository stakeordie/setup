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

initialize() {
    apt update
    apt install sudo nano nvtop -y
    apt-get install libgoogle-perftools-dev -y
    apt install libcairo2-dev pkg-config python3-dev -y
}

add_ubuntu_user() {
    echo $MY_PUBLIC_KEY
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
    runuser -l ubuntu -c 'pm2 status'
    cp /root/setup/proxy/error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh
}

a1111_options() {
    MODELS_DEFAULT="3.0"
    cr=`echo $'\n>'`
    read -p "Enter list of models:$cr  Options: 1.5, 2.1, 3.0 or SDXL$cr  $MODELS_DEFAULT is selected by default$cr (model_1, model_2, ...): " MODELS
    MODELS="${MODELS:-$MODELS_DEFAULT}"
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
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto1111
    cd /home/ubuntu/auto1111
    git reset --hard 68f336bd994bed5442ad95bad6b6ad5564a5409a
    cd ~
    rm -rf /home/ubuntu/auto1111/models && cp -r /home/ubuntu/models /home/ubuntu/auto1111/models
    rm -rf /home/ubuntu/auto1111/webui-user.sh && cp /root/setup/proxy/webui-user.sh /home/ubuntu/auto1111/webui-user.sh
    rm -rf /home/ubuntu/auto1111/webui.sh && cp /root/setup/proxy/webui.sh /home/ubuntu/auto1111/webui.sh && chmod 755 /home/ubuntu/auto1111/webui.sh
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements.txt
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements_versions.txt
    chown -R ubuntu:ubuntu /home/ubuntu
    runuser -l ubuntu -c 'cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"'
}

start_a1111() {
    COUNT=0
    for i in ${MODELS//,/ }
    do
        case $i in
            1.5) 
                echo "Starting Auto1111 for 1.5"
                runuser -l ubuntu -c 'cd /home/ubuntu/auto1111 && pm2 start --name auto1111_1.5 "./webui.sh -p 3115 -v $COUNT"'
                ;;
            2.1)
                echo "Starting Auto1111 for 2.1"
                runuser -l ubuntu -c 'cd /home/ubuntu/auto1111 && pm2 start --name auto1111_2.1 "./webui.sh -p 3121 -v $COUNT"'
                ;;
            3.0)
                echo "Starting Auto1111 for 3.0"
                runuser -l ubuntu -c 'cd /home/ubuntu/auto1111 && pm2 start --name auto1111_3.0 "./webui.sh -p 3130 -v $COUNT"'
                ;;
            SDXL)
                echo "Starting Auto1111 for SDXL"
                runuser -l ubuntu -c 'cd /home/ubuntu/auto1111 && pm2 start --name auto1111_3.0 "./webui.sh -p 3130 -v $COUNT"'
                ;;
            *)
                echo "$i is an Invalid option"
                ;;
        esac
        if [ $COUNT == 0 ]
        then 
            echo "Sleeping for 180 seconds"
            sleep 180
        fi
        COUNT=$((COUNT+1))
    done
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
    cp -r /home/ubuntu/controlnet /home/ubuntu/auto1111/extensions/sd_webui_controlnet
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

while getopts "f:m:" flag > /dev/null 2>&1
do
    case ${flag} in
        m) METHOD="${OPTARG}" ;;
        f) FUNCTION="${OPTARG}" ;;
        *) break;; 
    esac
done

if [[ -z $METHOD ]]; then
    METHOD_DEFAULT="S"
    read -p "Enter s for Single Function or m for multiple [$METHOD_DEFAULT/m]: " METHOD
    METHOD="${METHOD:-$METHOD_DEFAULT}"
    echo $METHOD
fi

if [[ -z $FUNCTION ]]; then
    echo -n "choose function by number (1 - initialize, 2 - add_ubuntu_user, 3 - configure_nginx, 4 - install_pm2, 5 - a1111_options, 6 - install_a1111, 7 - start_a1111): "
    read FUNCTION
fi


if [[ $METHOD = "s" || $METHOD = "S" ]]; then

    case $FUNCTION in
    1)
        echo "exec: initialize"
        initialize
        ;;
    2)
        echo "exec: add_ubuntu_user"
        add_ubuntu_user
        ;;
    3)
        echo "exec: configure_nginx"
        configure_nginx
        ;;
    4)
        echo "exec: install_pm2"
        install_pm2
        ;;
    5)
        echo "exec: a1111_options"
        a1111_options
        ;;
    6)
        echo "exec: install_auto1111"
        install_a1111
        ;;
    7)
        echo "exec: install_auto1111"
        a1111_options
        start_a1111
        ;;
    *)
        echo "exec: nothing"
        ;;
    esac

else
    case $FUNCTION in
    1)
        echo "exec: initialize"
        initialize
        ;;
    2)
        echo "exec: initialize and add_ubuntu_user"
        initialize
        add_ubuntu_user
        ;;
    3)
        echo "exec: initialize, add_ubuntu_user, and configure_nginx"
        initialize
        add_ubuntu_user
        configure_nginx
        ;;
    4)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, and install_pm2"
        initialize
        add_ubuntu_user
        configure_nginx
        install_pm2
        ;;
    5)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, and install_auto1111"
        a1111_options
        initialize
        add_ubuntu_user
        configure_nginx
        install_pm2
        ;;
    6)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, and install_auto1111"
        a1111_options
        initialize
        add_ubuntu_user
        configure_nginx
        install_pm2
        install_a1111
        ;;
    7)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, and install_auto1111"
        a1111_options
        initialize
        add_ubuntu_user
        configure_nginx
        install_pm2
        install_a1111
        start_a1111
        ;;
    *)
        echo "nothing"
        ;;
    esac
fi


#add_ubuntu_user

#configure_nginx

#install_pm2

#install_a1111

# install_controlnet

# sleep infinity
