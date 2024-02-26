Sign on the dottred line:
#box(width: 1fr, repeat[。])

#set text(10pt)
#v(8pt, weak: true)
#align(right)[等光落下啊]

#show outline.entry.where(
  level: 1
): it => {
  v(12pt, weak: true)
  strong(it)
}

#outline(
  indent: auto,

  fill: box(width: 1fr, repeat[-])
  
)

= Apache Spark

Spark 在流式处理中的应用

= Apache Flink

Flink 在流式处理中的应用

= Apache AirFlow

我不明白

== 定时任务

#lorem(10)

#lorem(10)

#lorem(20)

#lorem(20)

#let chinese(start: "\u{4E00}", end: "\u{9FA5}") = {
  let characters = ()
  for i in range("\u{FE10}".to-unicode(), "\u{FE1F}".to-unicode()) {
    characters.push(str.from-unicode(i))
  }
  for i in range(start.to-unicode(), end.to-unicode()) {
    characters.push(str.from-unicode(i))
  }
  characters
}

#let lorem(number) = {
  for (idx, value) in chinese().enumerate() {
    if idx == number {
      return
    }
    value
  }
}

= 随机数生成器

#lorem(30)

= 需要随机数生成器

#lorem(80)

