## Spark 中的 --files 参数与 ConfigFactory 工厂方法

## scala 对象

以前有个大数据项目做小程序统计，读取 HDFS 上的 Parquet 文件，统计完毕后，将结果写入到 MySQL 数据库。首先想到的是将 MySQL 的配置写在代码里面:

```scala
val jdbcUrl  = "jdbc:mysql://127.0.0.1:6606/test?useUnicode=true&characterEncoding=utf-8&autoReconnect=true&failOverReadOnly=false&useSSL=false"
val user     = "root"
val password = "averyloooooongword"
val driver   = "com.mysql.jdbc.Driver"
```

## properties 文件

如果是测试，生产环境各有一套，那上面的代码就要分别复制俩份，不便于维护！后来知道了可以把配置放在 `resources` 目录下, 针对本地，测试和生产环境，分别创建不同的 **properties** 文件：

```
conf.properties  
conf_product.properties 
env.properties  
local.properties
```

例如其中的 **conf.properties** 内容如下：

```
#  测试环境配置

## 数据库配置
jdbc.url=jdbc:mysql://10.0.0.11:3306/ald_xinen_test?useUnicode=true&characterEncoding=utf-8&autoReconnect=true&failOverReadOnly=false
jdbc.user=aldwx
jdbc.pwd=123456
jdbc.driver=com.mysql.jdbc.Driver

# parquet 文件目录
tongji.parquet=hdfs://10.0.0.212:9000/ald_log_parquet
```

然后在代码里面读取 resource 文件中的配置：

```java
    /**
     * 根据 key 获取 properties 文件中的 value
     * @param key properties 文件中等号左边的键
     * @return 返回 properties 文件中等号右边的值
     */
    public static String getProperty(String key) {
        Properties properties = new Properties();
        InputStream in = ConfigurationUtil.class.getClassLoader().getResourceAsStream(getEnvProperty("env.conf"));
        try {
            properties.load(in);
            in.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return (String) properties.get(key);
    }
```

这样解决了多个环境中配置不同的问题，只需要复制多个 properties 文件，根据需要修改就行。但是这种方法不是最优的，因为配置不是结构化的，而是通过注释分割了不同的配置。

## conf 文件

resources 目录下的文件如下：

```
application.conf              
application.production.conf      
application.local.conf             
log4j.properties              
metrics.properties
```

`ConfigFactory` 工厂方法默认会读取 `resources` 目录下面名为 **application.conf** 的文件：

```
# Spark 相关配置
spark {
  master                   = "local[2]"
  streaming.batch.duration = 5001  // Would normally be `ms` in config but Spark just wants the Long
  eventLog.enabled         = true
  ui.enabled               = true
  ui.port                  = 4040
  metrics.conf             = metrics.properties
  checkpoint.path          = "/tmp/checkpoint/telematics-local"
  stopper.port             = 12345
  spark.cleaner.ttl        = 3600
  spark.cleaner.referenceTracking.cleanCheckpoints = true
}

# Kafka 相关配置
kafka {

  metadata.broker.list = "localhost:9092"
  zookeeper.connect    = "localhost:2181"

  topic.dtcdata {
    name = "dc-diagnostic-report"
    partition.num = 1      
    replication.factor = 1  
  }

  group.id             = "group-rds"
  timeOut              = "3000"
  bufferSize           = "100"
  clientId             = "telematics"
  key.serializer.class = "kafka.serializer.StringEncoder"
  serializer.class     = "com.wm.dtc.pipeline.kafka.SourceDataSerializer"
//  serializer.class     = "kafka.serializer.DefaultEncoder"
}

# MySQL 配置
mysql {
  dataSource.maxLifetime              = 800000
  dataSource.idleTimeout              = 600000
  dataSource.maximumPoolSize          = 10
  dataSource.cachePrepStmts           = true
  dataSource.prepStmtCacheSize        = 250
  dataSource.prepStmtCacheSqlLimit    = 204800
  dataSource.useServerPrepStmts       = true

  jdbcUrl="jdbc:mysql://127.0.0.1:6606/wmdtc?useUnicode=true&characterEncoding=utf-8&autoReconnect=true&failOverReadOnly=false&useSSL=false"
  jdbcDriver="com.mysql.jdbc.Driver"
  dataSource.user="root"
  dataSource.password="123456"
}
```

为了验证，我创建了一个 Object 对象：

```scala
package allinone
import com.typesafe.config.ConfigFactory
import scopt.OptionParser

object SparkFilesArgs extends App  {
  val config = ConfigFactory.load()
  val sparkConf = config.getConfig("spark")
  val sparkMaster = sparkConf.getString("master")
  val sparkDuration = sparkConf.getLong("streaming.batch.duration")
  println(sparkMaster, sparkDuration)
}
```

如果我直接运行就会打印：

```
(local[2],5001)
```

确实是 **application.conf** 文件中 Spark 的配置。

但是生产环境我们打算使用另外一个配置文件 **application.production.conf**:

