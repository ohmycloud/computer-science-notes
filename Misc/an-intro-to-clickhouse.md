# ClickHouse 

## 行式存储和列式存储的区别

Examples of a row-oriented DBMS are MySQL, Postgres, and MS SQL Server.

| Row   | WatchID 	    | JavaEnable 	| Title 	          | GoodEvent 	| EventTime           |
|:------|:--------------|:--------------|:--------------------|:------------|:--------------------|
| #0 	| 89354350662 	| 1 	        | Investor  Relations |	1 	        | 2016-05-18 05:19:20 |
| #1 	| 90329509958 	| 0 	        | Contact us 	      | 1 	        | 2016-05-18 08:10:20 |
| #2 	| 89953706054 	| 1 	        | Mission 	          | 1 	        | 2016-05-18 07:38:00 |
| #N 	| … 	        | … 	        | … 	              | … 	        | …                   |

> all the values related to a row are physically stored next to each other.

MySQL 这样的行式存储数据库, 一行中的有关数据在物理存储上是存在一块的。

列式存储数据库的数据存储是这样的:

| Row: 	        | #0 	                |    #1 	             |       #2 	       |         #N
|:--------------|:----------------------|:-----------------------|:--------------------|:------------|
| WatchID: 	    | 89354350662 	        | 90329509958 	         | 89953706054 	       | …           |
| JavaEnable: 	| 1 	                | 0 	                 | 1 	               | …           |
| Title: 	    | Investor Relations 	| Contact us 	         | Mission      	   | …           |
| GoodEvent: 	| 1 	                | 1 	                 | 1 	               | …           |
| EventTime: 	| 2016-05-18 05:19:20 	| 2016-05-18 08:10:20 	 | 2016-05-18 07:38:00 | …           |

> The values from different columns are stored separately, and data from the same column is stored together.

列式存储中，89354350662、90329509958 和 89953706054 这种同类型的数据, 物理上存储在一起。

ClickHouse 的操作是矢量化的, 它不是针对单个值进行操作, 而是对一整列进行操作(一列下面的数据都是同类型的)。
为了高效的使用CPU，数据不仅仅按列存储，同时还按向量(列的一部分)进行处理，这样可以更加高效地使用CPU。

ClickHouse是一个数据库管理系统，而不是一个单一的数据库。ClickHouse允许在运行时创建表和数据库，加载数据，并运行查询，而不需要重新配置和重启服务器。

ClickHouse 会使用服务器上一切可用的资源，从而以最自然的方式并行处理大型查询。
在ClickHouse中，数据可以保存在不同的shard上，每一个shard都由一组用于容错的replica组成，查询可以并行地在所有shard上进行处理。这些对用户来说是透明的。
什么是分片？shard?

ClickHouse支持在表中定义主键。一般用 id 或 UUID 用作主键。

## 索引

按照主键对数据进行排序，这将帮助 ClickHouse 在几十毫秒以内完成对数据特定值或范围的查找。

## 限制

稀疏索引使得 ClickHouse 不适合通过其键检索单行的点查询。


/etc/clickhouse-server/

```bash
ls /etc/clickhouse-server/
```


config.d  config.xml  users.d  users.xml

config.xml 是 ClickHouse 的配置文件。升级时会修改这个文件, 所以一般使用 config.d 目录下的配置文件。

复制一份 config.xml 到 ClickHouse 的 config.d 目录下, 把数据存储路径从 /var/lib/clickhouse/ 改为 /data/clickhouse/

## ClickHouse 研究

启动 clickhouse server:

```bash
systemctl start clickhouse-server
```

使用客户端连接:

```bash
clickhouse-client
```

退出:

```bash
exit
```

```bash
cd /opt/scripts/Rust/clickhouse-server
```

配置文件:

复制 users.xml 和 config.xml 到某个目录下:

```bash
cp /etc/clickhouse-server/users.xml .
cp /etc/clickhouse-server/config.xml .
```

所属组和用户改为 clickhouse:

```bash
chown clickhouse:clickhouse users.xml
chown clickhouse:clickhouse config.xml
```

修改 config.xml 中监听的 host:

```xml
<listen_host>0.0.0.0</listen_host>
```

并将 9000 端口替换为 9917。

