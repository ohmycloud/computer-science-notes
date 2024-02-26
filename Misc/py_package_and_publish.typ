#import("doctemplate.typ"): conf

#show link: underline
#show "pyproject.toml": it => text(red)[#it]

#show: doc => conf(
    title: "Python 模块打包和发布指南",
    author: "ohmycloud",
    date: datetime.today().display(),
    description: "Rye Vs Poetry Vs PDM",
    doc,
)

= pypi 私有服务搭建

搭建 PYPI 私服, 便于 Python 模块/命令行工具的分享, 积累通用工具类和通用模块, 强化基础设施建设。

== 软件安装

在服务器端执行如下命令安装 PYPI 服务所需的依赖模块:

```bash
pip install pypiserver
pip install passlib
```

== 账号配置

在服务器端, 在数据盘上某个目录下创建一个名为 #text(red)[packages] 的目录用于存放打包命令上传的 #text(red)[.tar.gz] 和 #text(red)[.whl] 文件。使用 `htpasswd` 命令创建 PYPI 服务的用户名和密码:

```bash  
cd /mnt/data1/ && mkdir packages
htpasswd -c ~/.pypipaswd pypi
```

这会创建一个名为 #text(red)[pypi] 的用户, 在创建用户时会提示你输入这个用户的密码。

== 启动服务

在服务器端使用 pypi-server run 命令启动私有 PYPI 仓库:

```bash
nohup pypi-server run -P ~/.pypipasswd -p 8099 --fallback-url https://mirrors.aliyun.com/pypi/simple/ packages &
```

其中:

- #text(red)[-P] 指定密码文件为上面创建的 ~/.pypipasswd。
- #text(red)[-p] 指定监听端口为 8099。
- #text(red)[--fallback-url] 指定当在私有仓库找不到所需依赖模块时去该地址进行安装。
- #text(red)[packages] 是上面所创建的存储依赖文件的目录。

= nexus 私有服务搭建

== 软件安装

下载 nexus 压缩模块, 解压 到 /usr/local 目录:

```bash
tar -xvf nexus-3.53.0-01-unix.tar.gz -C /usr/local/
```

创建软链接:

```bash
ln -s /usr/local/nexus-3.53.0-01/ /usr/local/nexus
ln -s /usr/local/nexus/bin/nexus /usr/bin/
```

== 配置文件

```bash
cd /usr/local/nexus
vi bin/nexus.rc
vi etc/nexus-default.properties
vi bin/nexus.vmoptions
```

== 设置服务

```bash
vi /lib/systemd/system/nexus.service
systemctl daemon-reload
systemctl enable --now nexus.service
ss -ntlp | grep 3333
```

查看密码:

```bash
cat /usr/local/sonatype-work/nexus3/admin.password
```

浏览器打开: #link("http://127.0.0.1:3333")[http://127.0.0.1:3333] 输入 admin 的密码, 修改新的密码。

然后执行如下3个步骤配置仓库:

1) 创建 blob storage：

#image("blob_storages.png")

2) 创建新的仓库：hosted-pypi, proxy-pypi, group-pypi。

#image("repository.png")

3) 创建 nexus 用户：

#image("user.png")

设置用户名和密码, 后面上传 wheel 模块时需要使用这个用户名和密码。 

= 打包工具

Python 有多个打包工具, 这里使用两种打包工具, 即 #link("https://rye-up.com/")[Rye] 和 #link("https://python-poetry.org/")[Poetry]。

== Rye

=== 安装 Rye

Rye 提供了 exe 安装格式, 是单个二进制可执行文件, 从官网下载 #link("https://github.com/mitsuhiko/rye/releases/latest/download/rye-x86_64-windows.exe")[rye-x86_64-windows.exe], 然后把 Rye 添加到系统的 Path 路径中。

=== 创建项目

使用 `rye init esc_app` 创建一个项目, 生成的项目中有一个名为 #text(red)[pyproject.toml] 的文件, 其内容如下:

```toml
[project]
name = "esc_app"
version = "0.1.0"
description = "Add your description here"
dependencies = []
readme = "README.md"
requires-python = ">= 3.8"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.rye]
managed = true
dev-dependencies = []

[tool.hatch.metadata]
allow-direct-references = true
```

