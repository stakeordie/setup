## Build Options

Set IP and PORT locally

`scp -P $PORT ~/code/docker/emprops-server-setup/proxy/.env root@$IP:/root/.env`

Connect to Server

`ssh root@$IP -p $PORT`

Setup and clone setup repo

`echo -e "set -o allexport\nsource /root/.env\nset +o allexport" >> /root/.bashrc && source .bashrc && git clone https://github.com/stakeordie/setup.git /root/setup && cd setup`

Run Setup
`./setup.sh`

You will be prompted to choos the a single step or all steps and then the last step to run. For a new install "M" & "8" are most likely correct
