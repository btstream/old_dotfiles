#!/bin/bash

xsession_tmpfile=$(mktemp --suffix="-xsession")
if [[ -d $HOME/.Xresources.d/ ]]; then
    for i in $HOME/.Xresources.d/*; do
        if [[ -e $i ]]; then
            echo "load X resource $i" >> $xsession_tmpfile
            xrdb -merge $i >> $xsession_tmpfile 2>&1
        fi
    done
fi

