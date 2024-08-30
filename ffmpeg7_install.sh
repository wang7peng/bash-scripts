#!/bin/bash
set -u

# Desc: build ffmpeg sources v7.0+
# platform: Debian 12
# 
# Note: not use cmake

# ---------- ----- config ----- ----------
ffmpeg=7.0.2

installdir=/usr/local/etc/ffmpeg
# ----------------------------------------

check_env() {
  gcc --version 1> /dev/null
  if [ $? -eq 127 ]; then echo "Abort."; exit
  fi

  # if in centOS
  if cat /proc/version | grep -q -E -i "red hat"; then
    sudo yum install -y pkgconfig yasm
    return
  fi

  yasm --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y yasm

  pkg-config --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y pkgconf
}

download_repo() {
  local v=${ffmpeg%.*}
  [ ${#v} -eq 1 ] && v=$v.0

  if [ ! -d ffmpeg ]; then
    git clone --depth 2 --branch release/$v \
      https://git.ffmpeg.org/ffmpeg.git ffmpeg
  fi
}

addenv2path() {
  # app in bin/ need xxx.so
  if [ $(grep -cn '$installdir/lib' ~/.bashrc) -eq 0 ]; then
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$installdir/lib" |\
    sudo tee -a ~/.bashrc
    \. ~/.bashrc
  fi

  # link exe {ffmpeg ffprobe} to $PATH
  linkdir=/usr/local/bin
  sudo ln -sf -v $installdir/bin/ff* $linkdir
  # check PATH exist it and it is sort in front of /usr/bin
  test $(echo $PATH | tr ':' '\n' | grep -cn $linkdir) -eq 0 &&
    echo "export PATH=$linkdir:\$PATH" | sudo tee -a ~/.bashrc

  # pkg-config
  local pc_ffmpeg=$installdir/lib/pkgconfig
  if [ $(grep -cn '$pc_ffmpeg' ~/.bashrc) -eq 0 ]; then
    echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$pc_ffmpeg" |\
      sudo tee -a ~/.bashrc
    \. ~/.bashrc
  fi

  # need open a new terminal to take effect
  pkg-config --cflags libavcodec
}

main() {
  check_env
  download_repo

  cd ffmpeg
  ./configure --prefix=$installdir \
	--disable-doc \
	--enable-shared

  make
  sudo make install
  addenv2path
}

# ---------- main ----------
if [ -d ~/Desktop ]; then cd ~/Desktop; else
  cd $HOME
fi

ffmpeg -version 2> /dev/null
if [ $? -ne 127 ]; then
  op=0
  read -p "update version -> $ffmpeg? (default not) [Y/n] " op
  case $op in
    Y | y | 1)
      ;;
    *) echo -n "not update, check pkg config: "
      pkg-config --cflags libavcodec
      exit
  esac
fi

main
# test when install finished
ffmpeg -version
