#!/bin/bash
set -u

# Desc: build latest gcc from source
# platform: debian
#
##############################################

gcc=14.3.0

installdir=/usr/local/etc/gcc
# --------------------------------------------
[ $# -eq 1 ] && gcc=$1

check_tools() {
  make --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y make

  cc --version 1> /dev/null
  [ $? -eq 127 ] && sudo apt install -y gcc g++

  ldconfig 2> /dev/null
  [ $? -eq 127 ] && export PATH=$PATH:/usr/sbin
}

# deprecate
install_gmp() {
  m4 --version 1> /dev/null
  [$? -eq 127 ] && sudo apt install -y m4

  local v=6.3.0
  local pkg=gmp-$v.tar.xz
  sudo wget --no-clobber -P /opt \
    https://mirror.nju.edu.cn/gnu/gmp/$pkg

  if [ ! -d /usr/local/src/${pkg%.tar*} ]; then
    sudo tar -xJf /opt/$pkg -C /usr/local/src
  fi

  sudo chmod 777 -R /usr/local/src/${pkg%.tar*} 
  cd /usr/local/src/${pkg%.tar*}
  # setup 3 folders:include lib share/info
  ./configure \
    --includedir=/usr/local/include \
    --libdir=/usr/local/lib/gmp-${v%%.*} \
    --datarootdir=/usr/local/share

  sudo make -j`nproc`
  sudo make install
  # sudo make check  
}

# need gmp mpfr mpc
check_envs() {
  # when install mpc will auto install gmp and mpfr
  sudo apt install -y libmpc-dev \
    texinfo libisl-dev

  #find /usr/local/lib/ | grep libgmpp 1>/dev/null
  #[ $? -eq 1 ] && install_gmp
}

download_pkg() {
  local v=14.2.0
  [ $# -eq 1 ] && v=$1
  local pkg=gcc-$v.tar.xz # 88M

  sudo wget --no-clobber -P /opt \
    https://mirror.nju.edu.cn/gnu/gcc/gcc-$v/$pkg

  if [ ! -d /usr/local/src/${pkg%.tar*} ]; then
    sudo tar -xJf /opt/$pkg -C /usr/local/src
  fi
  sudo chmod -R 777 /usr/local/src/${pkg%.tar*}
}

config_gcc() {
  check_envs
  cd /usr/local/src/gcc-$gcc
  du -sh .

  ./configure -q --prefix=$installdir \
    --build=x86_64-linux-gnu \
    --enable-threads=posix \
    --enable-checking=release \
    --enable-languages=c,c++ \
    --disable-multilib
}

# link
addenv2path() {
  sudo ln -sf -v $installdir/bin/gcc /usr/local/bin/gcc
  sudo ln -sf -v $installdir/bin/g++ /usr/local/bin/g++
}

# ----------------------------------------------
if test -d ~/Desktop; then cd ~/Desktop; else
  cd $HOME
fi

# not to update when current gcc has v12+
verCurr=$(gcc --version | head -n 1 | awk '{print $NF}')
[ ${verCurr%%.*} -ge 12 ] && exit

# if previous data still exist
if [ -d $installdir/bin ]; then
  verNow=`$installdir/bin/gcc -dumpfullversion`

  # compare number without dot, e.g 1420 vs 1240
  if test ${verNow//./} -ge ${gcc//./}; then addenv2path; exit
  else
    echo "gcc $verNow not enough, start install $gcc..."
  fi
fi

# ---------- main ----------
check_tools
download_pkg $gcc

config_gcc
make -j`nproc` 
sudo make install
addenv2path

