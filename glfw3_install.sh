#!/bin/bash
set -u

# Desc: setup opengl env in linux
# platform: ubuntu24
#
# Note: build glfw3, download glad

# ---------- config ----------
glfw=3.4

builddir=glfw-build-`date +%Y`
installdir=/usr/local/etc/glfw
# ----------------------------

check_env() {
  gcc --version 1>/dev/null 2>&1
  if [ $? -eq 127 ]; then echo "Abort."; exit
  fi

  cmake --version 1> /dev/null
  if [ $? -eq 127 ]; then exit
  fi

  pkg-config --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y pkgconf

  # ldconfig maybe not found, though it is in /usr/sbin
  ldconfig --version 2> /dev/null
  [ $? -eq 127 ] && export PATH=$PATH:/usr/sbin
}

show_version() {
  if [ $1 == 'opengl' ]; then
    glxinfo 1> /dev/null
    [ $? -eq 127 ] && sudo apt install -y mesa-utils

    glxinfo | grep -i "opengl version" | awk '{print $1, $4}'
  fi
}

# clone repo of glfw from github
download_repo() {
  local v=3.4
  [ $# -eq 1 ] && v=$1

  if [ ! -d glfw ]; then
    git clone --depth 1 --branch $v \
      https://github.com/glfw/glfw.git
  else
    tree -C -L 1 glfw
    local op=0
    read -p "Repo already exists, update? (default not) [Y/n] " op
    case $op in
      Y | y | 1) sudo rm -rf glfw;
        download_repo $v ;;
      *) 
    esac
  fi
}

config_glfw() {
  local op_w=0
  local op_x=0

  if [ $XDG_SESSION_TYPE == "wayland" ]; then
    op_w=1
    sudo apt install -y libwayland-dev libxkbcommon-dev
  else
    op_x=1
    sudo apt install -y xorg-dev 
  fi

  # 两个窗口系统必须用1个 不能全关
  cmake -S ./glfw -B $builddir \
    -D CMAKE_INSTALL_PREFIX=${installdir} \
    -D GLFW_BUILD_DOCS=OFF \
    -D GLFW_BUILD_TESTS=OFF \
    -D GLFW_BUILD_WAYLAND=$op_w \
    -D GLFW_BUILD_X11=$op_x \
    -D BUILD_SHARED_LIBS=ON
}

addenv2path() {
  local path_cfg=/etc/ld.so.conf.d/glfw.conf
  if [ ! -f $path_cfg ]; then
    echo "${installdir}/lib" | sudo tee -a $path_cfg
  fi
  sudo ldconfig

  # pkg-config
  local pc_glfw=$installdir/lib/pkgconfig
  if [ $(grep -cn '$pc_glfw' ~/.bashrc) -eq 0 ]; then
    echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$pc_glfw" |\
      sudo tee -a ~/.bashrc
    \. ~/.bashrc
  fi

  pkg-config --cflags glfw3
}

main_glfw() {
  download_repo $glfw
  config_glfw

  cd $builddir
  cmake --build . # = make
  sudo make install
  addenv2path
}

# ---------- main ----------
cd ~/Desktop
check_env

ldconfig -p | grep glfw.so
if [ $? -eq 1 ]; then
  main_glfw
else
  echo -n "check glfw pkg config: "
  pkg-config --cflags glfw3
fi

# ----------------------------
# maybe exist qt source, it have glad dir
total=$(find /usr/local -name glad ! -path "/usr/local/src/qt*" | wc -l)
if (( $total == 0 )); then
  echo -n "glad 必须从网页下载, 并且你需要挑选: "
  show_version opengl
else
  echo -n "glad in "
  find /usr/local/ -name glad.h
fi

