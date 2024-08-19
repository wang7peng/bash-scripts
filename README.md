# Linux 脚本

![Debian](https://img.shields.io/badge/Debian-12.6+-E95420?style=social&logo=debian)

- 各个库的版本在文件开头可以配置
- 安装位置优先在 `/usr/local/etc`

## 使用

系统中可能没有 cmake，可以用 apt 安装或用 pip 安装最新版。

``` sh
# way1
sudo apt install -y cmake

# way2
python3 -m venv ./env4app
. ./env4app/bin/activate
pip install cmake --upgrade
```

然后再跑脚本 `bash xxx.sh`。
