使用 Dolphinscheduler 工具栏中的 [Spark](https://dolphinscheduler.apache.org/en-us/docs/latest/user_doc/guide/task/spark.html) Task 提交 Spark 程序时, 


按照如下选项参数配置运行:

```bash
--conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6 \
--conf spark.eventLog.enabled=false \
```

报了选项不存在:

```bash
Error: Unknown option --conf
Error: Unknown argument 'spark.dynamicAllocation.enabled=false'
Error: Unknown option --conf
Error: Unknown argument 'spark.yarn.submit.waitAppCompletion=false' 
```

查看日志，可以看到 spark-submit 脚本的内容如下:

```
 spark task params {"mainArgs":"--conf spark.dynamicAllocation.enabled=false \\\n--conf spark.yarn.submit.waitAppCompletion=false \\\n--conf spark.blacklist.timeout=30s \\\n--conf spark.sql.shuffle.partitions=6 \\\n--conf spark.eventLog.enabled=false \\","driverMemory":"3G","executorMemory":"3G","programType":"SCALA","mainClass":"com.thinkenergy.AlarmApp","driverCores":"1","deployMode":"cluster","executorCores":"3","appName":"alarmAppDev","mainJar":{"id":4},"sparkVersion":"SPARK2","numExecutors":"3","localParams":[],"others":"","resourceList":[{"res":"application.conf","name":"application.conf","id":3},{"res":"log4j.properties","name":"log4j.properties","id":5}]}
[INFO] 2021-12-16 10:21:01.038  - [taskAppId=TASK-42-264747-356895]:[125] - spark task command: ${SPARK_HOME2}/bin/spark-submit --master yarn --deploy-mode cluster --class com.thinkenergy.AlarmApp --driver-cores 1 --driver-memory 3G --num-executors 3 --executor-cores 3 --executor-memory 3G --name alarmAppDev --queue default byd-alarm-1.0.jar --conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6 \
--conf spark.eventLog.enabled=false \
```

选项参数填写的问题(最后一个参数不应该包括右斜杠 `\`)。

修改了一下选项参数：

```
--conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6
```

在 Dolphinscheduler 的日志中可以看到详细的提交命令:

[INFO] 2021-12-16 10:39:38.980  - [taskAppId=TASK-42-264807-356979]:[115] - create dir success /tmp/dolphinscheduler/exec/process/3/42/264807/356979
[INFO] 2021-12-16 10:39:39.197  - [taskAppId=TASK-42-264807-356979]:[75] - spark task params {"mainArgs":"","driverMemory":"3G","executorMemory":"3G","programType":"SCALA","mainClass":"com.thinkenergy.AlarmApp","driverCores":"1","deployMode":"cluster","executorCores":"3","appName":"alarmAppDev","mainJar":{"id":4},"sparkVersion":"SPARK2","numExecutors":"3","localParams":[],"others":"--conf spark.dynamicAllocation.enabled=false \\\n--conf spark.yarn.submit.waitAppCompletion=false \\\n--conf spark.blacklist.timeout=30s \\\n--conf spark.sql.shuffle.partitions=6 \\\n--conf spark.eventLog.enabled=false","resourceList":[{"res":"application.conf","name":"application.conf","id":3},{"res":"log4j.properties","name":"log4j.properties","id":5}]}
[INFO] 2021-12-16 10:39:39.207  - [taskAppId=TASK-42-264807-356979]:[125] - spark task command: ${SPARK_HOME2}/bin/spark-submit --master yarn --deploy-mode cluster --class com.thinkenergy.AlarmApp --driver-cores 1 --driver-memory 3G --num-executors 3 --executor-cores 3 --executor-memory 3G --name alarmAppDev --queue default --conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6 \
--conf spark.eventLog.enabled=false byd-alarm-1.0.jar
[INFO] 2021-12-16 10:39:39.207  - [taskAppId=TASK-42-264807-356979]:[87] - tenantCode user:bigdata, task dir:42_264807_356979
[INFO] 2021-12-16 10:39:39.207  - [taskAppId=TASK-42-264807-356979]:[92] - create command file:/tmp/dolphinscheduler/exec/process/3/42/264807/356979/42_264807_356979.command
[INFO] 2021-12-16 10:39:39.207  - [taskAppId=TASK-42-264807-356979]:[111] - command : #!/bin/sh
BASEDIR=$(cd `dirname $0`; pwd)
cd $BASEDIR
source /data/software/dolphinscheduler/conf/env/dolphinscheduler_env.sh
${SPARK_HOME2}/bin/spark-submit --master yarn --deploy-mode cluster --class com.thinkenergy.AlarmApp --driver-cores 1 --driver-memory 3G --num-executors 3 --executor-cores 3 --executor-memory 3G --name alarmAppDev --queue default --conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6 \
--conf spark.eventLog.enabled=false byd-alarm-1.0.jar
[INFO] 2021-12-16 10:39:39.207  - [taskAppId=TASK-42-264807-356979]:[327] - task run command:
sudo -u bigdata sh /tmp/dolphinscheduler/exec/process/3/42/264807/356979/42_264807_356979.command
[INFO] 2021-12-16 10:39:39.208  - [taskAppId=TASK-42-264807-356979]:[208] - process start, process id is: 3897
[INFO] 2021-12-16 10:39:41.208  - [taskAppId=TASK-42-264807-356979]:[129] -  -> 21/12/16 10:39:40 INFO client.RMProxy: Connecting to ResourceManager at host1/10.0.0.39:8032
	21/12/16 10:39:40 INFO yarn.Client: Requesting a new application from cluster with 3 NodeManagers
	21/12/16 10:39:40 INFO conf.Configuration: resource-types.xml not found
	21/12/16 10:39:40 INFO resource.ResourceUtils: Unable to find 'resource-types.xml'.
	21/12/16 10:39:40 INFO yarn.Client: Verifying our application has not requested more than the maximum memory capability of the cluster (8192 MB per container)
	21/12/16 10:39:40 INFO yarn.Client: Will allocate AM container, with 3456 MB memory including 384 MB overhead
	21/12/16 10:39:40 INFO yarn.Client: Setting up container launch context for our AM
	21/12/16 10:39:40 INFO yarn.Client: Setting up the launch environment for our AM container
	21/12/16 10:39:40 INFO yarn.Client: Preparing resources for our AM container
	21/12/16 10:39:40 INFO yarn.Client: Uploading resource file:/tmp/dolphinscheduler/exec/process/3/42/264807/356979/byd-alarm-1.0.jar -> hdfs://host1:8020/user/bigdata/.sparkStaging/application_1637577039070_0094/byd-alarm-1.0.jar
[INFO] 2021-12-16 10:39:43.019  - [taskAppId=TASK-42-264807-356979]:[217] - process has exited, execute path:/tmp/dolphinscheduler/exec/process/3/42/264807/356979, processId:3897 ,exitStatusCode:0
[INFO] 2021-12-16 10:39:43.020  - [taskAppId=TASK-42-264807-356979]:[444] - find app id: application_1637577039070_0094
[INFO] 2021-12-16 10:39:43.025  - [taskAppId=TASK-42-264807-356979]:[404] - appId:application_1637577039070_0094, final state:RUNNING_EXECUTION
[INFO] 2021-12-16 10:39:43.208  - [taskAppId=TASK-42-264807-356979]:[129] -  -> 21/12/16 10:39:42 INFO yarn.Client: Uploading resource file:/tmp/spark-fe66bab6-83da-426a-ac17-f0e01ef4db01/__spark_conf__5599617401405166148.zip -> hdfs://host1:8020/user/bigdata/.sparkStaging/application_1637577039070_0094/__spark_conf__.zip
	21/12/16 10:39:42 INFO spark.SecurityManager: Changing view acls to: bigdata
	21/12/16 10:39:42 INFO spark.SecurityManager: Changing modify acls to: bigdata
	21/12/16 10:39:42 INFO spark.SecurityManager: Changing view acls groups to: 
	21/12/16 10:39:42 INFO spark.SecurityManager: Changing modify acls groups to: 
	21/12/16 10:39:42 INFO spark.SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(bigdata); groups with view permissions: Set(); users  with modify permissions: Set(bigdata); groups with modify permissions: Set()
	21/12/16 10:39:42 INFO conf.HiveConf: Found configuration file file:/etc/hive/conf.cloudera.hive/hive-site.xml
	21/12/16 10:39:42 INFO yarn.Client: Submitting application application_1637577039070_0094 to ResourceManager
	21/12/16 10:39:42 INFO impl.YarnClientImpl: Submitted application application_1637577039070_0094
	21/12/16 10:39:42 INFO yarn.Client: Application report for application_1637577039070_0094 (state: ACCEPTED)
	21/12/16 10:39:42 INFO yarn.Client: 
		 client token: N/A
		 diagnostics: N/A
		 ApplicationMaster host: N/A
		 ApplicationMaster RPC port: -1
		 queue: root.users.bigdata
		 start time: 1639622382631
		 final status: UNDEFINED
		 tracking URL: http://host1:8088/proxy/application_1637577039070_0094/
		 user: bigdata
	21/12/16 10:39:42 INFO util.ShutdownHookManager: Shutdown hook called
	21/12/16 10:39:42 INFO util.ShutdownHookManager: Deleting directory /tmp/spark-fe66bab6-83da-426a-ac17-f0e01ef4db01
	21/12/16 10:39:42 INFO util.ShutdownHookManager: Deleting directory /tmp/spark-590c219b-b905-43a0-9e51-1014e3d3e355

但是报了: No configuration setting found for key 'checkpoint', 需要传递 --files 参数:

```
--conf spark.dynamicAllocation.enabled=false \
--conf spark.yarn.submit.waitAppCompletion=false \
--conf spark.blacklist.timeout=30s \
--conf spark.sql.shuffle.partitions=6 \
--conf spark.eventLog.enabled=false \
--files application.conf,log4j.properties
```

又报了权限问题:

Caused by: org.apache.hadoop.security.AccessControlException: Permission denied: user=bigdata, access=WRITE, inode="/apps/checkpoint/byd-alarm-dev/can_data_latest/offsets":hdfs:supergroup:drwxr-xr-x

使用 chmod 修改一下 checkpoint 的权限为 775:

```bash
hdfs dfs -chmod -R 775 /apps/checkpoint/byd-alarm-dev
```

hdfs 文件权限如下:

```
[root@host3 byd-alarm]# hdfs dfs -ls /apps/checkpoint/byd-alarm-dev
Found 3 items
drwxrwxr-x   - hdfs supergroup          0 2021-11-30 11:43 /apps/checkpoint/byd-alarm-dev/all-warn-sink
drwxrwxr-x   - hdfs supergroup          0 2021-11-30 11:43 /apps/checkpoint/byd-alarm-dev/can_data_latest
drwxrwxr-x   - hdfs supergroup          0 2021-11-30 11:43 /apps/checkpoint/byd-alarm-dev/latest-warn-sink
```


775 的权限仍不让写, 改为 777：

```
User class threw exception: org.apache.spark.sql.streaming.StreamingQueryException: Permission denied: user=bigdata, access=WRITE, inode="/apps/checkpoint/byd-alarm-dev/can_data_latest/offsets":hdfs:supergroup:drwxrwxr-x
```

