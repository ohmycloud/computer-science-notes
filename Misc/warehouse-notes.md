## 创建 HDFS 分层数据目录

在数据仓库中新增 ads 层和 dws 层:

```bash
sudo -su hdfs hdfs dfs -mkdir /data/external/warehouse/ads
sudo -su hdfs hdfs dfs -mkdir /data/external/warehouse/dws
```

修改 ads 层和 dws 层目录的所属组和所属用户(例如这里只允许 hadoop 用户读写如下目录):

```bash
sudo -su hdfs hdfs dfs -chown -R hadoop:hadoop /data/external/warehouse/ads
sudo -su hdfs hdfs dfs -chown -R hadoop:hadoop /data/external/warehouse/dws
```

查看数据仓库的分层目录:

```bash
[hadoop@datahouse-node3 job]$ hdfs dfs -ls /data/external/warehouse
drwxr-xr-x   - hadoop hadoop          0 2022-07-11 14:48 /data/external/warehouse/ads
drwxr-xr-x   - hadoop hadoop          0 2022-06-06 18:13 /data/external/warehouse/dwd
drwxr-xr-x   - hadoop hadoop          0 2022-07-11 15:55 /data/external/warehouse/dws
drwxr-xr-x   - hadoop hadoop          0 2022-07-11 10:18 /data/external/warehouse/ods
drwxr-xr-x   - hadoop hadoop          0 2022-04-21 18:31 /data/external/warehouse/std
drwxr-xr-x   - hadoop hadoop          0 2022-07-08 12:09 /data/external/warehouse/temp
```

## 创建表

建表语句类似 MySQL 语法:

```sql
CREATE EXTERNAL TABLE `dwd_alg_car_detail_csf_yi`(
  `real_time` string COMMENT '格式数据时间',
  `charge_st` bigint COMMENT '充电状态',
  `soc` double COMMENT 'SOC',
  `volt` double COMMENT '总电压',
  `current` double COMMENT '总电流',
  `veh_spd` double COMMENT '车速',
  `mileage` double COMMENT '里程',
  `max_single_volt` double COMMENT '电池单体电压最高值',
  `min_single_volt` double COMMENT '电池单体电压最低值',
  `max_temp` double COMMENT '最高温度值',
  `min_temp` double COMMENT '最低温度值',
  `timestamp` bigint COMMENT '时间戳数据时间',
  `mohm` double COMMENT '绝缘电阻',
  `lon` double COMMENT '经度',
  `lat` double COMMENT '维度',
  `max_single_volt_no` bigint COMMENT '电池单体电压最高单体编号',
  `min_single_volt_no` bigint COMMENT '电池单体电压最低单体编号',
  `bat_num` bigint COMMENT '电池个数',
  `max_temp_no` bigint COMMENT '最高温度探针编号',
  `min_temp_no` bigint COMMENT '最低温度探针编号',
  `temp_num` bigint COMMENT '电池温度探针总数',
  `single_volt_list` string COMMENT '电池单体电压列表',
  `single_temp_list` string COMMENT '电池探针温度列表',
  `charge_num` bigint COMMENT '充电段个数',
  `even` bigint COMMENT '充电段个数为偶数',
  `odd` bigint COMMENT '充电段个数奇数位')
COMMENT '车的上报明细数据，按oem,vin,年度分区'
PARTITIONED BY (
  `oem` string COMMENT 'oem厂商简称，算法维护',
  `vin` string COMMENT '车架号',
  `y` string COMMENT 'yyyy')
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  'hdfs://ns1/data/external/warehouse/dwd/dwd_alg_car_detail_csf_yi'
TBLPROPERTIES ('parquet.compression'='snappy');
```

## 运行 hive sql

```sql
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.max.dynamic.partitions=20000;
set hive.exec.max.dynamic.partitions.pernode=2000;
set parquet.memory.min.chunk.size= 65536;
use temp;

with tmp_oem as (
    select `real_time`        ,
        `timestamp`           ,
        `volt`                ,
        `current`             ,
        `soc`                 ,
        `max_single_volt`     ,
        `max_single_volt_no`  ,
        `min_single_volt`     ,
        `min_single_volt_no`  ,
        `max_temp`            ,
        `max_temp_no`         ,
        `min_temp`            ,
        `min_temp_no`         ,
        `charge_st`           ,
        `bat_num`             ,
        `temp_num`            ,
        `veh_spd`             ,
        `mileage`             ,
        `mohm`                ,
        `lon`                 ,
        `lat`                 ,
        `single_volt_list`    ,
        `single_temp_list`    ,
        `charge_num`          ,
        `even`                ,
        `odd`                 ,
        '${hiveconf:hive.oem.name}' as oem,
        `vin`                 ,
        DATE_FORMAT(real_time, 'Y') as y
        from ${hiveconf:hive.table.name}
)

insert overwrite table dwd.dwd_alg_car_detail_csf_yi partition(oem, vin, y)
select * from tmp_oem;
```

创建一个名为 beeline_dwd_alg_car_detail_csf_yi.sh 的 shell 脚本:

```bash
#!/bin/bash

job_name=$(basename "$0" | awk -F . '{print $1}')

for table in $(cat tables.txt)
do
    oem_name=$(echo "${table}" | awk -F '_' '{print $2}')
    echo "执行数据: ${oem_name}"
    beeline -u jdbc:hive2://datahouse-master2:10000 -n hadoop --hiveconf spark.app.name="${job_name}_${table}" --hiveconf hive.table.name="${table}" --hiveconf hive.oem.name="${oem_name}" -f etl_from_alg_to_datahouse.sql
    if [[ $? -ne 0 ]]; then
      echo "${table} finally failed"
    else
      echo "${table} finally successed"
    fi
done
```

这会按顺序依次从不同的表中读取数据, 写入到目的表。

## 运维

定时刷新 metadata:

创建一个名为 impala-meta.sh 的 shell 脚本:

```bash
impala-shell -u ranger -q 'invalidate metadata' > impala.log
```

设置为定时任务:

```bash
*/10 * * * * /root/impala-meta.sh
```

上述任务会每隔 10 分钟使用 ranger 用户执行 **invalidate metadata**, 刷新元数据。 

使用 beeline:

```bash
beeline -u jdbc:hive2://host1:10000 -n hadoop
```
