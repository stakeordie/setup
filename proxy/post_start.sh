#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

initialize() {
    apt update
    apt install sudo nano nvtop -y
    apt-get install libgoogle-perftools-dev -y
    apt install libcairo2-dev pkg-config python3-dev -y
}

add_ubuntu_user() {
    if [[ $PUBLIC_KEY ]]; then
      if [ -d "/home/ubuntu" ]; then
          ### Take action if $DIR exists ###
          echo "User Exists"
      else
          useradd -m -d /home/ubuntu -s /bin/bash ubuntu
          usermod -aG sudo ubuntu
          mkdir -p /home/ubuntu/.ssh && touch /home/ubuntu/.ssh/authorized_keys
          echo $PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys
          chown -R ubuntu:ubuntu /home/ubuntu/.ssh
          touch /etc/ssh/sshd_config.d/ubuntu.conf \
          && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.d/ubuntu.conf \
          && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.d/ubuntu.conf
          service ssh restart
          sudo cp /etc/sudoers /etc/sudoers.bak
          echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
      fi
    fi
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
    mv /error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh
}

install_a1111() {
    echo "Installing a1111..."
    apt-get install git-lfs
    git lfs install
    runuser -l ubuntu -c 'git lfs install'
    git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/models/
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto1111
    cd ~
    rm -rf /home/ubuntu/auto1111/models && mv /home/ubuntu/models /home/ubuntu/auto1111/models
    rm -rf /home/ubuntu/auto1111/webui-user.sh && mv /webui-user.sh /home/ubuntu/auto1111/webui-user.sh
    rm -rf /home/ubuntu/auto1111/webui.sh && mv /webui.sh /home/ubuntu/auto1111/webui.sh && chmod 755 /home/ubuntu/auto1111/webui.sh
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements.txt
    echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements_versions.txt
    chown -R ubuntu:ubuntu /home/ubuntu
    runuser -l ubuntu -c 'cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"'
}

download_models() {
    echo "Downloading Models"
    cd /home/ubuntu/auto1111/models/Stable-diffusion/
    wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt
    wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt
    wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
    wget --user $HUGGING_USER --password $HUGGING_PASSWORD https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors
}

start_a1111() {
    download_models
    chown -R ubuntu:ubuntu /home/ubuntu/
    echo "Starting Auto1111 for SDXL"
    runuser -l ubuntu -c "cd /home/ubuntu/auto1111 && pm2 start --name auto1111_web \"./webui.sh -w -p 3130\""
    service nginx restart
}

# ---------------------------------------------------------------------------- #
#                               RUN                                            #
# ---------------------------------------------------------------------------- #

echo "exec: initialize, add_ubuntu_user, configure_nginx, install_pm2, install_auto1111, and start_auto1111"
initialize
add_ubuntu_user
install_pm2
install_a1111
start_a1111

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
            ALL)
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