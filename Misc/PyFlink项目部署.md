## 1) 安装 Anaconda

## 2) 准备 Python 环境

```yaml
name: pyflink-trip
channels:
  - defaults
  - conda-forge
dependencies:
  - python=3.6.5
  - pandas=1.1.5
  - pip
  - pip:
      - apache-flink==1.14.4
```

把以上文件另存为 `environment.yaml`。

## 3) 创建 conda 环境

```shell
conda env create -f environment.yaml
```

## 4) 激活环境

```shell
conda activate pyflink-trip
```

## 5) 启动 PyFlink 集群

```bash
bin/start-cluster.sh
```

## 6) 准备 tar 包

- A Python environment on which your UDFs execute, and
- An archive that packages all resources you would like to access in your UDFs


```bash
(cd /opt/anaconda3/envs/pyflink-trip/ && zip -r - .) > pyenv.zip
```

打包整个 Python 项目:

```bash
zip -r projects.zip . \
  -x alg/* \
  -x auto_build.sh \
  -x requirements.txt \
  -x *.git* \
  -x *__pycache__* \
  -x readme.md \
  -x .idea/* \
  -x *.docx \
  -x *.sh \
  -x *.ps1 \
  -x .gitignore \
  -x consistency_app.py \
  -x lithium_app.py.py \
  -x rcc_app.py \
  -x soh_app.py \
  -x thermorunaway_app.py
```


激活环境, 


```bash
conda activate pyflink-trip
```


提交：

本地模式

```bash
/opt/software/flink-1.14.4/bin/flink run -d \
  -pyexec pyflink-trip/bin/python \
  -pyarch archive.zip,pyenv.zip#pyflink-trip \
  -py labeled_trip.py --prefix=hdfs://10.0.0.39:8020/byd_can --day=2020-09-02
```

报错了:


```
Traceback (most recent call last):
  File "labeled_trip.py", line 6, in <module>
    from conf.config import table_source_ddl, fields_alias, sink_ddl, byd_type_info, byd_type_info_with_name, output_typeinfo
ModuleNotFoundError: No module named 'conf'
org.apache.flink.client.program.ProgramAbortException: java.lang.RuntimeException: Python process exits with code: 1
```


```bash
zip -r archive.zip . labeled_trip.py
```


使用 `-pyfs` 命令指定 Python 项目归档文件: 


```bash
/opt/software/flink-1.14.4/bin/flink run -d \
  -pyexec pyflink-trip/bin/python \
  -pyarch pyenv.zip#pyflink-trip \
  -pyfs archive.zip \
  -py labeled_trip.py --prefix=hdfs://10.0.0.39:8020/byd_can --day=2020-09-22
```


提交后可以运行了。


把 await() 去掉后, 报错了:


```bash
Caused by: org.apache.flink.table.api.ValidationException: Could not find any factory for identifier 'jdbc' that implements 'org.apache.flink.table.factories.DynamicTableFactory' in the classpath.
```

Flink 的 lib 目录下没有 mysql 的包:

```bash
ls /opt/software/flink-1.14.4/lib | grep mysql
```

拷贝 flink-connector-jdbc 到 Flink 的 lib 目录下:

```bash
cp jars/flink-connector-jdbc_2.11-1.14.4.jar /opt/software/flink-1.14.4/lib/
```

报错了：

```
Caused by: org.apache.flink.streaming.runtime.tasks.StreamTaskException: Cannot load user class: org.apache.flink.connector.jdbc.internal.GenericJdbcSinkFunction
ClassLoader info: URL ClassLoader:
    file: '/tmp/blobStore-3cfedc37-4649-419a-a4c8-bd664a807ed3/job_be51f0e55c7124b03a49387bba127560/blob_p-2434f9e868ef2713813bda8bfd0d4f1e908f1113-20878764299ccab736aa76a9def0dd2d' (valid JAR)
Class not resolvable through given classloader.
```

把 mysql-connector 也拷贝到 Flink 的 lib 目录下::

```bash
cp jars/mysql-connector-java-8.0.13.jar /opt/software/flink-1.14.4/lib/
```


把 await() 去掉后:

```
Job has been submitted with JobID a3975165b5a741219e3767f7b674ed52
Job has been submitted with JobID 1c0fb72a2f14d90cd1eb6764c0139b8f
```

```
pipeline_jars = '/opt/software/flink-1.14.4/lib/flink-connector-jdbc_2.11-1.14.4.jar;/opt/software/flink-1.14.4/lib/mysql-connector-java-8.0.13.jar'
```

报了 no protocol:

```
py4j.protocol.Py4JJavaError: An error occurred while calling None.java.net.URL.
: java.net.MalformedURLException: no protocol: /opt/software/flink-1.14.4/lib/flink-connector-jdbc_2.11-1.14.4.jar
```

需要改为:

```
pipeline_jars = 'file:////opt/software/flink-1.14.4/lib/flink-connector-jdbc_2.11-1.14.4.jar;file:////opt/software/flink-1.14.4/lib/mysql-connector-java-8.0.13.jar'
```


如果放在 hdfs 上应该也是 OK 的：

```python
pipeline_jars = 'hdfs://jars/flink-connector-jdbc_2.11-1.14.4.jar;hdfs://jars/mysql-connector-java-8.0.13.jar'
```

设置完 `pipeline.jars` 还需要把这些 jars 放到 Flink 的 lib 目录吗？？？


```python
# 设置并发度和 pipeline.jars
table_env \
    .get_config() \
    .get_configuration() \
    .set_string("default.parallelism", "6") \
    .set_string("pipeline.jars", pipeline_jars)
```



打包时需要把 main.py 打包进去吗? (不需要)

```bash
# 删除 zip 包中的某个文件
zip -d archive.zip labeled_trip.py

# 删除 zip 包中的某个目录
zip -d archive.zip jars/
```

去掉 env.execute('streaming') 后, 


再次运行, 只看到一个任务了:

```
Job has been submitted with JobID f876bc1da122b57a50a2657d1fa5f3c5
```


注释掉即可:


```python
env.execute('streaming')
```

写数据库好像比较慢。


集群模式

```bash
bin/flink run -m yarn-cluster -pyarch venv.zip -pyexec venv.zip/venv/bin/Python -py deploy_demo.py
```


## 参考连接

- https://yiksanchan.com/posts/pyflink-infer
- https://enjoyment.cool/2020/01/02/Apache-Flink-%E8%AF%B4%E9%81%93%E7%B3%BB%E5%88%97-PyFlink-%E4%BD%9C%E4%B8%9A%E7%9A%84%E5%A4%9A%E7%A7%8D%E9%83%A8%E7%BD%B2%E6%A8%A1%E5%BC%8F/