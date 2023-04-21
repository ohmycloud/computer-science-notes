# Cassandra 笔记

创建新用户：

```sql
-- 创建一个 superuser 帐号

cd ~/opt/apache-cassandra-3.11.2/conf
-- vi cassandra.yaml # 将 authenticator 的值改为 PasswordAuthenticator
create role ohmycloud with PASSWORD = '123456' AND SUPERUSER = true;
```


```sql
CREATE KEYSPACE wmremotediagnose WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '2'}  AND durable_writes = true;
use wmremotediagnose;
--dtc诊断结果表
CREATE TABLE dtc_result(
taskid TEXT, -- 任务 ID
log TEXT,    -- log 日志
result TEXT, -- 报文结果  
PRIMARY KEY (taskid)
);
```

Cassandra 的 insert 操作， 不能使用双引号：

```sql
insert into wmtest.can_signal (vin,message_creation_time,odometer_value_mtr) values ("20171020SR66137","2018-06-13 13:34:34","6106") ;
```

并且类型要匹配。

```sql
insert into wmtest.can_signal (vin,message_creation_time,odometer_value_mtr) values ('20171020SR66137','2018-06-13 13:34:34',6106) ;
```
