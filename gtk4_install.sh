#!/bin/bash
set -u

# Desc: build gtk4+ sources
# platform: debian 12
# Date: 2024-7-19
#
# Note: 1. all steps must run in python virtual env
#       2. files are installed in /usr/local/etc
####################################################

# ---------- ------- version conf ------- ----------
glib=2.81.2  # must 2.76+
gtk4=4.15.3
# ---------- ------- ------------ ------- ----------

# python c
check_env() {
  python3 --version 1> /dev/null
  [ $? -eq 127 ] && exit

  local v=$(python3 --version | awk -F '.' {'print $2'})
  sudo apt install -y python3.$v-venv

  gcc --version 1> /dev/null
  if [ $? -eq 127 ]; then echo "Abort."; exit
  fi
}

# tools for building: meson, ninja, cmake
check_tools() {
  pip install meson ninja

  cmake --version 1> /dev/null
  [ $? -eq 127 ] && pip install cmake --upgrade

  pkg-config --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y pkg-config
}

# way A
download_pkg() {
  local v=4.15.3
  [ $# -eq 1 ] && v=$1

  local mirror=https://mirrors.nju.edu.cn/gnome
  sudo wget --no-verbose --no-clobber -P /opt \
    $mirror/sources/gtk/${v%.*}/gtk-$v.tar.xz

  if [ ! -d gtk ]; then mkdir gtk;
    tar --strip-components=1 -xJf /opt/gtk-$v.tar.xz -C ./gtk
  fi
}

# way B
download_repo() {
  local addr=https://github.com/GNOME/gtk.git
  local v=main
  [ $# -eq 1 ] && v=$1

  git --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y git

  sudo git clone --branch $v --depth 1 $addr
}

# default v2.74 not high enough, need v2.76+
install_glib() {
  local mirror=https://mirrors.nju.edu.cn/gnome
  sudo apt install -y libelf-dev libdbus-1-dev \
	  libpolkit-agent-1-dev libpolkit-gobject-1-dev \
	  libunwind-dev

  local v=2.81.1
  [ $# -eq 1 ] && v=$1

  sudo wget --no-verbose --no-clobber -P /opt \
    $mirror/sources/glib/${v%.*}/glib-$v.tar.xz  
  if [ ! -d glib-$v ]; then
    tar -xJf /opt/glib-$v.tar.xz -C .
  fi

  cd glib-$v
  local builddir=build-`date +%Y%m`
  meson setup $builddir --prefix /usr/local/etc/gtk

  cd $builddir
  meson compile
  meson install # input y if exist interactive

  sudo ln -sf -v /usr/local/etc/gtk/bin/* /usr/local/bin
  cd ../..
}

# PATH LD_LABRARY_PATH
addenv2path() {
  # export PATH=/usr/local/etc/gtk/bin:$PATH
  echo "export PATH=/usr/local/etc/gtk/bin:\$PATH" >> ~/.bashrc
  echo "export LD_LIBRARY_PATH=/usr/local/etc/gtk/lib/x86_64-linux-gnu/" >> ~/.bashrc
  \. ~/.bashrc
}

# ---------- ---------- ---------- ---------- ----------
if [ -d ~/Desktop ]; then cd ~/Desktop; else cd ~/桌面
fi

[ $# -eq 1 ] && gtk4=$1

gtk4-launch --version 1>/dev/null 2>&1
if [ $? -ne 127 ]; then
  vCurr=`gtk4-launch --version`
  if [ ${vCurr//./} -ge ${gtk4//./} ]; then
    echo "you may already have GTK installed on this system."
    gtk4-demo
  else
    op=0
    read -p "update gtk -> $gtk4? (default not) [Y/n] " op
    case $op in
      Y | y | 1) echo "start install gtk-$gtk4..."
        ;;
      *) echo "not update."; exit
    esac
  fi
fi

# ---------- ---------- ---------- ---------- ----------
check_env

# download_repo $gtk4
download_pkg $gtk4

# step1. start pip environment
python3 -m venv ./env4meson
\. ./env4meson/bin/activate
check_tools

# step2. subproject
[ `glib-compile-resources --version` == $glib ] && install_glib $glib

fribidi --version 1> /dev/null
[ $? -eq 127 ] && sudo apt install -y libfribidi-dev

pip install python-gettext
pip install gi-docgen --upgrade
pip install docutils
pip install fonttools

# ---------- ---------- Runtime dependency ---------- ----------
sudo apt install -y gettext                # msgfmt
sudo apt install -y libpango-1.*           # pango
sudo apt install -y libharfbuzz-dev        # pango
sudo apt install -y libgirepository1.0-dev # graphene-gobject
sudo apt install -y libepoxy-dev           # OpenGL
sudo apt install -y libcairo2-dev          # 2D graphics
sudo apt install -y libxkbcommon-x11-dev   # keyboard state
sudo apt install -y libxml2-utils          # xmllint
sudo apt install -y libtiff5-dev
sudo apt install -y librsvg2-dev

# x11-backend
sudo apt install -y libxrandr-dev libxi-dev \
       libxinerama-dev libxcursor-dev libxdamage-dev
sudo apt install -y libdrm-dev

# doc language
sudo apt install -y libthai-dev help2man

# ---------- ---------- ---------- ---------- ----------
# step3. configure and compile with meson 
cd gtk
du -sh .

# meson configure
# apt install wayland-*, it's version not enough
builddir=build-`date +%Y%m`
meson setup $builddir --prefix /usr/local/etc/gtk \
  -Dmedia-gstreamer=disabled \
  -Dwayland-backend=false \
  -Dvulkan=disabled 

cd $builddir
meson compile
meson install # input y if exist interactive

# step4. update env
addenv2path

deactivate # close python virtual env

