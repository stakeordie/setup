#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

<<<<<<< HEAD
=======
while getopts 'p:g:' flag; do
  case "${flag}" in
    p) port="${OPTARG}" ;;
    g) gpu="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done


if [ -z "$port" ]
then
      port=3000
fi

if [ -z "$gpu" ]
then
      gpu=0
fi

>>>>>>> 7938105 (re-init)
# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
#clone_dir="stable-diffusion-webui"
<<<<<<< HEAD
#export XFORMERS_PACKAGE="xformers==0.0.22.post7+cu118"
# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
export COMMANDLINE_ARGS="--xformers --api --port 3000 --medvram --no-half-vae"
=======

# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram>
unset COMMANDLINE_ARGS
export COMMANDLINE_ARGS="--xformers --api --port ${port} --medvram --no-half-vae"

export CUDA_VISIBLE_DEVICES=$gpu

# git executable
#export GIT="git"
>>>>>>> 7938105 (re-init)

# python3 executable
python_cmd="python3.10"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"


# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch A100
export TORCH_COMMAND="pip install clean-fid ninja numba numpy torch==2.0.1+cu118 torchvision -force-reinstall --extra-index-url https://download.pytorch.org/whl/cu118"


# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

# Uncomment to disable TCMalloc
#export NO_TCMALLOC="True"

###########################################