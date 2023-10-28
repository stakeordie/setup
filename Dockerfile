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
RUN mkdir /workspace

# Update, upgrade, install packages and clean up
RUN apt-get update --yes
RUN apt-get upgrade --yes
RUN apt install --yes --no-install-recommends git wget curl bash libgl1 software-properties-common openssh-server nginx sudo nano nvtop
RUN apt-get install libgoogle-perftools-dev -y
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install "python${PYTHON_VERSION}-dev" "python${PYTHON_VERSION}-venv" -y --no-install-recommends
RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen


# Set up Python and pip
RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py

RUN echo $(pip --version)


RUN pip install --upgrade --no-cache-dir pip
RUN pip uninstall torch
RUN pip cache purge
RUN pip install --upgrade --no-cache-dir ${TORCH}
RUN pip install --upgrade --no-cache-dir jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions

# Set up Jupyter Notebook
#RUN pip install notebook==6.5.5
#RUN jupyter contrib nbextension install --user && \
#    jupyter nbextension enable --py widgetsnbextension


# NGINX Proxy
COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy nginx-default /etc/nginx/sites-available/default
COPY --from=proxy readme.html /usr/share/nginx/html/readme.html
COPY --from=proxy webui-user.sh ~/webui-user.sh

# Copy the README.md
COPY README.md /usr/share/nginx/html/README.md



# Start Scripts
COPY --from=scripts start.sh /
RUN chmod +x /start.sh

# Custom MOTD
COPY --from=scripts runpod.txt /etc/motd

# Set the default command for the container
CMD [ "/start.sh" ]