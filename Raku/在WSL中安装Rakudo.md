## 开启 Windows 虚拟化

```bash
bcdedit /set hypervisorlaunchtype auto
```

然后使用 `shutdown /r` 重启计算机。

## 设置代理

在 Clash 客户端中打开 Allow LAN。

在 `~/.bashrc` 中添加如下配置:

```bash
host_ip=$(cat /etc/resolv.conf | grep nameserver | cut -f 2 -d " ") # 如果是局域网内的服务器, 则把 host_ip 设置为 Windows 主机的 IP 地址
# 或使用 windows 局域网的 IP(以太网适配器 以太网)
alias set_proxy="export https_proxy=http://$host_ip:7890;export http_proxy=http://$host_ip:7890;export all_proxy=socks5://$host_ip:7890"
alias unset_proxy="unset https_proxy;unset http_proxy;unset all_proxy"
```

然后使配置生效: `source ~/.bashrc`。

## 安装依赖

```bash
sudo apt-get update
sudo apt-get install liblocal-lib-perl cpanminus build-essential git curl vim
```

## 方法一) 编译安装

```bash
wget -c --no-check-certificate https://github.com/rakudo/rakudo/releases/download/2021.12/rakudo-2021.12.tar.gz
# or
git clone https://github.com/rakudo/rakudo.git
sudo tar -zxvf rakudo-2021.12.tar.gz
cd rakudo
sudo perl Configure.pl --git-protocol=https --gen-moar --gen-nqp --backends=moar --prefix=/opt/rakudo
```

安装完毕把 raku 添加到 PATH 中。

## 方法二) 安装 rakudo-pkg

安装 Rakudo:

```bash
curl -1sLf 'https://dl.cloudsmith.io/public/nxadm-pkgs/rakudo-pkg/setup.deb.sh' | sudo -E bash
sudo apt-get info rakudo-pkg
```

设置环境变量:

```bash
export RAKU_PKG_HOME=/opt/rakudo-pkg/
export PATH=$PATH:$RAKU_PKG_HOME/bin:~/.raku/bin
```

`source ~/.bashrc`。

执行如下脚本, 让 `libmoar.so` 在 Win10 上能够工作:

```bash
sh /opt/rakudo-pkg/bin/fix-windows10
```

安装 zef:

```bash
sh /opt/rakudo-pkg/bin/install-zef
```

安装 Linenoise 模块:

```bash
zef install Linenoise
```