执行 `rye sync`:

```
Initializing new virtualenv in /mnt/d/software/scripts/esc_app/esc_app/.venv
Python version: cpython@3.11.3
Generating production lockfile: /mnt/d/software/scripts/esc_app/esc_app/requirements.lock
Generating dev lockfile: /mnt/d/software/scripts/esc_app/esc_app/requirements-dev.lock
Installing dependencies
Looking in indexes: https://pypi.org/simple/
Obtaining file:///. (from -r /tmp/tmpcvyy5_fl (line 1))
  Installing build dependencies ... done
  Checking if build backend supports build_editable ... done
  Getting requirements to build editable ... done
  Preparing editable metadata (pyproject.toml) ... done
Building wheels for collected packages: esc_app
  Building editable for esc_app (pyproject.toml) ... done
  Created wheel for esc_app: filename=esc_app-0.1.0-py3-none-any.whl size=975
  Stored in directory: /tmp/pip-ephem-wheel-cache-2vw7ijau/wheels/97/54/f5/
Successfully built esc_app
Installing collected packages: esc_app
Successfully installed esc_app-0.1.0
Done!
```

这会为我们自动创建虚拟环境, 下载依赖, 准备 Python 开发所需要的环境。最后的 `Done!` 说明一切准备就绪。

=== 添加依赖

执行 `rye add` 命令添加依赖:

```bash
$ rye add click==8.1.6
Added click==8.1.6 as regular dependency
$ rye add polars==0.18.6
Added polars==0.18.6 as regular dependency
$ rye add xlsx2csv==0.8.1
Added xlsx2csv==0.8.1 as regular dependency
$ rye add XlsxWriter==3.1.2
Added XlsxWriter==3.1.2 as regular dependency
```

执行 `rye add` 命令后, 会在 `pyproject.toml` 文件中增加 dependencies 配置:

```
dependencies = [
    "click==8.1.6",
    "polars==0.18.6",
    "xlsx2csv==0.8.1",
    "XlsxWriter==3.1.2",
]
```

=== 开发调试

假设我们开发了一个名为 main.py 的命令行程序, 它接收两个参数: input_path 和 sheet_name:

```python
import click

@click.command()
@click.option('--input-path', help='输入文件路径')
@click.option('--sheet-name', default='Sheet1', help='Worksheet 名称')
def peak_capacity(input_path, sheet_name):
    pass

if __name__ == '__main__':
    peak_capacity()
```

这是一个命令行程序, 我们在 #text(red)[pyproject.toml] 中添加命令行程序的配置:

```toml
[project.scripts]
peak = "esc_app.main:peak_capacity"
```

其中 esc_app 为 package 名, main 为命令行程序的文件名, peak_capacity 为入口函数。等号左边的 `peak` 为该命令行程序对外使用的别名, 调试的时候, 执行 `rye run` 命令运行该命令行程序:

```bash
rye run peak --input-path=input.xlsx --sheet-name=1月
```

=== 打包发布

模块/命令行程序开发完毕后, 执行 `rye build` 进行打包:

```bash
rye build
```

这会生成一个名为 #text(red)[dist] 的目录, 目录下包含两个文件:

```bash
xxx-a.b.c.tar.gz
xxx-a.b.c-py3-none-any.whl
```

rye 尚未支持发布到私服, 但是 rye 自己的发布命令使用的是 #link("https://twine.readthedocs.io")[twine], 而 twine 支持把 Python 模块发布到私服。

为了使用方便, 在 Windows 下在 %USERPROFILE% 目录下创建一个名为 #text(red)[.pypirc] 的文件, 其内容如下:

```toml
[distutils]
index-servers =
    pypi
    nexus
    devpi

[pypi]
repository: http://127.0.0.1:8099/
username: pypi
password: a_very_complex_password

[nexus]
repository: http://127.0.0.1:3333/repository/local-pypi/
username: pypi
password: a_very_complex_password


[devpi]
repository: http://pypi.xxx.xxx/bigdata/datahouse/+simple/
username: bigdata
password: a_very_complex_password
```

