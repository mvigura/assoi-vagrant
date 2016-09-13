#!/usr/bin/env bash

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | sudo tee -a /etc/fstab

#add apt repos
#mongo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

#rabbitmq
echo 'deb http://www.rabbitmq.com/debian/ testing main' | tee /etc/apt/sources.list.d/rabbitmq.list
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -

#postgresql
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

sudo apt-get update

#nginx install
sudo apt-get install -y nginx
sudo cp /vagrant/assoi_ugmk.conf /etc/nginx/sites-available/assoi_ugmk.conf
rm -f /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/assoi_ugmk.conf /etc/nginx/sites-enabled/assoi_ugmk.conf
sudo service nginx restart

#postgres install
sudo apt-get install -y postgresql postgresql-contrib
sudo service postgresql restart
sudo su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""
sudo su postgres -c "createdb -U postgres assoi;"
sudo su postgres -c "psql -U postgres assoi < /vagrant/assoi.dump;"

#mongo install
sudo apt-get install -y mongodb-org

#redis install
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
make install
cd utils
./install_server.sh
cd ~

#rabbitmq install
apt-get install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_tracing

rabbitmqctl delete_user guest
rabbitmqctl add_user jet jetparole12j
rabbitmqctl set_permissions jet ".*" ".*" ".*"
rabbitmqctl set_user_tags jet administrator


#other modules
curl -sL https://deb.nodesource.com/setup_6.x | bash -s
apt-get install -y git \
    nodejs \
    python \
    libkrb5-dev \
    libcairo2-dev \
    libjpeg8-dev \
    libpango1.0-dev \
    libgif-dev \
    build-essential \
    g++

npm i -g pm2

npm install -g gitbook-cli
wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"


cd /htdocs/ugmk
sudo npm i --no-bin-links
node install.js
sudo pm2 start ugmk.json
sudo pm2 save