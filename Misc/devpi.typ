#import("circuedoc_template.typ"): conf

#show link: underline

#show: doc => conf(
    title: "Python 项目打包与发布流程",
    author: "ohmycloud",
    date: datetime.today().display(),
    description: "ohmycloud",
    doc,
)



= 新建项目

为了使 Python 代码组织、管理、分享以及维护的方便, 建议创建带有 *pyproject.toml* 文件的项目。
有很多包管理工具可以为我们创建 *pyproject.toml* 文件。

== 方法一）使用 #link("https://pdm-project.org/latest/")[pdm] 新建项目

```bash
mkdir my-project && cd my-project
pdm init
```

添加依赖:

```bash
pdm add polars==0.18.15
```

构建:

```bash
pdm build
```

发布:

```bash
pdm publish --no-build
```

== 方法二）使用 #link("https://python-poetry.org/")[Poetry] 新建项目

```bash
mkdir my-project && cd my-project
poetry init --name=my_project
```

添加依赖:

```bash
poetry add polars==0.18.15
```

构建：

```bash
poetry build
```

发布：

```bash
poetry publish
```

== 方法三）使用 #link("https://rye-up.com/")[Rye] 新建项目

```bash
mkdir my-project && cd my-project
rye init --name my_project
```

添加依赖:

```bash
rye add polars==0.18.15
```

构建：

```bash
rye build
```

发布：

```bash
rye publish
```

= 把 Python 包发布到私服

使用 build 命令构建完 Python 包之后,  在发布阶段, 一般需要配置上传时需要的用户名、密码以及仓库地址等信息。

== 发布到 #link("http://pypi.xxx.xxx/")[devpi]

把 Python 包发布到 devpi, 需要先安装 *devpi*:

```bash
pip install devpi
```

在服务端创建发布 Python 包需要的账号密码, 例如 bigdata:bigdata。

使用新创建的账号登录 devpi:

```bash
devpi login bigdata
```

登录成功之后创建新的索引。例如下面的命令创建了一个名为 datahouse 的索引:

```bash
devpi index -c datahouse
```

上传 Python 包到 pypi 服务器时, 可以使用 devpi 命令行程序或 twine 命令行程序。

使用 devpi 命令上传 Python 包时, 需要先登录。

```bash
devpi login bigdata # 登录账号
devpi upload --sdist .\dist\xxx-0.1.0-py3-none-any.whl
```

使用 twine 上传时, 会自动使用 *.pypirc* 配置中的账号密码来登录(参见 @config):

```bash
twine upload .\dist\* -r devpi --verbose
```

如果在配置中配置了仓库的名字, 那么在上传时使用 -r 仓库名 即可。 

== 配置 <config>

为了上传方面, 在系统的家目录下配置创建一个名为 *.pypirc* 的文件, 文件内容如下:

```bash
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
repository: http://pypi.xxx.xxx/bigdata/datahouse
username: bigdata
password: a_very_complex_password
```

如果有多个索引服务, 就每行一个 index-server, 例如上面的配置中, 就使用了 pypi, nexus 和 devpi 三个索引服务。
在每个索引服务的下面, 配置仓库地址, 用户名和密码。

= 安装 Python 包 

上传完毕后, 使用者使用 pip 命令安装模块:

```bash
pip install --trusted-host pypi.xxx.xxx \
 -i http://pypi.xxx.xxx/bigdata/datahouse/+simple \
 test==0.1.1
```
