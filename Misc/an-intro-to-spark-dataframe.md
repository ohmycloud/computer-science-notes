## Spark-Shell

spark-shell 能帮助我们很快地在本地进行代码测试, 如果设置了全局环境变量, 则在终端命令行中输入 spark-shell 即可进入:

```bash
> spark-shell
```

注意到终端显示的这三行信息：

```
Spark context Web UI available at http://192.168.1.11:4040
Spark context available as 'sc' (master = local[*], app id = local-1502291515378).
Spark session available as 'spark'.
```

就是在浏览器中输入  `http://192.168.1.11:4040` 即可查看任务的执行情况, `sc` 为 spark 上下文, `spark` 为 SparkSession。


## 读取 json 数据源

```
// 读取当前目录中的 json 文件作为数据源
val df = spark.read.json(".")
df.show()

// 输出表结构
df.printSchema()
```

可以读取某一个 json 文件, 根据官网给出的例子, 假设有一个 people.json 的文件:

```
{"name":"Michael"}
{"name":"Andy", "age":30}
{"name":"Justin", "age":19}
```

我们在 spark-shell 中读取这个文件:

```
// 导入 implicits 这个包是为了使用 $-记法
import spark.implicits._
df = spark.read.json("/Users/ohmyfish/people.json")
df.printSchema() // 可以输入 print 按 tab 键自动补全

// root
// |-- age: long (nullable = true)
// |-- name: string (nullable = true)

```

## select 操作

`select` 可以一次选择一列或多列, select 的时候还可以给列起别名:

```
// 选择某一列
df.select("name").show()

// +-------+
// |   name|
// +-------+
// |Michael|
// |   Andy|
// | Justin|
// +-------+

// 选择多列并给其中一列起别名
df.select(df("name"), df("age").alias("secret") ).show()

// +-------+------+
// |   name|secret|
// +-------+------+
// |Michael|  null|
// |   Andy|    30|
// | Justin|    19|
// +-------+------+
```

```
// 使用 $ 记号来选择某些列
df.select($"name", $"age" + 1).show()
// +-------+---------+
// |   name|(age + 1)|
// +-------+---------+
// |Michael|     null|
// |   Andy|       31|
// | Justin|       20|
// +-------+---------+
```

但是运算后列的名字变成 `(age + 1)`, 我们也可以给改列起别名:

```
df.select($"name", $"age" + 1 as "secret").show()

// +-------+------+
// |   name|secret|
// +-------+------+
// |Michael|  null|
// |   Andy|    31|
// | Justin|    20|
// +-------+------+
```

## Filter 操作

`filter` 用来过滤 dataframe, 它和 `where` 是同义词。
```
// 选择年纪大于 21 的人

df.filter($"age" > 21).show()

// 选择名字包含 andy 的人
df.filter($"name" contains "andy").show()

// +---+-----+
// |age| name|
// +---+-----+
// | 30|Sandy|
// | 19|Jandy|
// +---+-----+

// 选择名字包含 andy 且年龄大于 19 的人

df.filter($"name" contains "andy" and $"age" > 19).show()

// +---+-----+
// |age| name|
// +---+-----+
// | 30|Sandy|
// +---+-----+
```

`where` 的作用和 `filter` 相同:

```
df.where("age > 19 or age <28").show()
```

## groupby 操作

```
// 分组之后进行聚合
import org.apache.spark.sql.functions._
df.groupby("name").agg(
  countDistinct("name") as "people_count",
  sum("age") as "total_age"
).show()
```

##  join 操作

join 有 `leftouter`, `rightouter`, `inner`, 平常用的比较多:

```
qr_count_df.join(
      qr_newer_df,
      qr_count_df("app_key")===qr_newer_df("app_key") &&
      qr_count_df("qr_key")===qr_newer_df("qr_key"),
      "leftouter"
    )
```

字段进行比较的时候用的是三个等号, 多个条件之间用 `&&` 进行连接。

## withColumn 和  withColumnRenamed

我们经常需要在计算完之后的结果 DataFrame 中新增一列, 例如我们新增一列日期:

```
import org.apache.spark.sql.functions.lit
val date = "2017-08-10"
df.withColumn("day", lit(date))
```

添加列的同时还可以重命名某一列:

```
df.withColumnRenamed("id", "idx")
```

## 将 DataFrame 注册为虚拟表

```
df.registerTempTable("people")
spark.sql("select * from people").show()

// +----+-------+
// | age|   name|
// +----+-------+
// |null|Michael|
// |  30|  Sandy|
// |  19| Justin|
// |  19|  Jandy|
// +----+-------+
```

目前我们离线代码中用的比较多的是 Spark SQL, 其性能和 RDD 差不多。但是对于复杂的计算, 使用 mysql 其可读性就变的比较差。建议工作中多使用 DataFrame。

## 从 Mysql 中返回 DataFrame

DataFrame 还可以来自 MySQL 数据源, 我们可以定义一个函数从 MySQL 中读取数据并返回一个 DataFrame:

```
def read_from_mysql(sparkSession: SparkSession, table: String): DataFrame = {
  val jdbcDF = sparkSession.read
    .format("jdbc")
    .option("driver", "com.mysql.jdbc.Driver")
    .option("url", s"${url}")
    .option("dbtable", table)
    .option("user", s"${username}")
    .option("password", s"${password}")
    .load()
  return jdbcDF

// 获取 ald_code 的信息
val code_df = read_from_mysql(spark, "(select id, qr_key from ald_code) as code_df")
```

`table` 是一个字符串, 但是它的格式为 "(select xx from table) as sth_df" , 否则会报错。比较好的做法是加上分区。

RDD 和 DataFrame 的性能对比：

https://community.hortonworks.com/articles/42027/rdd-vs-dataframe-vs-sparksql.html

RDD, DataFrame, DataSet 三者的比较：

https://stackoverflow.com/questions/31508083/difference-between-dataframe-and-rdd-in-spark