用自定义的配置文件启动 clickhouse-server:

```bash
sudo -u clickhouse /usr/bin/clickhouse-server --config=config.xml
```

查看占用的端口:

```bash
lsof -p $(pgrep clickhouse) -i -Pan
```

然后修改项目中的 database_url:

```bash
let database_url = "tcp://10.0.0.17:9917/default?compression=lz4&ping_timeout=5000ms";
```

测试:

```bash
cargo run add 1
cargo run list 1
```

## 使用 clickhouse-client

由于我们更改了默认的端口, 所以需要使用 `clickhouse-client --port=9917 --host=10.0.0.17` 进行连接。

```
clickhouse-client --port=9917  --host=10.0.0.17 --query='SELECT 1'
echo 'SELECT 1' | clickhouse-client --port=9917  --host=10.0.0.17
clickhouse-client --port=9917  --host=10.0.0.17 <<< 'SELECT 1'
```

## 一个例子

```sql
show databases;
clickhouse-client --query "CREATE DATABASE IF NOT EXISTS tutorial"
```

## 使用 Python 客户端连接

```bash
pip install clickhouse-driver
pip install lz4
pip install clickhouse-cityhash
```

创建表:

```python
from clickhouse_driver import Client
import clickhouse_driver

if __name__ == '__main__':
    client = clickhouse_driver.Client(
        host = '10.0.0.17',
        port = '9917',
        database = 'tutorial',
        compression=True
    )

    # create table
    sql = """create table ...."""
    client.execute(sql)
```

查看表结构

```bash
describe hits_v1;
show create table hits_v1;
```

导入数据

```bash
clickhouse-client --host=10.0.0.17 --port=9917 --query="insert into tutorial.hits_v1 format TSV" --max_insert_block_size=100000 < hits_v1.tsv
clickhouse-client --host=10.0.0.17 --port=9917 --query="insert into tutorial.visits_v1 format TSV" --max_insert_block_size=100000 < visits_v1.tsv

clickhouse-client --host=10.0.0.17 --port=9917 --query "OPTIMIZE TABLE tutorial.hits_v1 FINAL"
clickhouse-client --host=10.0.0.17 --port=9917 --query "OPTIMIZE TABLE tutorial.visits_v1 FINAL"
```

## 执行 SQL

```bash
SELECT
    StartURL AS URL,
    AVG(Duration) AS AvgDuration
FROM tutorial.visits_v1
WHERE StartDate BETWEEN '2014-03-23' AND '2014-03-30'
GROUP BY URL
ORDER BY AvgDuration DESC
LIMIT 10

SELECT \
    sum(Sign) AS visits, \
    sumIf(Sign, has(Goals.ID, 1105530)) AS goal_visits, \
    (100. * goal_visits) / visits AS goal_percent \
FROM tutorial.visits_v1 \
WHERE (CounterID = 912887) AND (toYYYYMM(StartDate) = 201403) AND (domain(StartURL) = 'yandex.ru')
```

Windows 的终端对跨行的 SQL 支持不好, 需要使用续行符 `\`。

也可以使用 Python 客户端进行 SQL 查询:

```python
from clickhouse_driver import Client
import clickhouse_driver

if __name__ == '__main__':
    client = clickhouse_driver.Client(
        host = '10.0.0.17',
        port = '9917',
        database = 'tutorial',
        compression=True
    )

    # create table
    sql1 = """
SELECT name, value, changed, description
FROM system.settings
WHERE name LIKE '%max_insert_b%'
FORMAT TSV"""
    res = client.execute(sql1)
    for i in res:
        print(i)
```

## HTTP 接口连接

```bash

# 使用 CURl 查询 ClickHouse 的 Playground
echo 'SELECT 1' | curl 'https://playground:clickhouse@play-api.clickhouse.tech:8443/' -d @-

