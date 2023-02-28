## 依赖分析

```bash
mvn dependency:analyze
```

使用 maven 的 **analyze** 命令分析依赖中可能存在的问题(**WARNING**):

```xml
[WARNING] Some problems were encountered while building the effective settings
[WARNING] expected START_TAG or END_TAG not TEXT (position: TEXT seen ... artifacts.\r\n   |\r\n   | Default: ${user.home}/.m2/repository\r\n  <l... @53:5)  @ D:\software\apache-maven-3.6.3\bin\..\conf\settings.xml, line 53, column 5
...
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b06-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b07-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b08-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b11-SNAPSHOT is missing, no dependency information available
...
[WARNING]  Expected all dependencies to require Scala version: 2.11.12
[WARNING]  com.twitter:chill_2.11:0.9.3 requires scala version: 2.11.12
[WARNING]  org.apache.spark:spark-core_2.11:2.4.6 requires scala version: 2.11.12
[WARNING]  org.json4s:json4s-jackson_2.11:3.5.3 requires scala version: 2.11.11
[WARNING] Multiple versions of scala libraries detected!
...
[WARNING]  Expected all dependencies to require Scala version: 2.11.12
[WARNING]  com.twitter:chill_2.11:0.9.3 requires scala version: 2.11.12
[WARNING]  org.apache.spark:spark-core_2.11:2.4.6 requires scala version: 2.11.12
[WARNING]  org.json4s:json4s-jackson_2.11:3.5.3 requires scala version: 2.11.11
[WARNING] Multiple versions of scala libraries detected!
...
[WARNING] Used undeclared dependencies found:
[WARNING]    org.scala-lang:scala-library:jar:2.11.12:compile
[WARNING]    org.scala-lang:scala-reflect:jar:2.11.8:compile
[WARNING]    com.typesafe:config:jar:1.3.3:compile
[WARNING]    com.typesafe.akka:akka-stream_2.11:jar:2.5.23:compile
[WARNING]    org.apache.hadoop:hadoop-common:jar:3.0.0-cdh6.2.0:compile
[WARNING]    com.typesafe.play:play-ws-standalone_2.11:jar:2.0.8:compile
[WARNING]    org.apache.spark:spark-catalyst_2.11:jar:2.4.6:compile
[WARNING]    com.typesafe.play:play-json_2.11:jar:2.7.4:compile
[WARNING]    org.glassfish.hk2.external:javax.inject:jar:2.4.0-b34:compile
[WARNING]    com.typesafe.akka:akka-actor_2.11:jar:2.5.23:compile
[WARNING] Unused declared dependencies found:
[WARNING]    com.github.nscala-time:nscala-time_2.11:jar:2.20.0:compile
[WARNING]    junit:junit:jar:4.12:test
[WARNING]    mysql:mysql-connector-java:jar:8.0.13:compile
[WARNING]    org.apache.hbase:hbase:pom:2.1.0-cdh6.2.0:compile
[WARNING]    org.apache.hbase:hbase-server:jar:2.1.0-cdh6.2.0:compile
[WARNING]    org.apache.hbase:hbase-protocol:jar:2.1.0-cdh6.2.0:compile
```

## Expected all dependencies to require Scala version: 2.11.12

在 `scala-maven-plugin` 插件的配置中添加 **scalaCompatVersion** 和 **scalaVersion**:

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <version>${scala-maven-plugin.version}</version>
                <configuration>
                    <scalaCompatVersion>${scala.binary.version}</scalaCompatVersion>
                    <scalaVersion>${scala.version}</scalaVersion>
                </configuration>
```

## The POM for org.glassfish:javax.el:jar:3.0.1-b06-SNAPSHOT is missing

```
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b06-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b07-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b08-SNAPSHOT is missing, no dependency information available
[WARNING] The POM for org.glassfish:javax.el:jar:3.0.1-b11-SNAPSHOT is missing, no dependency information available
```

使用 `mvn clean package` 命令打包时, 报了一个警告: **The POM for org.glassfish:javax.el:jar:3.0.1-b06-SNAPSHOT is missing**。原因是 **hbase-server** 依赖了 3.0.1 版本的 `org.glassfish:javax.el`，使用 `exclusion` 排除该依赖:

```bash
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-server</artifactId>
            <version>${hbase.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>org.glassfish</groupId>
                    <artifactId>javax.el</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
```

## 参考链接

https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
https://stackoverflow.com/questions/63659733/maven-shade-overlapping-classes-warning
https://stackoverflow.com/questions/19987080/maven-shade-plugin-uber-jar-and-overlapping-classes
https://maven.apache.org/plugins/maven-shade-plugin/examples/includes-excludes.html
https://maven.apache.org/plugins/maven-shade-plugin/examples/class-relocation.html