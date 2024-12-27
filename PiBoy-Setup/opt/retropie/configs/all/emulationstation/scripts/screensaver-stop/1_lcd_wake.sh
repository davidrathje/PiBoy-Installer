#!/bin/bash

TVCHECK=$(/opt/vc/bin/tvservice -s | grep -c "[\bLCD\b]")
if [[ "$TVCHECK" == "1" ]];
then sudo sh -c "echo "1" > /sys/kernel/xpi_gamecon/flags"
fi
