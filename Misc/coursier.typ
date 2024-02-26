#let box_title(body) = {
  set text(weight: "regular")
  show: box.with(
    fill: luma(249),
    inset: 1em,
    radius: 3pt,
    baseline: 0.4em,
    width: 100%,
  )
  [#body]
}

#show heading.where(level: 1): it => {
    set text(size: 18pt, fill: red)
    align(center)[#it.body]
}

#show heading.where(level: 2): it => {
    set text(size: 16pt, fill: rgb(54, 123, 128))
    align(center)[#box_title(it.body)]
}

#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)


= 使用 coursier 安装 Scala

== 安装

在 #underline(link("https://get-coursier.io/docs/cli-installation")[get-coursier.io])
下载 Coursier。

== 启动

下载并设置完毕后, 启动 scala3 的 REPL:

```bash
cs launch scala3
```

== 加载依赖

启动 Scala3 的时候, 加载依赖:

```bash
cs launch org.typelevel::cats-effect:3.5.2 scala3
import cats.effect.IO
import cats.implicits._
import cats.effect.unsafe.implicits.global
```

加载多个依赖:

```bash
cs launch org.typelevel::cats-effect:3.5.2 co.fs2::fs2-core:3.9.3 scala3
import fs2._
```

多个依赖之间使用空格分隔。

单独下载依赖:

```bash
cs fetch -p org.typelevel::cats-effect:3.5.2
```

== 在 REPL 中加载 object

```scala
import cats.effect.IO

object model {
  opaque type Currency = String
  
  object Currency {
    def apply(name: String): Currency = name
    extension (currency: Currency) def name: String = currency
  }
}

object IoExercise extends App {
  import model._
  import cats.implicits._
  
  def exchangeTable(from: Currency): IO[Map[Currency, BigDecimal]] = {
    IO.delay(exchangeRatesTableApiCall(from.name)
      .map(x => (Currency(x._1), x._2))
    )
  }    
}
```
