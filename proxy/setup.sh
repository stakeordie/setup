echo "IT WORKS"

su - ubuntu
cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh"

cd /home/ubuntu/auto1111/models/Stable-diffusion \
&& wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt -O v1-5-pruned.ckpt \
&& wget https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt -O v2-1_768-ema-pruned.ckpt \
&& wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors -O sd_xl_base_1.0.safetensors \
&& wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors -O sd_xl_refiner_1.0.safetensors

cd /home/ubuntu/auto1111 && pm2 start --name auto1111_web "./webui.sh -w -p 3130"

echo "READY"

exit

exit 0