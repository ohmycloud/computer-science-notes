#import("circuedoc_template.typ"): conf

#show: doc => conf(
    title: "使用 Docker 部署 FastAPI 程序",
    author: "ohmycloud",
    date: datetime.today().display(),
    description: "Web 版",
    doc,
)

= docker 安装

```bash
# 下载 docker-compose 到 /usr/local/bin/
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo -su iot_api
sudo docker network create docker_default
sudo docker-compose --compatibility up -d
```

= 编写 Dockerfile

```yaml
FROM python:3.11

MAINTAINER circue
ENV TZ=Asia/Shanghai \
       DEBIAN_FRONTEND=noninteractive

WORKDIR /app

COPY requirements.txt /app

RUN mkdir -p /etc/apt
RUN touch /etc/apt/sources.list
RUN echo > /etc/apt/sources.list

# 更新apt-get源
RUN echo deb https://mirrors.aliyun.com/debian/ bullseye main contrib non-free  >> /etc/apt/sources.list
RUN echo deb-src https://mirrors.aliyun.com/debian/ bullseye main contrib non-free  >> /etc/apt/sources.list
RUN echo deb https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free  >> /etc/apt/sources.list
RUN echo deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free  >> /etc/apt/sources.list
RUN echo deb https://mirrors.aliyun.com/debian/ bullseye-backports main contrib non-free  >> /etc/apt/sources.list
RUN echo deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main contrib non-free  >> /etc/apt/sources.list
RUN echo deb https://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free  >> /etc/apt/sources.list
RUN echo deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free  >> /etc/apt/sources.list

RUN apt-get clean && apt-get update && apt-get -y install net-tools
RUN pip install --upgrade pip && pip install -i https://mirrors.aliyun.com/pypi/simple --no-cache-dir -r /app/requirements.txt
RUN pip install http://pypi.circue.tech/bigdata/datahouse/+f/463/f0bf0ec13d546/esc_app-0.3.42-py3-none-any.whl#sha256=463f0bf0ec13d54667b9d33643eef22334e31c67036e0f591ed65ab15db39f52

COPY ./ /app

WORKDIR /app/src/iot_api
CMD ["python", "main.py"]
```

更换 Debian 系统的源，更换 pip 的安装源。

= 编写 docker-compose.yml

```yaml
version: '3'
services:
  iot-api:
    build:
      context: ./
      dockerfile: ./Dockerfile
    image: circue/iot-api
    container_name: iot-api
    networks:
      docker_default:
        aliases:
          - iot-api

    ports:
      - "10217:10217"
    volumes:
      - /data/log:/log
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G

networks:
  default:
    external:
      name: docker_default
  docker_default:
    external: true
```
