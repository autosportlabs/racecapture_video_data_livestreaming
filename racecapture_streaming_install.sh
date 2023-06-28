#!/bin/bash

# install dependencies
echo "Installing additional packages"
sudo apt-get -qq update
sudo apt-get -y -qq install mesa-utils libegl1-mesa mtdev-tools intel-media-va-driver-non-free curl v4l-utils tk gstreamer1.0-plugins-bad gstreamer1.0-libav gconf2 gnome-shell-extensions ratpoison

RC_APP_URL=`curl -s https://podium.live/software | grep -Po '(?<=<a href=")[^"]*racecapture_linux_x86_64[^"]*.deb'`
RC_APP_FILENAME=`basename $RC_APP_URL`
VSTREAMER_URL=`curl -s https://podium.live/software | grep -Po '(?<=<a href=")[^"]*video-streamer_linux_x86_64[^"]*.bz2'`
VSTREAMER_FILENAME=`basename $VSTREAMER_URL`

# enable access to RaceCapture USB and other /dev files
echo "Enabling access to system devices"
sudo adduser $USER dialout >/dev/null 2>&1
sudo adduser $USER render >/dev/null 2>&1
sudo adduser $USER video >/dev/null 2>&1
sudo adduser $USER input >/dev/null 2>&1
sudo echo "ATTRS{idVendor}==16d0, ATTRS{idProduct}==07f1, MODE=0666" | sudo tee /etc/udev/rules.d/70-autosportlabs.racecapture.rules >/dev/null 2>&1

# The commands below assume we're in $HOME so just change directories now
cd $HOME

# Download the RC app installer
echo "Installing RC App '$RC_APP_FILENAME'"
wget -q --show-progress -c "$RC_APP_URL"

# install RC app, with cleanup
sudo dpkg -i $RC_APP_FILENAME && rm $RC_APP_FILENAME

# Move the current vstreamer directory if it exists
if [ -d video-streamer ] ; then
  echo "Saving old video-streamer installation as video-streamer_old"
  rm -rf video-streamer_old
  mv video-streamer video-streamer_old
fi
echo "Installing Video Streamer App '$VSTREAMER_FILENAME'"
wget -q --show-progress -c "$VSTREAMER_URL" -O - | tar -xjp

if [ ! -f ~/Desktop/video-config.ini ] ; then
  echo "Adding default video-config.ini file for configuring streaming and recording settings"
  cat > ~/Desktop/video-config.ini <<'EOF'
[capture]
audio_device=1

[local_recording]
video_dir=$HOME/Videos

[streaming]
streaming_url=rtmp://a.rtmp.youtube.com/live2/<streaming key>
EOF
fi

echo "Configuring auto-start for racecapture and streaming"
cat > ~/.ratpoisonrc <<'EOF'
## Disable the message in the upper right
set startupmessage 0
## Force the cursor to the lower right when RC starts up
addhook newwindow banish

## Make it so that 'ctrl-t q' quits
bind q exec bash -c "killall -w -s SIGINT video-streamer; ratpoison -c quit"

## Set the cursor to the left pointer
exec xsetroot -cursor_name left_ptr

## Disable screen saver/blanking/etc
exec gsettings set org.gnome.desktop.session idle-delay 0
exec gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
exec gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
exec xset s off
exec xset s noblank
exec xset -dpms

## Start RC APP
exec /bin/bash -c 'cd /opt/racecapture && ./race_capture --size 1920x1080 >> ~/racecapture.log 2>&1' &

## Start the video capture/streaming
exec /bin/bash -c 'cd ~/video-streamer && ./start-video-streamer.sh -w 1 2>&1' &
EOF

sudo sh -c "cat > /usr/share/xsessions/racecapture.desktop <<'EOF'
[Desktop Entry]
Name=RaceCapture video+data streamer
Comment=This session logs you into Ratpoison
Exec=/usr/bin/ratpoison
TryExec=/usr/bin/ratpoison
Icon=
Type=Application
X-Ubuntu-Gettext-Domain=ratpoison-session
EOF
"

echo "Changing your window manager to single app mode"
sudo sed -i "s/Session=.*/Session=racecapture/g" /var/lib/AccountsService/users/$USER
