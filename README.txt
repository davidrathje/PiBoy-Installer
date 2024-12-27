Automatic script to create a PiBoy Retropie image from a standard 32 Raspberry OS image (Bookworm) created with Raspberry Pi Imager.

2.opy all files/folders to the /Boot partition of your Retropie SD card/USB drive.
3.Edit wpa_supplicant.conf to match your region, network name and password.
4.Put your SD card inside your PiBoy and power it up.
5.SSH in and once you are inside Retropie, type ./PiBoy.sh. (Use PuTTY + Bonjour drivers to be able to use pi@raspberry.local instead of IP)
6.After it reboots you should be good to go. Map controls, setup your retropie.