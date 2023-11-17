#show link: underline

= 本地/内网文件共享服务搭建方法

1. 下载 #link("https://github.com/svenstaro/miniserve")[miniserve] 到 /usr/local/bin 目录。
2. 创建系统服务。

在 /etc/systemd/system 目录下新建一个名为 miniserve.service 的文件, 内容如下:

```sh
[Unit]
Description=miniserve
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
ExecStart=/usr/local/bin/miniserve \
  --enable-tar \
  --enable-zip \
  --no-symlinks \
  --verbose \
  -p 3333 \
  -o \
  -a username:password \
  --title 通用软件仓库 \
  -F \
  --mkdir -u -- /data/software

IPAccounting=yes
IPAddressAllow=localhost
IPAddressDeny=any
PrivateTmp=yes
PrivateDevices=yes
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_DAC_READ_SEARCH

[Install]
WantedBy=multi-user.target
```

3. 启用服务

```sh
systemctl enable miniserve
```

4. 启用服务

```sh
systemctl start miniserve
```

5. 查看服务状态

```sh
systemctl status miniserve
```

打开浏览器, 访问 #link("http://127.0.0.1:3333")[http://127.0.0.1:3333]
