Automatic script to create a PiBoy Retropie image from a standard 32 Raspberry OS image (Bookworm) created with Raspberry Pi Imager.

1. Download and edit network / ssh settings to match your region, network name and password inside the imager.
2. Copy all files/folders to the /Boot partition of your Retropie SD card/USB drive.
3. 
4. Put your SD card inside your PiBoy and power it up.
5. SSH inside Retropie, type ./PiBoy.sh. (Use PuTTY + Bonjour drivers to be able to use pi@raspberry.local instead of IP)
6. After it reboots you should be good to go. Map controls, setup your retropie. Profit!