#!/bin/sh

outputs() {
    declare -a sink_index=()

    # declare a value maps
    declare -A dev_map=()

    # cache value
    info_file=$(mktemp --suffix '-chdadv')
    device_name_file=$(mktemp --suffix '-chdadv')
    pacmd list-sinks > $info_file

    # get indexes
    indexes=$(cat $info_file | grep index | cut -d\: -f2 | sed 's/ *//g')
    j=0
    for i in $indexes; do
        sink_index[$j]=$i
        j=$((j+1))
    done

    # get device names
    cat $info_file | grep alsa.card_name | cut -d\= -f2 | sed 's/"//g; s/^ *//g' > $device_name_file

    # generate devcice map
    k=0
    for i in ${sink_index[@]}; do
        l=$((k+1))
        device_name=$(sed "$l!d" $device_name_file)
        dev_map[$device_name]=${sink_index[$k]}
        k=$l
    done

    OUTPUT=$(cat $device_name_file | rofi -dmenu -i -p "OUTPUT" -mesg "Select prefered output audio device")
    if [[ x$OUTPUT != x ]]; then
        new_sink=${dev_map[$OUTPUT]}
        echo $new_sink
        pacmd set-default-sink $new_sink

        pacmd list-sink-inputs | grep index | while read line
        do
            echo "Moving input: ";
            echo $line | cut -f2 -d' ';
            echo "to sink: $new_sink";
            pacmd move-sink-input `echo $line | cut -f2 -d' '` $new_sink
        done
        notify-send -a "Audio Mixer" "Setting default device to: $OUTPUT"
    fi

    rm -rf $info_file $device_name_file 
}

inputs() {
    INPUT=$(pactl list short sources | cut  -f 2 | grep input | rofi -i -dmenu -p "INPUT" -mesg "Select prefered input source" )
    pacmd set-default-source "$INPUT" >/dev/null 2>&1

    for recording in $(pacmd list-source-outputs | awk '$1 == "index:" {print $2}'); do
        pacmd move-source-output "$recording" "$INPUT" >/dev/null 2>&1
    done
}

volume_up() {
    pactl set-sink-volume @DEFAULT_SINK@ +3%
}

volume_down() {
    pactl set-sink-volume @DEFAULT_SINK@ -3%
}

mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
}

volume_source_up() {
    pactl set-source-volume @DEFAULT_SOURCE@ +3%
}

volume_source_down() {
    pactl set-source-volume @DEFAULT_SOURCE@ -3%
}

mute_source() {
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
}

get_default_sink() {
    pacmd stat | awk -F": " '/^Default sink name: /{print $2}'
}

output_volume() {
     pacmd list-sinks | awk '/^\s+name: /{indefault = $2 == "'"<$(get_default_sink)>"'"}
             /^\s+muted: / && indefault {muted=$2}
             /^\s+volume: / && indefault {volume=$5}
             END { 
                if (muted == "no") {
                    volume_num = substr(volume, 1, length(volume)) + 0;
                    if (volume_num>=75) {
                        icon = "";
                    } else if (volume_num <= 20) {
                        icon = "";
                    } else {
                        icon = "";
                    }
                    if (volume_num >= 100){
                        printf("%s%4d%\n", icon, volume_num);
                    } else {
                        printf("%s%3d%\n", icon, volume_num);
                    }
                } else {
                    print "ﱝ Muted";
                }
             }'
}

get_default_source() {
    pacmd stat | awk -F": " '/^Default source name: /{print $2}'
}

input_volume() {
     pacmd list-sources | awk '/^\s+name: /{indefault = $2 == "'"<$(get_default_source)>"'"}
             /^\s+muted: / && indefault {muted=$2}
             /^\s+volume: / && indefault {volume=$5}
             END { print muted=="no"?volume:"Muted" }'
}

output_volume_listener() {
    LC_ALL=C pactl subscribe | while read -r event; do
        if echo "$event" | grep -q "change"; then
            output_volume
        fi
    done
}

input_volume_listener() {
    pactl subscribe | while read -r event; do
        if echo "$event" | grep -q "change"; then
            input_volume
        fi
    done
}

case "$1" in
    --output)
        outputs
    ;;
    --input)
        inputs
    ;;
    --mute)
        mute
    ;;
    --mute_source)
        mute_source
    ;;
    --volume_up)
        volume_up
    ;;
    --volume_down)
        volume_down
    ;;
    --volume_source_up)
        volume_source_up
    ;;
    --volume_source_down)
        volume_source_down
    ;;
    --output_volume)
        output_volume
    ;;
    --input_volume)
        input_volume
    ;;
    --output_volume_listener)
        output_volume
        output_volume_listener
    ;;
    --input_volume_listener)
        input_volume
        input_volume_listener
    ;;
    *)
        echo "Wrong argument"
    ;;
esac
