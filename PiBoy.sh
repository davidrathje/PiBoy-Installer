#!/usr/bin/env bash

apt-get update
apt-get dist-upgrade
apt-get install git
apt-get install -y wget unzip

git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git

cd /RetroPie-Setup/
./retropie_setup.sh	

git clone --depth=1 https://github.com/davidrathje/PiBoy_Utilities/

cd /pi

mkdir -p PiBoy-Setup
mkdir -p /opt/retropie/configs/all/emulationstation/scripts
mkdir -p /usr/lib/systemd/system

cp -r /PiBoy-Setup/ /PiBoy-Setup

chmod +x /home/pi/osd/*
chmod +x /opt/retropie/configs/all/emulationstation/scripts/*

cd /usr/src/
dkms install xpi_gamecon/1.0

sed -zi '/xpi-gamecon/!s/$/\nxpi-gamecon/' /etc/modules

systemctl enable xpi_gamecon_shutdown.service
systemctl enable xpi_gamecon_reboot.service

reboot