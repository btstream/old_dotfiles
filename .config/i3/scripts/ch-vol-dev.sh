#!/bin/bash 

declare -a sink_index=()

# declare a value maps
declare -A dev_map=()

# cache value
info_file=/tmp/pulse_devices
pacmd list-sinks > $info_file

# get indexes
indexes=$(cat $info_file | grep index | cut -d\: -f2 | sed 's/ *//g')
j=0
for i in $indexes; do
    sink_index[$j]=$i
    j=$((j+1))
done

# get device names
cat $info_file | grep alsa.card_name | cut -d\= -f2 | sed 's/"//g; s/^ *//g' > /tmp/pulse_device_name 

k=0
for i in ${sink_index[@]}; do
    l=$((k+1))
    device_name=$(sed "$l!d" /tmp/pulse_device_name)
    dev_map[${sink_index[$k]}]="$device_name"
    k=$((k+1))
done

new_sink=$(cat $info_file | grep index | tee /dev/stdout | grep -m1 -A1 "* index" | tail -1 | cut -c12-)
notify-send -a "Audio Mixer" "Setting default device to: ${dev_map[$new_sink]}";
pacmd set-default-sink $new_sink

pacmd list-sink-inputs | grep index | while read line
do
    echo "Moving input: ";
    echo $line | cut -f2 -d' ';
    echo "to sink: $new_sink";
    pacmd move-sink-input `echo $line | cut -f2 -d' '` $new_sink
done
