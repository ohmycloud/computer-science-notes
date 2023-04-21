- 添加分区

```sql
-- 示例
ALTER TABLE table_name ADD PARTITION (partCol = 'value1') location 'loc1';

-- 一次添加一个分区
ALTER TABLE table_name ADD IF NOT EXISTS PARTITION (dt='20130101') LOCATION '/user/hadoop/warehouse/table_name/dt=20130101'; 

-- 一次添加多个分区
ALTER TABLE page_view ADD PARTITION (dt='2008-08-08', country='us') location '/path/to/us/part080808' PARTITION (dt='2008-08-09', country='us') location '/path/to/us/part080809';
```

创建完 nation 表后不能直接查到 parquet 数据, 需要添加分区:

```sql
ALTER TABLE nation ADD PARTITION (dt='20200105', vt='A26') location '/parquet_data/nation/vintype=A26/d=20200105';
```

- 删除分区

```sql
ALTER TABLE login DROP IF EXISTS PARTITION (dt='2008-08-08');
ALTER TABLE page_view DROP IF EXISTS PARTITION (dt='2008-08-08', country='us');
```

- 修改分区

```sql
ALTER TABLE table_name PARTITION (dt='2008-08-08') SET LOCATION "new location";
ALTER TABLE table_name PARTITION (dt='2008-08-08') RENAME TO PARTITION (dt='20080808');
```

- 添加列

```sql
-- 在所有存在的列后面，但是在分区列之前添加一列
ALTER TABLE table_name ADD COLUMNS (col_name STRING);
```

- 修改列

```sql
CREATE TABLE test_change (a int, b int, c int);
  
-- will change column a's name to a1
ALTER TABLE test_change CHANGE a a1 INT; 
  
-- will change column a's name to a1, a's data type to string, and put it after column b. 
-- The new table's structure is: b int, a1 string, c int
ALTER TABLE test_change CHANGE a a1 STRING AFTER b; 
  
-- will change column b's name to b1, and put it as the first column. 
-- The new table's structure is: b1 int, a string, c int
ALTER TABLE test_change CHANGE b b1 INT FIRST;
```

- 修改表属性

```sql
-- 内部表转外部表 
alter table table_name set TBLPROPERTIES ('EXTERNAL'='TRUE');

-- 外部表转内部表
alter table table_name set TBLPROPERTIES ('EXTERNAL'='FALSE');
```

- 重命名表

```sql
ALTER TABLE table_name RENAME TO new_table_name
```

- 查看某个表的分区

`SHOW PARTITIONS table_name;`
  
![](https://gitee.com/uibooker/ImgSync/raw/master/img/2019-09-11-ouVZVF.png)

- 查看某个表是否存在某个特定分区

```sql
SHOW PARTITIONS table_name PARTITION(dt='xx')
  
DESCRIBE EXTENDED tabel_name PARTITION(dt='xx')
```

- 查询表信息：

`DESCRIBE EXTENDED table_name;`

- 查询结构化的表信息：

`DESCRIBE FORMATTED table_name;`
