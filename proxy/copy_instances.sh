#!/bin/bash
cd ~

cp -r auto3000 auto3001
cp -r auto3000 auto3002
cp -r auto3000 auto3003
cp -r auto3000 auto3004
cp -r auto3000 auto3005
cp -r auto3000 auto3006
cp -r auto3000 auto3007

cd ~/auto3001
sed -i 's/--port 3000/--port 3001/g' webui-user.sh
pm2 start --name auto:3001 "./webui.sh"

cd ~/auto3002
sed -i 's/--port 3000/--port 3002/g' webui-user.sh
pm2 start --name auto:3002 "./webui.sh"

cd ~/auto3003
sed -i 's/--port 3000/--port 3003/g' webui-user.sh
pm2 start --name auto:3003 "./webui.sh"

cd ~/auto3004
sed -i 's/--port 3000/--port 3004/g' webui-user.sh
pm2 start --name auto:3004 "./webui.sh"

cd ~/auto3005
sed -i 's/--port 3000/--port 3005/g' webui-user.sh
pm2 start --name auto:3005 "./webui.sh"

cd ~/auto3006
sed -i 's/--port 3000/--port 3006/g' webui-user.sh
pm2 start --name auto:3006 "./webui.sh"

cd ~/auto3007
sed -i 's/--port 3000/--port 3007/g' webui-user.sh
pm2 start --name auto:3007 "./webui.sh"