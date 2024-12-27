#!/usr/bin/env bash

apt-get update
apt-get install -y dist-upgrade

cd /boot/

cp -r PiBoy_Installer/osd.cfg firmware/

mkdir -p /opt/retropie/configs/all/emulationstation/scripts
cp -r PiBoy-Installer/PiBoy-Setup/opt/retropie/configs/all/emulationstation/scripts/* /opt/retropie/configs/all/emulationstation/scripts
	
cp -r PiBoy-Installer/PiBoy-Setup/home/pi/osd /home/pi
cp -r PiBoy-Installer/PiBoy-Setup/usr/src/* /usr/src	

cp -r PiBoy-Installer/PiBoy-Setup/usr/lib/systemd/system/* /usr/lib/systemd/system

chmod +x /home/pi/osd/*
chmod +x /opt/retropie/configs/all/emulationstation/scripts/*

git clone https://github.com/dell/dkms.git
make install-debian

cd /usr/src/
dkms install xpi_gamecon/1.0

sed -zi '/xpi-gamecon/!s/$/\nxpi-gamecon/' /etc/modules

systemctl enable xpi_gamecon_shutdown.service
systemctl enable xpi_gamecon_reboot.service

apt-get install -y raspberrypi-kernel-headers

CONFIG_TXT="

# BOOT
auto_initramfs=1
gpio=0-9,12-17,20-25=a2
disable_splash=1	
boot_delay=0

# DISPLAY
dtoverlay=vc4-kms-v3d
#dtoverlay=vc4fkms-v3d 
max_framebuffers=2
disable_overscan=1

# LCD
enable_dpi_lcd=1
hvs_set_dither=0x210
dpi_group=2
dpi_mode=87
dpi_output_format=0x070016 
dpi_timings=640 1 80 80 80 480 1 13 13 13 0 0 0 70 0 32000000 1 # DEFAULT
#dpi_timings=640 1 56 4 42 480 1 16 4 12 0 0 0 60 0 22800000 1  # RPI4 ONLY

# HDMI
hdmi_mode:1=85
hdmi_group:1=2
hdmi_drive1=2

# AUDIO (snd_bcm2835)
dtparam=audio=on
#audio_pwm_mode=2
#classicaudio
#dtoverlay=audremap,pins_18_19

# DISABLE LEDS
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off	

#ETHERNET
dtparam=eth_led0=4
dtparam=eth_led1=4

"
cd /boot/

touch firmware/config.txt
echo "${CONFIG_TXT}" > firmware/config.txt 

git clone --depth=1 http://github.com/RetroPie/RetroPie-Setup.git

cd RetroPie-Setup/
./retropie_setup.sh
