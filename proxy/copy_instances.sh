#!/bin/bash
cd ~

echo "Copying instances..."
cp -r auto3000 auto3001
cp -r auto3000 auto3002
cp -r auto3000 auto3003
cp -r auto3000 auto3004
cp -r auto3000 auto3005
cp -r auto3000 auto3006
cp -r auto3000 auto3007

echo "updating 3001..."
cd ~/auto3001
sed -i 's/--port 3000/--nowebui --port 3001/g' webui-user.sh
echo "starting auto::::3001..."
pm2 start --name auto::::3001 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

echo "updating 3002..."
cd ~/auto3002
sed -i 's/--port 3000/--nowebui --port 3002/g' webui-user.sh
echo "starting auto::::3002..."
pm2 start --name auto::::3002 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

cd ~/auto3003
echo "updating 3003..."
sed -i 's/--port 3000/--nowebui --port 3003/g' webui-user.sh
echo "starting auto::::3003..." 
pm2 start --name auto::::3003 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

echo "updating 3004..."
cd ~/auto3004
sed -i 's/--port 3000/--nowebui --port 3004/g' webui-user.sh
echo "starting auto::::3004..."
pm2 start --name auto::::3004 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

echo "updating 3005..."
cd ~/auto3005
sed -i 's/--port 3000/--nowebui --port 3005/g' webui-user.sh
echo "starting auto::::3005..."
pm2 start --name auto::::3005 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

echo "updating 3006..."
cd ~/auto3006
sed -i 's/--port 3000/--nowebui --port 3006/g' webui-user.sh
echo "starting auto::::3006..."
pm2 start --name auto::::3006 "./webui.sh"
echo  "sleeping 30s..."
sleep 30s

echo "updating 3007..."
cd ~/auto3007
sed -i 's/--port 3000/--nowebui --port 3007/g' webui-user.sh
echo "starting auto::::3007..."
pm2 start --name auto::::3007 "./webui.sh"
echo "sleeping 30s..."
sleep 30s

cd ~/auto3000
sed -i 's/--port 3000/--nowebui --port 3000/g' webui-user.sh
pm2 restart 0