curl "https://play-api.clickhouse.tech:8443/?query=SELECT+'Play+ClickHouse\!';&user=playground&password=clickhouse&database=datasets"
```

使用 CURL 查询一下公司内网的 ClickHouse:

```bash
echo 'SELECT 1' | curl 'http://10.0.0.17:9917' -d @-
```

Port 9917 is for clickhouse-client program.
You must use port 8123 for HTTP.

它说对于 HTTP 请求, 必须使用 8123 端口:

```bash
echo 'SELECT 1' | curl 'http://10.0.0.17:8123' -d @-
```

## MySQL 连接

```bash
mysql --protocol tcp -u default -P 9004 -h 10.0.0.17
```

默认端口是 9004, 可以使用 MySQL 客户端连接。

## 添加用户名和密码

```bash
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha1sum | tr -d '-' | xxd -r -p | sha1sum | tr -d '-'
```

生成一个名为密码和对应的 hash 字符串:

```
Vutb6feT
19bbb7c40e91b7641542b8cef430e4433eb02054
```

使用 256sum

```bash
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha1sum | tr -d '-' | xxd -r -p | sha256sum | tr -d '-'
```



```
Y9NtcmFI
efbff2ab3cccb0787ec46359a60f50bbc4d162b4510151f86e4b1e6bf2654186
```

在 /opt/scripts/Rust/clickhouse-server/users.xml 的 `<users>` 标签里面添加另外一个名为 bigdata 的用户:

```xml
        <bigdata>
          <password>Y9NtcmFI</password>
          <!-- Or -->
            <!-- <password_sha256_hex>efbff2ab3cccb0787ec46359a60f50bbc4d162b4510151f86e4b1e6bf2654186</password_sha256_hex> -->
            <networks>
                <ip>::/0</ip>
            </networks>

            <!-- Settings profile for user. -->
            <profile>default</profile>

            <!-- Quota for user. -->
            <quota>default</quota>

            <!-- User can create other users and grant rights to them. -->
            <!-- <access_management>1</access_management> -->
        </bigdata>
```

重启 clickhouse-server


```bash
#先停掉之前的 server。
sudo -u clickhouse /usr/bin/clickhouse-server --config=config.xml

# 使用密码连接 ClickHouse
clickhouse-client --port=9917 --host=10.0.0.17 --user bigdata --password Y9NtcmFI
```

```
# clickhouse-client --port=9917 --host=10.0.0.17 --user bigdata --password Y9NtcmFI
ClickHouse client version 21.4.6.55 (official build).
Connecting to 10.0.0.17:9917 as user bigdata.
Connected to ClickHouse server version 21.4.6 revision 54447.
```

MySQL 客户端的连接：

```bash
mysql --protocol tcp -u default -P 9004 -h 10.0.0.17 -u bigdata -p
```

输入密码连接 ClickHouse。

写入 online 数据

```bash
ls -1 *.zip | xargs -I{} -P $(nproc) bash -c "echo {}; unzip -cq {} '*.csv' | sed 's/\.00//g' | clickhouse-client --port=9917 --host=10.0.0.17 --user bigdata --password Y9NtcmFI --input_format_with_names_use_header=0 --query='INSERT INTO tutorial.ontime FORMAT CSVWithNames'"
```

## 数据的加载

可以从 CSV 中通过 insert into 把数据写入 ClickHouse 中, 也可以使用预先分区好的数据(以 `.idx`、`.bin`、`.mrk` 等后缀结尾的文件):

```bash
$ curl -O https://datasets.clickhouse.tech/ontime/partitions/ontime.tar
$ tar xvf ontime.tar -C /var/lib/clickhouse # path to ClickHouse data directory
$ # check permissions of unpacked data, fix if required
$ sudo service clickhouse-server restart
$ clickhouse-client --query "select count(*) from datasets.ontime"
```

官网的建表语句某些列不存在(ClickHouse 中的每一列都以列的名字命名的 xxxcolumn.bin 文件)。

## 输入格式和输出格式

ClickHouse 支持多种数据输入和输出格式, 例如 Parquet: https://clickhouse.tech/docs/en/interfaces/formats/#data-format-parquet

## 参考链接

- https://github.com/suharev7/clickhouse-rs
- https://altinity.com/blog/2019/3/15/clickhouse-networking-part-1
- https://clickhouse.tech/docs/en/getting-started/install/
- https://github.com/nauu/rust2ch
- https://altinity.com/blog/clickhouse-and-python-getting-to-know-the-clickhouse-driver-client
- https://blog.csdn.net/github_39577257/article/details/103066747
