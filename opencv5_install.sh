#!/bin/bash
set -u

# Desc: build opencv from sources
# Platform: debian 12
# Date: 2024-08-25
#
####################################################

# --------- ---------- version ---------- ----------
opencv='5.x'
tag='5.x'

builddir=opencv-build-`date +%Y%m`
installdir=/usr/local/etc/opencv
# --------- ---------- ------- ---------- ----------

check_tools() {
  git --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y git

  wget --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y wget

  pip install ninja
  pip install cmake # --upgrade
}

# $1 all repos have same version
download_repo() {
  local v=master
  [ ${tag%.*} -eq 5 ] && v=$tag

  while [ $# != 0 ]; do
    local reponame=$1 # change every time

    test -d $reponame-$v && continue

    # 优先看本地有没有现成的压缩包
    if [ -f /opt/$reponame-$v.zip ]; then
      sudo unzip -q /opt/$reponame-$v.zip -d .
    else
      sudo env PATH=$PATH git clone --branch $v --depth 1 \
        https://github.com/opencv/$reponame.git $reponame-$v
      git config --add safe.directory `pwd`/$reponame
    fi

    sudo chmod 777 -R $reponame-$v

    shift # $# reduce 1
  done
}

config_opencv() {
  ffmpeg -version
  if [ $? -eq 127 ]; then bash ffmpeg5_install.sh
    exit
  fi

  export OPENCV_DOWNLOAD_PATH=/tmp/opencv-cache
  cmake -GNinja ../opencv-$tag \
       -D CMAKE_BUILD_TYPE=Release \
       -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-$tag/modules \
       -D OPENCV_GENERATE_PKGCONFIG=ON \
       -D CMAKE_INSTALL_PREFIX=$installdir
}

addenv2path() {
  local path_cfg=/etc/ld.so.conf.d/opencv5.conf
  if [ $(grep -c '$installdir/lib') -eq 0 ]; then
    echo "$installdir/lib" | sudo tee -a $path_cfg
  fi
  sudo ldconfig

  local pc=$installdir/lib/pkgconfig
  if [ $(grep -cn '$pc' ~/.bashrc) -eq 0 ]; then
    echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$pc" |\
      sudo tee -a ~/.bashrc
  fi
  \. ~/.bashrc
}

# --------- ---------- ---------- ----------
if test -d ~/Desktop; then cd ~/Desktop; else
  cd $HOME
fi

python3 -m venv ./env4opencv
\. ./env4opencv/bin/activate
check_tools

arr_repo=(
  opencv
  opencv_contrib
)

download_repo ${arr_repo[*]}

mkdir -p $builddir
cd $builddir

config_opencv
cmake --build .
ninja install
addenv2path

deactivate
