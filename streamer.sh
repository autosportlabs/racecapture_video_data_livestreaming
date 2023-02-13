#TODO read settings from a config file:
# * Video output directory
# * youtube streaming key
VIDEO_OUTPUT=$HOME/Videos/video%05d.mp4
AUDIO_DEVICE=hw:4,0

# wait for desktop to settle
sleep 0

gst-launch-1.0 -e splitmuxsink name=mux location=$VIDEO_OUTPUT max-size-bytes=2147483648 \
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
