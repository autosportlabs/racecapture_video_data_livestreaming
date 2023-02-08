#!/bin/bash
RACECAPTURE_DOWNLOAD=https://www.dropbox.com/s/7gvbzsfdb9hllzb/racecapture_linux_x86_64_2.8.0.tar.bz2?dl=1

# install dependencies
echo Installing additional packages
sudo apt-get -qq update
sudo apt-get -y -qq install v4l-utils tk gstreamer1.0-plugins-bad gstreamer1.0-libav gconf2 gnome-shell-extensions ratpoison

# enable access to RaceCapture USB connection
echo Enabling access to USB
sudo adduser $USER dialout >/dev/null 2>&1
sudo echo "ATTRS{idVendor}==16d0, ATTRS{idProduct}==07f1, MODE=0666" | sudo tee /etc/udev/rules.d/70-autosportlabs.racecapture.rules >/dev/null 2>&1

echo Saving old racecapture installation as racecapture_old
cd $HOME
rm -rf racecapture_old
[ -d racecapture ] && mv racecapture racecapture_old

echo Downloading latest racecapture
# download RaceCapture
wget -q --show-progress -c $RACECAPTURE_DOWNLOAD -O - | tar -xjp

echo Configuring auto-start for racecapture and streaming
{
        echo "exec /bin/bash -c 'cd ~/racecapture && ./run_racecapture_linux.sh >> ~/racecapture.log'"
        echo "exec  
} > ~/.ratpoisonrc

echo Changing your window manager to single app mode
sudo sed -i "s/Session=.*/Session=ratpoison/g" /var/lib/AccountsService/users/$USER

