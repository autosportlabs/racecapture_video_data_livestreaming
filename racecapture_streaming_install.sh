#!/bin/bash

RC_APP_URL=`curl -s https://podium.live/software | grep -Po '(?<=<a href=")[^"]*racecapture_linux_x86_64[^"]*.bz2'`
RC_APP_FILENAME=`basename $RC_APP_URL`

# install dependencies
echo "Installing additional packages"
sudo apt-get -qq update
sudo apt-get -y -qq install v4l-utils tk gstreamer1.0-plugins-bad gstreamer1.0-libav gconf2 gnome-shell-extensions ratpoison

# enable access to RaceCapture USB and other /dev files
echo "Enabling access to system devices"
sudo adduser $USER dialout >/dev/null 2>&1
sudo adduser $USER render >/dev/null 2>&1
sudo adduser $USER video >/dev/null 2>&1
sudo adduser $USER input >/dev/null 2>&1
sudo echo "ATTRS{idVendor}==16d0, ATTRS{idProduct}==07f1, MODE=0666" | sudo tee /etc/udev/rules.d/70-autosportlabs.racecapture.rules >/dev/null 2>&1

# The commands below assume we're in $HOME so just change directories now
cd $HOME

# Move the current RC directory if it exists
if [ -d racecapture ] ; then
  echo "Saving old racecapture installation as racecapture_old"
  rm -rf racecapture_old
  mv racecapture racecapture_old
fi

# Download and decompress the RC App bundle
echo "Installing RC App '$RC_APP_FILENAME'"
wget -q --show-progress -c "$RC_APP_URL" -O - | tar -xjp

echo "Download livestreaming scripts"
mkdir -p $HOME/streamer
pushd .
cd $HOME/streamer
wget -q -O streamer.sh https://raw.githubusercontent.com/autosportlabs/racecapture_video_data_livestreaming/main/streamer.sh
chmod +x streamer.sh
popd

echo "Configuring auto-start for racecapture and streaming"
cat > ~/.ratpoisonrc <<'EOF'
## Disable the message in the upper right
set startupmessage 0
## Force the cursor to the lower right when RC starts up
addhook newwindow banish

## Make it so that 'ctrl-t q' quits
bind q exec bash -c "killall -w -s SIGINT video-streamer && ratpoison -c quit"

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
exec /bin/bash -c 'cd ~/racecapture && LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ./race_capture >> ~/racecapture.log 2>&1'

## Start the video capture/streaming
exec $HOME/streamer/streamer.sh >> ~/streamer.log 2>&1
EOF

echo "Changing your window manager to single app mode"
sudo sed -i "s/Session=.*/Session=ratpoison/g" /var/lib/AccountsService/users/$USER
