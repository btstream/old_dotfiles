#!/bin/bash 

info_file=/tmp/pulse_devices
pacmd list-sinks > $info_file
new_sink=$(cat $info_file | grep index | tee /dev/stdout | grep -m1 -A1 "* index" | tail -1 | cut -c12-)
index=$((new_sink+1))
echo $new_sink
device_name=$(cat $info_file | grep alsa.card_name | cut -d\= -f2 | sed "s/\"//g; s/^ *//g; ${index}!d")

echo $device_name
notify-send -a "Audio Mixer" "Setting default device to: $device_name";
pacmd set-default-sink $new_sink

pacmd list-sink-inputs | grep index | while read line
do
    echo "Moving input: ";
    echo $line | cut -f2 -d' ';
    echo "to sink: $new_sink";
    pacmd move-sink-input `echo $line | cut -f2 -d' '` $new_sink
done
