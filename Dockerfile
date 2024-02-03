FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

ARG PUBLIC_KEY


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt update \
    && apt install sudo nano nvtop nginx wget -y \
    && apt-get install libgoogle-perftools-dev -y \
    && apt install libcairo2-dev pkg-config python3-dev -y

RUN useradd -m -d /home/ubuntu -s /bin/bash ubuntu \
    && usermod -aG sudo ubuntu \
    && mkdir -p /home/ubuntu/.ssh && touch /home/ubuntu/.ssh/authorized_keys \
    && echo ${PUBLIC_KEY} >> /home/ubuntu/.ssh/authorized_keys \
    && chown -R ubuntu:ubuntu /home/ubuntu/.ssh \
    && touch /etc/ssh/sshd_config.d/ubuntu.conf \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.d/ubuntu.conf \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.d/ubuntu.conf \
    && sudo cp /etc/sudoers /etc/sudoers.bak \
    && echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && rm -rf /etc/nginx/ngix.conf \
    && rm -rf /etc/nginx/sites-enabled/default 

COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy nginx-default /etc/nginx/sites-enabled/default

RUN apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update
RUN apt-get install nodejs -y
RUN npm install -g npm@9.8.0

RUN npm install -g pm2@latest \
    && runuser -l ubuntu -c 'pm2 status'

COPY --from=proxy error_catch_all.sh /home/ubuntu/.pm2/logs/error_catch_all.sh

RUN apt-get install git-lfs \
    && git lfs install \
    && runuser -l ubuntu -c 'git lfs install' \
    && git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /home/ubuntu/auto1111 \
    && rm -rf /home/ubuntu/auto1111/models \
    && git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/auto1111/models/ \
    && mkdir /home/ubuntu/auto1111/models/Stable-diffusion

RUN rm -rf /home/ubuntu/auto1111/webui.sh && rm -rf /home/ubuntu/auto1111/webui-user.sh

COPY --from=proxy webui-user.sh /home/ubuntu/auto1111/webui-user.sh
COPY --from=proxy webui.sh /home/ubuntu/auto1111/webui.sh

RUN chmod 755 /home/ubuntu/auto1111/webui.sh \
    && echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements.txt \
    && echo "httpx==0.24.1" >> /home/ubuntu/auto1111/requirements_versions.txt \
    && chown -R ubuntu:ubuntu /home/ubuntu

COPY --from=proxy setup.sh /setup.sh

RUN chmod +x /setup.sh
CMD /setup.sh