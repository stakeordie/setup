## Build Options

Set IP and PORT locally

`scp -P $PORT ~/code/docker/emprops-server-setup/proxy/.env root@$IP:/root/.env`

Connect to Server

`ssh root@$IP -p $PORT`

Setup and clone setup repo

`echo -e "set -o allexport\nsource /root/.env\nset +o allexport" >> /root/.bashrc && source .bashrc && git clone https://github.com/stakeordie/setup.git /root/setup && cd setup`