index-servers 是仓库的名称, 我们要把 Python 模块上传到 pypi 和 nexus。

使用 twine 的 #text(red)[upload] 命令, 后面跟着 #raw("dist/*"), 表示把 dist 目录下的所有文件都上传到私服。--repository 指定仓库的名称, twine 一次上传到一个仓库:

```bash
twine upload dist/* --repository pypi
twine upload dist/* --repository nexus
twine upload dist/* --repository devpi
```

== Poetry

=== 安装 Poetry

```bash
# 安装 Anaconda

# 切换到 conda 环境
cmd /k "C:\ProgramData\Anaconda3\Scripts\activate.bat & powershell -NoLogo"

# 设置代理
$Env:http_proxy="http://127.0.0.1:7890";$Env:https_proxy="http://127.0.0.1:7890"

# 安装 pipx
python -m pip install pipx --user

# 安装 poetry
pipx install poetry==1.1.15

# 添加 path 路径
pipx ensurepath

# 刷新环境变量或重开一个新的终端
refreshenv
```

=== 创建项目

```bash
mkdir esc_spp && cd esc_app
poetry init
```

执行 `poetry init` 命令后会以交互式的形式创建项目。

```
This command will guide you through creating your pyproject.toml config.

Package name:  esc_app
Version [0.1.0]:
Description []:
Author [None, n to skip]:  ohmycloud
License []:
Compatible Python versions [^3.11]:
```

确认生成的 `pyproject.toml` 文件格式是否正确: 

```toml
[tool.poetry]
name = "esc-app"
version = "0.1.0"
description = ""
authors = ["ohmycloud"]
readme = "README.md"
packages = [{include = "esc_app"}]

[tool.poetry.dependencies]
python = "^3.11"


[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

或使用 `poetry init -n` 直接创建一个项目。

=== 添加依赖

执行 `poetry add` 命令添加依赖:

```bash
poetry add polars==0.19.2
```

这会在 pyproject.toml 文件中添加依赖:

```toml
[tool.poetry.dependencies]
python = "^3.11"
polars = "0.19.2"
```

=== 开发调试

在 *pyproject.toml* 文件中添加如下配置:

```toml
[tool.poetry.scripts]
peak = "esc_app.main:peak_capacity"
```

执行 `poetry run` 命令运行命令行程序:

```bash
poetry run peak --input-path=input.xlsx --sheet-name=1月
```

=== 打包发布

首先配置仓库地址和用户名密码, 在客户机上执行如下设置:

```bash
# 配置 pypi 仓库
poetry config repositories.ohmycloud http://127.0.0.1:8099/
poetry config http-basic.ohmycloud pypi a_very_complex_password

# 配置 nexus 仓库
poetry config repositories.nexus http://127.0.0.1:3333/repository/local-pypi/
poetry config http-basic.nexus pypi a_very_complex_password

# 配置 devpi 仓库
poetry config repositories.devpi http://pypi.xxx.xxx/bigdata/datahouse/+simple/
poetry config http-basic.devpi bigdata a_very_complex_password
```

这会在 ~/.config 目录下创建一个名为 #text(red)[pypoetry] 的目录, 并生成 #text(red)[auth.toml] 和 #text(red)[config.toml] 文件。

`~/.config/pypoetry/auth.toml` 文件的内容如下:

```toml
[http-basic.nexus]
username = "pypi"
password = "a_very_complex_password"

[http-basic.ohmycloud]
username = "pypi"
password = "a_very_complex_password"

[http-basic.devpi]
username = "bigdata"
password = "a_very_complex_password"
```

`~/.config/pypoetry/config.toml` 文件的内容如下(注意 url 末尾的 `/`):

```toml
[repositories.nexus]
url = "http://127.0.0.1:3333/repository/local-pypi/"

[repositories.ohmycloud]
url = "http://127.0.0.1:8099/"

[repositories.devpi]
url = "http://pypi.xxx.xxx/bigdata/datahouse/+simple/"
```

也可以执行 `poetry config --list` 查看仓库地址。

配置完成后使用 `--dry-run` 模拟发布:

```bash
poetry build
poetry publish --repository ohmycloud --dry-run

