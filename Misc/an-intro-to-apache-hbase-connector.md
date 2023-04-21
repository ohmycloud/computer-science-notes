# [Use Spark to read and write HBase data](https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-using-spark-query-hbase)

## 启动 hbase

```
start-hbase.sh
```

## 在 HBase 中准备 sample 数据

- 1、运行 HBase shell

```
hbase shell
```

- 2、创建一个含有 `Personal` 和 `Office` 列簇的 `Contacts` 表

```
create 'Contacts', 'Personal', 'Office'
```

- 3、加载一些样例数据

```
put 'Contacts', '1000', 'Personal:Name', 'John Dole'
put 'Contacts', '1000', 'Personal:Phone', '1-425-000-0001'
put 'Contacts', '1000', 'Office:Phone', '1-425-000-0002'
put 'Contacts', '1000', 'Office:Address', '1111 San Gabriel Dr.'
put 'Contacts', '8396', 'Personal:Name', 'Calvin Raji'
put 'Contacts', '8396', 'Personal:Phone', '230-555-0191'
put 'Contacts', '8396', 'Office:Phone', '230-555-0191'
put 'Contacts', '8396', 'Office:Address', '5415 San Gabriel Dr.'
```

## 运行 Spark Shell 引用 Spark HBase Connector

```bash
spark-shell --packages com.hortonworks:shc-core:1.1.1-2.1-s_2.11 --repositories http://repo.hortonworks.com/content/repositories/releases
```

这会下载很多 jar 包, 完成后会进入 spark shell 界面, 继续下面的步骤。

## 定义一个 Catalog 并查询

- 1）在你的 Spark Shell 中, 运行下面的 `import` 语句：

```scala
import org.apache.spark.sql.{SQLContext, _}
import org.apache.spark.sql.execution.datasources.hbase._
import org.apache.spark.{SparkConf, SparkContext}
import spark.sqlContext.implicits._
```

- 2）给 HBase 表中的 Contacts 表定义一个 catalog

a. 给名为 `Contacts` 的 HBase 表定义一个 catalog
b. 将 rowkey 标识为 `key`，并将 Spark 中使用的列名映射到 HBase 中使用的列族，列名和列类型
c. 还必须将 r​​owkey 详细定义为命名列（`rowkey`），其具有 `rowkey` 的特定列族 `cf`。

```scala
def catalog = s"""{
     |"table":{"namespace":"default", "name":"Contacts"},
     |"rowkey":"key",
     |"columns":{
     |"rowkey":{"cf":"rowkey", "col":"key", "type":"string"},
     |"officeAddress":{"cf":"Office", "col":"Address", "type":"string"},
     |"officePhone":{"cf":"Office", "col":"Phone", "type":"string"},
     |"personalName":{"cf":"Personal", "col":"Name", "type":"string"},
     |"personalPhone":{"cf":"Personal", "col":"Phone", "type":"string"}
     |}
 |}""".stripMargin
```

- 3) 定义一个方法，在 HBase 中的 `Contacts` 表周围提供 `DataFrame`：


```scala
def withCatalog(cat: String): DataFrame = {
         spark.sqlContext
         .read
         .options(Map(HBaseTableCatalog.tableCatalog->cat))
         .format("org.apache.spark.sql.execution.datasources.hbase")
         .load()
     }
```

- 4) 创建一个 DataFrame 的实例

```scala
val df = withCatalog(catalog)
```

- 5）查询这个 DataFrame

```scala
df.show()
```

- 6）你应该看到两行数据：

```
+------+--------------------+--------------+-------------+--------------+
|rowkey|       officeAddress|   officePhone| personalName| personalPhone|
+------+--------------------+--------------+-------------+--------------+
|  1000|1111 San Gabriel Dr.|1-425-000-0002|    John Dole|1-425-000-0001|
|  8396|5415 San Gabriel Dr.|  230-555-0191|  Calvin Raji|  230-555-0191|
+------+--------------------+--------------+-------------+--------------+
```

- 7）注册临时表，以便使用 Spark SQL 查询 HBase 表

```scala
df.registerTempTable("contacts")
```

- 8）针对 contacts 表发出 SQL 查询：

```scala
val query = spark.sqlContext.sql("select personalName, officeAddress from contacts")
query.show()
```

- 9）你应该看到这样的结果：

```
+-------------+--------------------+
| personalName|       officeAddress|
+-------------+--------------------+
|    John Dole|1111 San Gabriel Dr.|
|  Calvin Raji|5415 San Gabriel Dr.|
+-------------+--------------------+
```

## 插入新数据

- 1）要插入新的 Contact 联系人记录，请定义 `ContactRecord` 类：

```scalal
case class ContactRecord(
     rowkey: String,
     officeAddress: String,
     officePhone: String,
     personalName: String,
     personalPhone: String
     )
```

- 2）创建 `ContactRecord` 的实例并将其放在一个数组中：

```scala
val newContact = ContactRecord("16891", "40 Ellis St.", "674-555-0110", "John Jackson","230-555-0194")

var newData = new Array[ContactRecord](1)
newData(0) = newContact
```

- 3）将新数据数组保存到 HBase：

```scala
sc.parallelize(newData).toDF.write.options(Map(HBaseTableCatalog.tableCatalog -> catalog,HBaseTableCatalog.newTable -> "5")).format("org.apache.spark.sql.execution.datasources.hbase").save()
```

- 4）检查结果：

```scala
df.show()
```

- 5) 你应该看到这样的输出：

```
+------+--------------------+--------------+------------+--------------+
|rowkey|       officeAddress|   officePhone|personalName| personalPhone|
+------+--------------------+--------------+------------+--------------+
|  1000|1111 San Gabriel Dr.|1-425-000-0002|   John Dole|1-425-000-0001|
| 16891|        40 Ellis St.|  674-555-0110|John Jackson|  230-555-0194|
|  8396|5415 San Gabriel Dr.|  230-555-0191| Calvin Raji|  230-555-0191|
+------+--------------------+--------------+------------+--------------+
```

## Hbase 更改表名

```shell
hbase shell> disable 'tableName'
hbase shell> snapshot 'tableName', 'tableSnapshot'
hbase shell> clone_snapshot 'tableSnapshot', 'newTableName'
hbase shell> delete_snapshot 'tableSnapshot'
hbase shell> drop 'tableName'
```

## Hbase 更改 TTL

```shell
desc 'car_data_na_rt'
disable 'car_data_na_rt'
alter 'car_data_na_rt', {NAME => 'd', TTL => '15552000' }
enable 'car_data_na_rt'
```

## 参考文献

- [Apache Spark - Apache HBase Connector](https://github.com/hortonworks-spark/shc)
