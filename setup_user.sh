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
    sudo apt update
    sudo apt install nano nvtop nginx -y
    sudo apt-get install libgoogle-perftools-dev -y
    sudo apt install libcairo2-dev pkg-config python3-dev -y
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
    sudo rm -rf /etc/nginx/ngix.conf && sudo cp ./proxy/nginx.conf /etc/nginx/nginx.conf
    sudo rm -rf /etc/nginx/sites-enabled/default && sudo cp ./proxy/nginx-default /etc/nginx/sites-enabled/default
    sudo service nginx restart
}

install_pm2() {
    echo "Installing pm2..."
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install nodejs -y
    sudo npm install -g npm@9.8.0
    sudo npm install -g pm2@latest
    sudo runuser -l ubuntu -c 'pm2 status'
    sudo cp /home/ubuntu/setup/proxy/error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh
}

a1111_options() {
    MODELS_DEFAULT="3.0"
    cr=`echo $'\n>'`
    read -p "Enter list of models:$cr  Options: 1.5, 2.1, 3.0 or SDXL$cr  $MODELS_DEFAULT is selected by default$cr (model_1, model_2, ...): " MODELS
    MODELS="${MODELS:-$MODELS_DEFAULT}"
}

install_a1111() {
    echo "Installing a1111..."
    sudo apt-get install git-lfs
    git lfs install
    git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/models/
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto1111
    cd /home/ubuntu/auto1111
    if [ $1 = "legacy" ]; then
        git reset --hard 68f336bd994bed5442ad95bad6b6ad5564a5409a
    fi
    cd ~
    rm -rf /home/ubuntu/auto1111/models && cp -r /home/ubuntu/models /home/ubuntu/auto1111/models
    mkdir /home/ubuntu/auto1111/models/Stable-diffusion
    rm -rf /home/ubuntu/auto1111/webui-user.sh && cp /home/ubuntu/setup/proxy/webui-user.sh /home/ubuntu/auto1111/webui-user.sh
    rm -rf /home/ubuntu/auto1111/webui.sh && cp /home/ubuntu/setup/proxy/webui.sh /home/ubuntu/auto1111/webui.sh && chmod 755 /home/ubuntu/auto1111/webui.sh
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements.txt
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements_versions.txt
    sudo chown -R ubuntu:ubuntu /home/ubuntu
    cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"
}

download_models() {
    echo "Downloading Models"
    mkdir -p /home/ubuntu/checkpoints/
    cd /home/ubuntu/checkpoints/
    for i in ${MODELS//,/ }
    do
        case $i in
            1.5) 
                wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt
                ;;
            2.1)
                wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt
                ;;
            3.0)
                wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
                # wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors
                ;;
            4.0)
                wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors
                ;;
            *)
                echo "$i is an Invalid option"
                ;;
        esac
    done
}

start_a1111() {
    # if [ -d "/workspace/checkpoints" ]; then
    #     echo "Models Found"
    #     cp -r /workspace/checkpoints /home/ubuntu/checkpoints/
    # else
    download_models
    # fi
    for i in ${MODELS//,/ }
    do
        case $i in
            1.5) 
                echo "Copying Auto1111"
                runuser -l ubuntu -c "cp -r /home/ubuntu/auto1111 /home/ubuntu/auto1111_1.5"
                echo "Linking base Model"
                runuser -l ubuntu -c "ln -s /home/ubuntu/checkpoints/v1-5-pruned.ckpt /home/ubuntu/auto1111_1.5/models/Stable-diffusion/v1-5-pruned.ckpt"
                echo "Starting Auto1111 for 1.5"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_1.5 && pm2 start --name auto1111_1.5 \"./webui.sh -p 3115\""
                ;;
            2.1)
                echo "Copying Auto1111"
                runuser -l ubuntu -c "cp -r /home/ubuntu/auto1111 /home/ubuntu/auto1111_2.1"
                echo "Linking base Model"
                runuser -l ubuntu -c "ln -s /home/ubuntu/checkpoints/v2-1_768-ema-pruned.ckpt /home/ubuntu/auto1111_2.1/models/Stable-diffusion/v2-1_768-ema-pruned.ckpt"
                echo "Starting Auto1111 for 2.1"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_2.1 && pm2 start --name auto1111_2.1 \"./webui.sh -p 3121\""
                ;;
            3.0)
                echo "Copying Auto1111"
                cp -r /home/ubuntu/auto1111 /home/ubuntu/auto1111_3.0
                echo "Linking base Model"
                ln -s /home/ubuntu/checkpoints/sd_xl_base_1.0.safetensors /home/ubuntu/auto1111_3.0/models/Stable-diffusion/sd_xl_base_1.0.safetensors
                echo "Starting Auto1111 for SDXL"
                cd /home/ubuntu/auto1111_3.0 && pm2 start --name auto1111_3.0 "./webui.sh -p 3130"
                ;;
            4.0)
                echo "Copying Auto1111"
                runuser -l ubuntu -c "cp -r /home/ubuntu/auto1111 /home/ubuntu/auto1111_4.0"
                echo "Linking base Model"
                runuser -l ubuntu -c "ln -s /home/ubuntu/checkpoints/sd_xl_turbo_1.0_fp16.safetensors /home/ubuntu/auto1111_4.0/models/Stable-diffusion/sd_xl_turbo_1.0_fp16.safetensors"
                echo "Starting Auto1111 for SDXL TURBO"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_4.0 && pm2 start --name auto1111_4.0 \"./webui.sh -p 3140\""
                ;;
            *)
                echo "$i is an Invalid option"
                ;;
        esac
    done
}

