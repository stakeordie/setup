echo "IT WORKS"

su - ubuntu
cd /home/ubuntu/.pm2/logs && pm2 start --name error_catch_all "./error_catch_all.sh" 
cd /home/ubuntu/auto1111 && pm2 start --name auto1111_web "./webui.sh -w -p 3130"

echo "READY"