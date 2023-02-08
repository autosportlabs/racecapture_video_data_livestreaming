#TODO read settings from a config file:
# * Video output directory
# * youtube streaming key
VIDEO_OUTPUT=$HOME/Videos/video.mp4

# wait for desktop to settle
sleep 5

gst-launch-1.0 -v -e ximagesrc use-damage=0 \
  ! video/x-raw,framerate=30/1 \
  ! queue \
  ! videoconvert \
  ! videorate \
  ! queue \
  ! vaapih264enc \
  ! h264parse \
  ! queue \
  ! mp4mux name=mux \
  ! filesink location=$VIDEO_OUTPUT alsasrc device="hw:3,0" \
  ! queue \
  ! audioconvert \
  ! queue \
  ! lamemp3enc bitrate=192 \
  ! mux.