```
spark {
  master = "yarn"
  streaming.batch.duration = 5002
  eventLog.enabled=true
  ui.enabled = true
  ui.port = 4040
  metrics.conf = metrics.properties
  checkpoint.path = "/tmp/telematics"
  stopper.port = 12345
  spark.cleaner.ttl = 3600
  spark.cleaner.referenceTracking.cleanCheckpoints = true
}

##cassandra相关配置
cassandra {
  keyspace = wmdtc
  cardata.name = can_signal
  trip.name = trip
  latest.name = latest
  latest.interval = 15000

  write.consistency_level = LOCAL_ONE
  read.consistency_level = LOCAL_ONE
  concurrent.writes = 24
  batch.size.bytes = 65536
  batch.grouping.buffer.size = 1000
  connection.keep_alive_ms = 300000
  auth.username = cihon
  auth.password = cihon
}

kafka {
  metadata.broker.list = "test:9092"
  zookeeper.connect = "test:2181"

  topic.obddata {
    name = "test"
  }

  group.id = "can_signal"
  timeOut = "3000"
  bufferSize = "100"
  clientId = "telematics"

  key.serializer.class = "kafka.serializer.StringEncoder"
  serializer.class = "com.wm.telematics.pipeline.kafka.SourceDataSerializer"

}

akka {
  loglevel = INFO
  stdout-loglevel = WARNING
  loggers = ["akka.event.slf4j.Slf4jLogger"]
}

##geoService接口URL
webservice {
  url = "http://192.168.1.1:8088/map/roadmessage"
}

##geoService相关配置
geoservice {
  timeout = 3
  useRealData = false
}
```

既然 ConfigFactory 方法默认读取 `application.conf` 文件，但是

```
val config = ConfigFactory.load()
```

相当于：

```
val config = ConfigFactory.load("application.conf")
```

但是 `load` 方法也接受参数：*resourceBasename*:

```
val config = ConfigFactory.load("application.production") // 加载生产环境的配置
```

这样在代码里面通过加载不同的配置文件实现本地、测试、生产环境的切换和部署，但是在代码里面读取配置还是不够优美！所以我们有 Spark 的 `--files` 命令行选项。顾名思义，显而易见，也正如[官网](http://spark.apache.org/docs/latest/submitting-applications.html)所描述的那样, `--files` 参数后面的值是逗号分割的文本文件, 里面有一个 *.conf* 文件, load 方法会加载 `--files` 选项传递过来的配置文件：

```bash
#!/bin/sh

CONF_DIR=/root/telematics/resources
APP_CONF=application.production.conf
EXECUTOR_JMX_PORT=23339
DRIVER_JMX_PORT=2340

spark-submit \
  --name WM_telematics \
  --class allinone.SparkFilesArgs \
  --master local[*] \
  --deploy-mode client \
  --driver-memory 2g \
  --driver-cores 2 \
  --executor-memory 1g \
  --executor-cores 3 \
  --num-executors 3 \
  --conf "spark.executor.extraJavaOptions=-Dconfig.resource=$APP_CONF -Dcom.sun.management.jmxremote.port=$EXECUTOR_JMX_PORT -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=`hostname`" \
  --conf "spark.driver.extraJavaOptions=-Dconfig.resource=$APP_CONF -Dcom.sun.management.jmxremote.port=$DRIVER_JMX_PORT -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=`hostname`" \
  --conf spark.executor.memoryOverhead=4096 \
  --conf spark.driver.memoryOverhead=2048 \
  --conf spark.yarn.maxAppAttempts=2 \
  --conf spark.yarn.submit.waitAppCompletion=false \
  --conf spark.network.timeout=1800s \
  --conf spark.scheduler.executorTaskBlacklistTime=30000 \
  --conf spark.core.connection.ack.wait.timeout=300s \
  --files $CONF_DIR/$APP_CONF,$CONF_DIR/log4j.properties,$CONF_DIR/metrics.properties \
  /Users/ohmycloud/work/cihon/app-1.0-SNAPSHOT.jar
```

它打印：

```
(local[*],5002)
```

因为我在命令行选项中指定了 master 为 `local[*]`, 配置文件为 `application.production.conf`。

## References

- [Using typesafe config with Spark on Yarn](https://stackoverflow.com/questions/40507436/using-typesafe-config-with-spark-on-yarn)
- [Externalize properties – typesafe config](http://www.itversity.com/topic/externalize-properties-typesafe-config/)
- [Spark Context and Spark Configuration](http://www.itversity.com/topic/spark-context-and-spark-configuration/)
- [How to specify custom conf file for Spark Standalone's master?](https://stackoverflow.com/questions/43430596/-how-to-specify-custom-conf-file-for-spark-standalones-master)
- [Scala Load Configuration With PureConfig](https://dzone.com/articles/scala-load-configuration-with-pureconfig)
- [Example: Running a Spark application with optional parameters](https://console.bluemix.net/docs/services/AnalyticsforApacheSpark/spark_submit_example.html#example-running-a-spark-application-with-optional-parameters)
