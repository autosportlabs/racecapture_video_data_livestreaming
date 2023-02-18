#!/bin/bash
####################################################
#TODO read settings from a config file:
AUDIO_DEVICE=hw:3,0
MAX_TIME_SEC=60
####################################################

MAX_SIZE_TIME=$(($MAX_TIME_SEC*1000000000))
N=1

function setDirname()
{
    local CURRENT_DATE=$(date +"%Y-%m-%d")
    VIDEOS_DIR=~/Videos/${CURRENT_DATE}-${N}
}

setDirname
while [[ -d "${VIDEOS_DIR}" ]] ; do
    N=$(($N+1))
    setDirname
done

mkdir -p ${VIDEOS_DIR}
VIDEO_OUTPUT=$VIDEOS_DIR/video%05d.mp4

# wait for desktop to settle
sleep 4

gst-launch-1.0 -e splitmuxsink name=mux location=$VIDEO_OUTPUT max-size-time=$MAX_SIZE_TIME \
        ximagesrc use-damage=0 \
        ! 'video/x-raw,framerate=30/1' \
        ! queue \
        ! videoconvert \
        ! vaapih264enc \
        ! h264parse \
        ! mux.video \
        alsasrc device=$AUDIO_DEVICE \
        ! queue \
        ! audioconvert \
        ! voaacenc \
        ! mux.audio_0
