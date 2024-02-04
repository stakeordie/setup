echo "**** syncing venv to workspace, please wait. This could take a while on first startup! ****"
rsync --remove-source-files -rlptDu --ignore-existing /venv/ /workspace/venv/

apt-get install git-lfs && git lfs install \
  && rm -rf /home/ubuntu/auto1111/models \
  && git clone https://github.com/stakeordie/sd_models.git /home/ubuntu/auto1111/models/ \
  && rm -rf /home/ubuntu/auto1111/webui.sh && rm -rf /home/ubuntu/auto1111/webui-user.sh \
  && mv /webui-user.sh /home/ubuntu/auto1111/webui-user.sh \
  && mv /webui.sh /home/ubuntu/auto1111/webui.sh

echo "**** syncing stable diffusion to workspace, please wait ****"
rsync --remove-source-files -rlptDu --ignore-existing /stable-diffusion-webui/ /workspace/stable-diffusion-webui/
apt-get install git-lfs && git lfs install
rm -rf /workspace/stable-diffusion-webui/models/
git clone https://github.com/stakeordie/sd_models.git /workspace/stable-diffusion-webui/models/
ln -s /sd-models/* /workspace/stable-diffusion-webui/models/Stable-diffusion/
ln -s /cn-models/* /workspace/stable-diffusion-webui/extensions/sd-webui-controlnet/models/

if [[ $RUNPOD_STOP_AUTO ]]
then
    echo "Skipping auto-start of webui"
else
    echo "Started webui through relauncher script"
    cd /workspace/stable-diffusion-webui
    python relauncher.py &
fi
