# 在 WSL 中安装 Python3.9.12

```shell
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
wget https://www.python.org/ftp/python/3.9.12/Python-3.9.12.tgz
sudo tar -xzf Python-3.9.12.tgz

cd Python-3.9.12
sudo ./configure --enable-optimizations
sudo make -j 2
sudo make install
/usr/local/bin/python3.9 -m pip install --upgrade pip
```

# 在 CentOS 7 上安装 Python3.9.12

```shell
sudo yum -y install epel-release
sudo yum -y update
sudo yum groupinstall "Development Tools" -y
sudo reboot

sudo yum groupinstall "Development Tools" -y
sudo yum install openssl-devel libffi-devel bzip2-devel -y

gcc --version
sudo yum install wget -y
wget https://www.python.org/ftp/python/3.9.12/Python-3.9.12.tgz
tar xvf Python-3.9.12.tgz
cd Python-3.9.12
sudo ./configure --enable-optimizations
sudo make install
/usr/local/bin/python3.9 -m pip install --upgrade pip
```

# 安装 apache-flink

安装 apache-flink 1.15 各种安装不上, 里面编译很多东西, 报错。
原因是因为使用了 Python 版本比较高, 3.9.12， 而 apache-flink (1.15)现在支持到了 python3.8, 所以 Python 3.9 尚未得到支持。
解决办法是安装 3.8 版本的 Python。但是下面这条安装命令仅仅在 Linux 上安装成功了，在 Windows 上会用为编译安装 pemja 这个包而失败!

```shell
pip install apache-flink
```

# 运行 PyFlink 任务

在 WSL(Debian 10) 中通过安装 2020.07 月份的 Anaconda, 来安装 Python 3.8.3。

```shell
sudo sh Anaconda3-2020.07-Linux-x86_64.sh
sudo apt-get install lsof
sudo apt install openssh-server
sudo service ssh start
sudo chown -R sxw:sxw /opt/scripts/Python

conda create -n flinkenv python=3.8.3
conda activate flinkenv
```

启动本地的 Kafka Docker 镜像, 运行 PyFlink 任务:

```shell
python json_format.py
```

测试了发送和读写 Kafka 都是正常的。在 Windows 上开发就是老六。