useradd -m -d /home/ubuntu -s /bin/bash ubuntu \
  && usermod -aG sudo ubuntu \
  && mkdir -p /home/ubuntu/.ssh && touch /home/ubuntu/.ssh/authorized_keys \
  && echo ${PUBLIC_KEY} >> /home/ubuntu/.ssh/authorized_keys \
  && chown -R ubuntu:ubuntu /home/ubuntu/.ssh \
  && touch /etc/ssh/sshd_config.d/ubuntu.conf \
  && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.d/ubuntu.conf \
  && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.d/ubuntu.conf \
  && sudo cp /etc/sudoers /etc/sudoers.bak \
  && echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

apt-get install git-lfs \
  && git lfs install \
  && git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto1111 \
  && rm -rf /home/ubuntu/auto1111/models \
  && git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/auto1111/models/ \
  && rm -rf /home/ubuntu/auto1111/webui.sh && rm -rf /home/ubuntu/auto1111/webui-user.sh \
  && mv /webui-user.sh /home/ubuntu/auto1111/webui-user.sh \
  && mv /webui.sh /home/ubuntu/auto1111/webui.sh

runuser -l ubuntu -c 'pm2 status'
mv /error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh

chmod 755 /home/ubuntu/auto1111/webui.sh \
  && echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements.txt \
  && echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements_versions.txt

mkdir /home/ubuntu/auto1111/models/Stable-diffusion \
&& cd /home/ubuntu/auto1111/models/Stable-diffusion \
&& echo "1.5" \
&& wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt -nv -O v1-5-pruned.ckpt \
&& echo "2.1" \
&& wget https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt -nv -O v2-1_768-ema-pruned.ckpt \
&& echo "SDXL" \
&& wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors -nv -O sd_xl_base_1.0.safetensors \
&& echo "REFINER" \
&& wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors -nv -O sd_xl_refiner_1.0.safetensors \
&& echo "MODEL DONE"

chown -R ubuntu:ubuntu /home/ubuntu

runuser -l ubuntu -c 'cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"'
runuser -l ubuntu -c 'cd /home/ubuntu/auto1111 && pm2 start --name auto1111_web "./webui.sh -w -p 3130"'