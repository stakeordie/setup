ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG TORCH
ARG PYTHON_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

# Set the working directory
WORKDIR /

# Create workspace directory
RUN mkdir -p /workspace


# NGINX Proxy
COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy nginx-default /etc/nginx/sites-available/default
COPY --from=proxy readme.html /usr/share/nginx/html/readme.html
COPY --from=proxy webui-user.sh /root/webui-user.sh
COPY --from=proxy webui-user.sh /root/copy_instances.sh

# Copy the README.md
COPY README.md /usr/share/nginx/html/README.md

# Start Scripts
COPY --from=scripts start.sh /
RUN chmod +x /start.sh

# Custom MOTD
COPY --from=scripts runpod.txt /etc/motd

# Set the default command for the container
CMD [ "/start.sh" ]