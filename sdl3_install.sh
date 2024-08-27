#!/bin/bash
set -u

# Desc: build sdl2+ sources
# platform: debian 12
# Date: 2024-7-25
#
# Note: 
####################################################

builddir=build-`date +%Y%m`
prefix=/usr/local/etc/sdl
# ---------- ---------- ---------- ---------

check_tools() {
  gcc --version 1> /dev/null
  [ $? -eq 127 ] && exit

  pkg-config --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y pkg-config

  pip install cmake
}

# 55M
download_repo() {
  local v=main
  [ $# -eq 1 ] && v=$1

  test -d SDL && return
  git --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y git

  repo=https://github.com/libsdl-org/SDL.git
  sudo env PATH=$PATH \
    git clone --branch $v --depth 1 --single-branch $repo
}

# module need
#       alsa-lib  v1.2.8+ , in libasound2-dev
#       jack      v1.9.21+
#       pipewire  v0.3.65+
#       libpulse  v0.9.15+
#       libsndio  v1.9.0+
#       libusb    v1.0.26+
install_dependency() {
  sudo apt install -y \
    libasound2-dev libjack-jackd2-dev \
    libpipewire-0.3-dev libpulse-dev \
    libsndio-dev libusb-1.0-0-dev

  sudo apt autoremove -y
}

# usage:
# export PKG_CONFIG_PATH=/usr/local/etc/sdl/lib/pkgconfig
addenv2path() {
  local f=$HOME/.bashrc
  local pc=$prefix/lib/pkgconfig

  if [ $(grep -cn "$pc" $f) -eq 0 ]; then
    echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$pc" | sudo tee -a $f
    \. $f
  fi

  # test
  local v_pkg=PKG_CONFIG_PATH
  eval echo '$'$v_pkg | tr ':' '\n'
  pkg-config --cflags sdl3
}

# ---------- ---------- ---------- ---------- ----------
pkg-config --modversion sdl3 2> /dev/null
test $? -ne 1 && exit

if test -d ~/Desktop; then cd ~/Desktop; else
  cd $HOME
fi

# step1 start pip environment
python3 -m venv env4cmake
\. ./env4cmake/bin/activate
check_tools

# step2 sources
download_repo 
install_dependency

# step3 configure and build
cmake -S ./SDL -B $builddir \
    -DSDL_EXAMPLES=ON \
    -DSDL_WAYLAND=OFF \
    -DSDL_STATIC=ON

cmake --build $builddir 

[ -d $prefix ] && sudo rm -r $prefix
sudo mkdir -p $prefix
sudo chmod 777 -R $prefix

# step4 install
cmake --install $builddir --prefix=$prefix
addenv2path

deactivate # close python virtual env

