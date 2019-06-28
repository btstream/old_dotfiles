#!/bin/bash

new_mc_window() {
    i3-msg 'workspace 4:FM; exec urxvtc -e mc'
}

i=0
ws4index=-1
for workspace in $(i3-msg -t get_workspaces | jq '.[] | .num'); do
    if [[ $workspace == 4 ]]; then
        ws4index=$i
        break;
    fi
    i=$((i+1))
done

mc_window_id=$(xdotool search --desktop $ws4index --name "^mc")
if [[ x$mc_window_id == "x" ]]; then
    new_mc_window
else
    i3-msg 'workspace 4:FM'
fi