test_instances() {
    for i in ${MODELS//,/ }
    do
        case $i in
            1.5) 
                python /root/setup/proxy/api_test.py -p 3115 --output=output15.png --height=512 --width=512
                ;;
            2.1)
                python /root/setup/proxy/api_test.py -p 3121 --output=output21.png --height=768 --width=768
                ;;
            3.0)
                python /root/setup/proxy/api_test.py -p 3130 --output=output30.png --height=1024 --width=1024
                ;;
            4.0)
                python /root/setup/proxy/api_test.py -p 3140 --output=output40.png --height=1024 --width=1024
                ;;
            *)
                echo "$i is an Invalid option"
                ;;
        esac
    done
    var=$(ls /root/setup/proxy/test)
    echo $var
}

install_controlnet() {
    git clone https://huggingface.co/lllyasviel/ControlNet /home/ubuntu/controlnet_models/
    git clone https://huggingface.co/lllyasviel/sd_control_collection /home/ubuntu/controlnet_models_2/
    git clone https://github.com/Mikubill/sd-webui-controlnet.git /home/ubuntu/controlnet
    rm -rf /home/ubuntu/controlnet/models && ln -s /home/ubuntu/controlnet_models/models /home/ubuntu/controlnet/models
    chown -R ubuntu:ubuntu /home/ubuntu/controlnet/models
    for i in ${MODELS//,/ }
    do
        case $i in
            1.5) 
                runuser -l ubuntu -c "cp -r /home/ubuntu/controlnet /home/ubuntu/auto1111_1.5/extensions/sd_webui_controlnet"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_1.5 && pm2 delete auto1111_1.5 && pm2 start --name auto1111_1.5 \"./webui.sh -w -p 3151\""
                ;;
            2.1)
                runuser -l ubuntu -c "cp -r /home/ubuntu/controlnet /home/ubuntu/auto1111_2.1/extensions/sd_webui_controlnet"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_2.1 && pm2 delete auto1111_2.1 && pm2 start --name auto1111_2.1 \"./webui.sh -w -p 3121\""
                ;;
            3.0)
                runuser -l ubuntu -c "cp -r /home/ubuntu/controlnet /home/ubuntu/auto1111_3.0/extensions/sd_webui_controlnet"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_3.0 && pm2 delete auto1111_3.0 && pm2 start --name auto1111_3.0 \"./webui.sh -w -p 3130\""
                ;;
            4.0)
                runuser -l ubuntu -c "cp -r /home/ubuntu/controlnet /home/ubuntu/auto1111_4.0/extensions/sd_webui_controlnet"
                runuser -l ubuntu -c "cd /home/ubuntu/auto1111_4.0 && pm2 delete auto1111_4.0 && pm2 start --name auto1111_4.0 \"./webui.sh -w -p 3140\""
                ;;
            *)
                echo "$i is an Invalid option"
                ;;
        esac
    done
}

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
        v) VERSION="${OPTARG}" ;;
        *) break;; 
    esac
done

if [[ -z $METHOD ]]; then
    METHOD_DEFAULT="S"
    read -p "Enter s for Single Function or m for multiple [$METHOD_DEFAULT/m]: " METHOD
    METHOD="${METHOD:-$METHOD_DEFAULT}"
    echo $METHOD
fi

if [[ -z $VERSION ]]; then
    VERSION_DEFAULT="LATEST"
    read -p "Enter s for Single Function or m for multiple [$VERSION_DEFAULT/Legacy]: " VERSION
    VERSION="${VERSION:-$VERSION_DEFAULT}"
    echo $VERSION
fi

if [[ -z $FUNCTION ]]; then
    echo -n "choose function by number (1 - initialize, 2 - add_ubuntu_user, 3 - configure_nginx, 4 - install_pm2, 5 - a1111_options, 6 - install_a1111, 7 - start_a1111, 8 - test_instances): "
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
    8)
        echo "exec: testing instances"
        a1111_options
        install_controlnet
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
        # add_ubuntu_user
        ;;
    3)
        echo "exec: initialize, add_ubuntu_user, and configure_nginx"
        initialize
        a# add_ubuntu_user
        configure_nginx
        ;;
    4)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, and install_pm2"
        initialize
        # add_ubuntu_user
        configure_nginx
        install_pm2
        ;;
    5)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, and install_auto1111"
        a1111_options
        initialize
        # add_ubuntu_user
        configure_nginx
        install_pm2
        ;;
    6)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, and install_auto1111"
        a1111_options
        initialize
        # add_ubuntu_user
        configure_nginx
        install_pm2
        install_a1111
        ;;
    7)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, install_auto1111, and start_auto1111"
        a1111_options
        initialize
        # add_ubuntu_user
        configure_nginx
        install_pm2
        install_a1111
        start_a1111
        ;;
    8)
        echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, install_auto1111, start_auto1111, and install_controlnet"
        a1111_options
        initialize
        # add_ubuntu_user
        configure_nginx
        install_pm2
        install_a1111
        start_a1111
        install_controlnet
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
