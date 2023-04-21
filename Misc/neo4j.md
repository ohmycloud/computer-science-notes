删除节点

```sql
match (n:Person ) where n.name starts with 'Andrea' delete n
```

断开连接:

```bash
:server disconnect
```

## 只有企业版才可以创建数据库

```bash
Creating databases test
```

MERGE (c:Rakudo { id:event.id, name: coalesce(event.name, "MISSING"), age: coalesce(event.age, -1) })

## 使用 PySpark 连接 neo4j

PySpark Shell:

```bash
pyspark --packages graphframes:graphframes:0.7.0-spark2.4-s_2.11 --repositories https://repos.spark-packages.org
```

PySpark Submit 

```bash
spark-submit --packages graphframes:graphframes:0.7.0-spark2.4-s_2.11 --repositories https://repos.spark-packages.org test.py
```

## 参考连接

- https://neo4j.com/blog/streaming-graphs-combining-kafka-neo4j/
- https://www.freecodecamp.org/news/how-to-ingest-data-into-neo4j-from-a-kafka-stream-a34f574f5655/
- https://neo4j.com/labs/kafka/4.0/kafka-connect/
- https://tech.meituan.com/2021/04/01/nebula-graph-practice-in-meituan.html
- https://zhuanlan.zhihu.com/p/245658174