# 如果没有使用 pypoetry 的配置文件, 则指定用户名和密码
poetry publish --repository ohmycloud -u pypi -p a_very_complex_password --dry-run
```

这会打印出该模块准备发布到 ohmycloud 仓库, 和上传进度:

```
Publishing esc_app (0.1.0) to ohmycloud
 - Uploading esc_app-0.1.0-py3-none-any.whl 100%
 - Uploading esc_app-0.1.0.tar.gz 100%
```

模拟发布没有问题后去掉 `--dry-run` 选项把模块发布到私有 PYPI 仓库中。

```bash
# 发布到 ohmycloud 仓库
poetry publish --repository ohmycloud
# 发布到 nexus 仓库
poetry publish --repository nexus

# 发布到 devpi 仓库
poetry publish --repository devpi

# 或使用 twine
twine upload dist/* -r devpi
```

== PDM

=== 安装 PDM

```bash
curl -sSL https://pdm-project.org/install-pdm.py | python3 -
```

=== 创建项目

```bash
mkdir my-project && cd my-project
pdm init
```

=== 添加依赖

添加依赖:

```bash
pdm add polars==0.18.15
```

=== 开发调试

在 *pyproject.toml* 文件中添加如下配置:

```toml
[tool.pdm.scripts]
peak = {call = "esc_app.main:peak_capacity"}
```

这对外暴露出了一个命令行接口, 即 peak 命令。

调试的时候, 使用 pdm 进行构建和安装后, 再使用 `pdm run` 运行命令行程序进行调试。

```bash
pdm build
pdm install
pdm run peak --input-path=input.xlsx --sheet-name=1月
```

=== 打包发布

第一次发布时, 需要配置仓库地址和用户名密码:

在用户的家目录新建一个文件: `~/.config/pdm/config.toml`, 其内容如下:

```toml
[repository.nexus]
url = "http://127.0.0.1:3333/repository/local-pypi/"
username = "pypi"
password = "a_very_complex_password"

[repository.ohmycloud]
url = "http://127.0.0.1:8099/"
username = "pypi"
password = "a_very_complex_password"

[repository.devpi]
url = "http://pypi.xxx.xxx/bigdata/datahouse/+simple/"
username = "bigdata"
password = "a_very_complex_password"
```

在 pyproject.toml 文件中, 添加如下内容:

```toml
[[tool.pdm.source]]
url = "http://127.0.0.1:3333/repository/local-pypi/"
verify_ssl = false
name = "nexus"

[[tool.pdm.source]]
url = "http://127.0.0.1:8099/"
verify_ssl = false
name = "ohmycloud"

[[tool.pdm.source]]
url = "http://pypi.xxx.xxx/bigdata/datahouse/+simple/"
verify_ssl = false
name = "devpi"
```

打包发布:

```bash
pdm publish -r nexus -v
pdm publish -r ohmycloud -v
pdm publish -r devpi -v
```

= 从私服安装模块

从私服中安装模块, 在 install 命令后面指定 `--trusted-host` 以及 `-i` 选项

```bash
# 从 pypi 仓库安装 Python 模块
pip install --trusted-host 127.0.0.1 -i http://127.0.0.1:8099/ esc_app==0.2.2
# 从 nexus 仓库安装 Python 模块
pip install --trusted-host 127.0.0.1 -i http://127.0.0.1:3333/repository/group-pypi/simple esc_app==0.2.2
# 从 devpi 仓库安装 Python 模块
pip install --trusted-host pypi.xxx.xxx -i http://pypi.xxx.xxx/bigdata/datahouse/+simple/ pdm_demo
```

= 使用 Python 模块

如果是 Python 模块, 直接导入使用:

```python
import esc_app
```

如果是命令行程序, 就像使用普通的 Python 命令行程序一样, 使用命令行程序的别名, 后跟命名参数:

```bash
peak --input-path=input.xlsx --sheet-name=1月
```

这样既可以把自己编写好的模块上传到私服供他人使用, 也可以安装使用别人编写好的模块。加上模块的版本控制, 分发和使用起来更加方便, 提升开发效率。
