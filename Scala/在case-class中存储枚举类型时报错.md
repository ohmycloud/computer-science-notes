```scala
case class Cumulant(
                     orderId: String,
                     deviceId: String,
                     cumulantKind: CumulantKind,
                     cumulantValue: Double,
                     relTime: Long
                   )
```

报了如下错误:

```
Exception in thread "main" java.lang.UnsupportedOperationException: No Encoder found for com.thinkenergy.core.common.CumulantItem.CumulantKind
- field (class: "scala.Enumeration.Value", name: "cumulantKind")
- root class: "com.thinkenergy.model.Cumulant"
```

添加如下隐式转换:

```scala
  implicit def caseEncoders: org.apache.spark.sql.Encoder[Cumulant] =
    org.apache.spark.sql.Encoders.kryo[Cumulant]
```

Map 的键中也使用了 Enum 类型值作为键，也报编码错误:

Exception in thread "main" java.lang.UnsupportedOperationException: No Encoder found for com.thinkenergy.core.common.CumulantItem.CumulantKind
- map key class: "scala.Enumeration.Value"
- root class: "scala.collection.immutable.Map"

添加如下隐式转换:

```scala
  implicit def enumEncoders: org.apache.spark.sql.Encoder[Map[CumulantKind, Cumulant]] =
    org.apache.spark.sql.Encoders.kryo[Map[CumulantKind, Cumulant]]
```

就可以运行了。