#TODO read settings from a config file:
# * Video output directory
# * youtube streaming key
VIDEO_OUTPUT=$HOME/Videos/video%05d.mp4

# wait for desktop to settle
sleep 0

gst-launch-1.0 -v -e ximagesrc use-damage=0 \
  ! video/x-raw,framerate=30/1 \
  ! queue \
  ! videoconvert \
  ! videorate \
  ! queue \
  ! vaapih264enc \
  ! h264parse \
  ! mux. alsasrc device=hw:3,0 \
  ! queue \
  ! audioconvert \
  ! voaacenc \
  ! mux. mp4mux name=mux \
  ! filesink location=$VIDEO_OUTPUT

