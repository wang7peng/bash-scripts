#!/bin/bash
set -u

# Desc: build qt6+ sources
# platform: debian 12
# Date: 2024-8-28
#
##################################################

qt6=6.7.2  # must 6.5+

# tools for building: cmake
check_tools() {
  cmake --version 1> /dev/null
  [ $? -eq 127 ] && pip install cmake --upgrade

  gcc --version 1> /dev/null
  if [ $? -eq 127 ]; then
    echo "Abort."; deactivate; exit
  fi

  # QtWebEngine need bison gperf ninja
  sudo apt install -y \
    bison flex gperf libnss3-dev
  pip install ninja
}

# 900M+
download_pkg() {
  local v=6.7.2
  [ $# -eq 1 ] && v=$1

  local pkg=qt-everywhere-src-$v.tar.xz
  local mirror=https://mirror.nju.edu.cn/qt
  # e.g xxx/6.7/6.7.2/single/qt-everywhere-src-6.7.2.tar.gz
  sudo wget --no-verbose --no-clobber -P /opt \
    $mirror/official_releases/qt/${v%.*}/$v/single/$pkg

  if [ ! -d /usr/local/src/${pkg%.tar*} ]; then 
    sudo tar -xJf /opt/$pkg -C /usr/local/src
  fi

  # cmake need authorisation of it
  sudo chmod 777 -R /usr/local/src/${pkg%.tar*}
}

addenv2path() {
  PATH=/usr/local/etc/qt/bin:$PATH

  export PATH
}

# ---------- ---------- ---------- ----------
cd ~/Desktop
download_pkg $qt6

python3 -m venv ./env4qt
\. ./env4qt/bin/activate
check_tools

pip install html5lib  # QtWebEngine

builddir=qt-build-`date +%Y%m`
mkdir -p $builddir
cd $builddir

sudo mkdir -p /usr/local/etc/qt
sudo chmod 777 -R /usr/local/etc/qt

# reference: doc.qt.io/qt-6/configure-options.html
/usr/local/src/qt-everywhere-src-*/configure \
  -prefix /usr/local/etc/qt \
  -skip qtwayland

cmake --build . --parallel
cmake --install .

addenv2path

