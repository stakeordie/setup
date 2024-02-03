FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

ARG PUBLIC_KEY


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt update \
    && apt install sudo nano nvtop nginx wget -y \
    && apt-get install libgoogle-perftools-dev -y \
    && apt install libcairo2-dev pkg-config python3-dev -y

RUN rm -rf /etc/nginx/ngix.conf \
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
RUN npm install -g pm2@latest

COPY --from=proxy post_start.sh /post_start.sh
COPY --from=proxy webui-user.sh /webui-user.sh
COPY --from=proxy webui.sh /webui.sh
COPY --from=proxy error_catch_all.sh /error_catch_all.sh

RUN chmod +x /post_start.sh
CMD /start.sh