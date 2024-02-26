#import "@preview/splash:0.3.0": *

#let make-title(title: none, author: none, date: none, description: none) = [
  #set align(center)
  = #title
  #v(1em)
  #text(style: "italic", description)
  #v(1em)
  / 设计者: #author
  / 日期: #date
  #v(3em)
]

#make-title(
    title: "Serde 序列化和反序列化",
    author: "ohmycloud",
    date: "2023-09-19",
    description: "结构体的序列化和反序列化"
)

#outline(
    title: "目录",
    target: heading.where(level: 1)
)

#pagebreak()

#show heading.where(level: 1): it => {
    align(center)[#text(xcolor.cyan)[ *#it*]]
    v(0.75em)
}

#show heading.where(level: 2): it => {
    text(red)[ *#it*]
    v(0.6em)
}

#show heading.where(level: 3): it => {
    text(red)[ *#it*]
    v(0.6em)
}

#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)

= 项目目标

+ 对结构体进行序列化, 生成 JSON 字符串。
+ 把 JSON 字符串反序列化为结构体。

= 新建项目

新建一个 bin 项目:

```bash
cargo new serde_demo
cd serde_demo
```

== 添加依赖

```bash
cargo add serde --features=derive
cargo add serde_json
```

添加依赖后, Cargo.toml 中的内容如下:

```toml
[package]
name = "serde_demo"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0.188", features = ["derive"] }
serde_json = "1.0.107"
```

#pagebreak()

= 演示代码

```rust
use serde::{Deserialize, Serialize};
use serde_json::Result;

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Bar {
    a: Option<u8>,
    b: Option<String>,
}

#[derive(Debug, PartialEq, Deserialize, Serialize)]
pub struct Foo<'a> {
    x: Option<&'a str>,
    y: Bar
}

fn main() -> Result<()> {
    let foo: Foo = serde_json::from_str(r#"{"x": "1", "y":{"a": 5, "b": "rakulang"}}"#)?;
    println!("{:?}", foo);

    let foo = Foo {
        x: Some("1"),
        y: Bar {
            a: Some(5),
            b: Some("rakulang".to_string()),
        }
    };

    let serialized_foo = serde_json::to_string(&foo).unwrap();
    println!("{:?}", serialized_foo);

    Ok(())
}
```

运行 `cargo run` 输出:

```bash
Foo { x: Some("1"), y: Bar { a: Some(5), b: Some("rakulang") } }
"{\"x\":\"1\",\"y\":{\"a\":5,\"b\":\"rakulang\"}}"
```
