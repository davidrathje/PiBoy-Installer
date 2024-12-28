#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PAYLOAD_DIR="${SCRIPT_DIRECTORY}/PiBoy-Installer/PiBoy-Setup"

apt-get update

cp -r "${PAYLOAD_DIR}/home/pi/osd" /home/pi
cp -r $PAYLOAD_DIR/usr/src/* /usr/src

mkdir -p /opt/retropie/configs/all/emulationstation/scripts
cp -r $PAYLOAD_DIR/opt/retropie/configs/all/emulationstation/scripts/* /opt/retropie/configs/all/emulationstation/scripts

cp -r $PAYLOAD_DIR/usr/lib/systemd/system/* /usr/lib/systemd/system

chmod +x /home/pi/osd/*
chmod +x /opt/retropie/configs/all/emulationstation/scripts/*

OSD_CFG=" 
#classicaudio Use PCM instead of HDMI/HEADPHONE audio devices
#classicaudio
#loadwait sets an application to wait to open before closing the boot splash screen
#loadwait
#emulationstation
#LED maximum brightness
redled
5	
greenled
5
##Volumeicon enables displaying the volume slider when changing volume. 0 disables display.  1 thru 100 sets transparency(alpha).
volumeicon
75
##Fanduty defines the number of temperature bands and fan power for each given temperature.  
#temps are in millidegrees
#duty/power is in tenths of a percent.  0 to 254 = 0% to 25.4% duty. Setting 255 will set 100% power.
#on boot fan is set to 100% power until changed by osd or third party applications.
fanduty
6
50000 0
55000 20
60000 40
65000 140
70000 200
75000 220
##Temperature shows processor temp in degrees C
#alpha 0 to 100
#x 0 to 639
#y 0 to 479
#size small, medium or large
temperature
100
80
5
small

##Voltage shows estimated open circuit battery voltage
#alpha 0 to 100
#x 0 to 639
#y 0 to 479
#size small, medium or large
voltage
100
140
5
small

##Current shows battery current. Positive current is charging and negative current is discharging
#alpha 0 to 100
#x 0 to 639
#y 0 to 479
#size small, medium or large
current
100
190
5
small
##Bluetooth
bluetooth
100
550
0
amall
##WIFI
wifi
100
580
0
small
##Battery
battery
100
610
small

"

CONFIG_TXT="
[all]
avoid_warnings=2
gpu_mem_256=192
gpu_mem_512=256
gpu_mem_1024=448
overscan_scale=1
disable_splash=1
boot_delay=0
initial_turbo=60
force_eeprom_read=0

##10% overclock
arm_freq=1100
over_voltage=8
sdram_freq=500
sdram_over_voltage=2
force_turbo=1
boot_delay=1

##Enable DPI gpio
gpio=0-9,12-17,20-25=a2

##Audio Settings
dtparam=audio=on
audio_pwm_mode=2
dtoverlay=audremap,pins_18_19

##Disable ACT LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
  
##Disable PWR / ETHERNET LED
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
dtparam=eth_led0=4
dtparam=eth_led1=4

##Disable Bluetooth
#dtoverlay=disable-bt

##DPI LCD settings
hvs_set_dither=0x210
dpi_group=2
dpi_mode=87
dpi_output_format=0x070016
enable_dpi_lcd=1

##Default
dpi_timings=640 1 80 80 80 480 1 13 13 13 0 0 0 70 0 32000000 1

##Alternate 60hz setting for Pi4 only.
dpi_timings=640 1 56 4 42 480 1 16 4 12 0 0 0 60 0 22800000 1               

##Start with these settings first. This is like hdmi_safe interlaced.
#hdmi_safe=1
hdmi_force_hotplug=1
config_hdmi_boost=4
hdmi_group=1
hdmi_mode=0
disable_overscan=0

##Auto detect HDMI
[edid=*]
enable_dpi_lcd=0
"

touch /boot/osd.cfg
echo "${OSD_CFG}" > /boot/osd.cfg
touch /boot/config.txt
echo "${CONFIG_TXT}" > /boot/config.txt

cd /usr/src/
dkms install xpi_gamecon/1.0

sed -zi '/xpi-gamecon/!s/$/\nxpi-gamecon/' /etc/modules

systemctl enable xpi_gamecon_shutdown.service
systemctl enable xpi_gamecon_reboot.service
