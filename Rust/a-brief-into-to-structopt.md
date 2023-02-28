# structopt

[structopt](https://crates.io/crates/structopt) 是用于解析命令行参数的 crate, 它通过定义一个结构体, 把结构体中的字段变成命令行中的选项(OPTION)或 FLAG。

看[官方文档](https://docs.rs/structopt/0.3.21/structopt/index.html)的一个例子来演示 structopt 的用法:

```rust
use std::path::PathBuf;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(name = "example", about = "An example of StructOpt usage.")]
struct Opt {
    /// Activate debug mode
    // short and long flags (-d, --debug) will be deduced from the field's name
    #[structopt(short, long)]
    debug: bool,

    /// Set speed
    // we don't want to name it "speed", need to look smart
    #[structopt(short = "v", long = "velocity", default_value = "42")]
    speed: f64,

    /// Input file
    #[structopt(parse(from_os_str))]
    input: PathBuf,

    /// Output file, stdout if not present
    #[structopt(parse(from_os_str))]
    output: Option<PathBuf>,

    /// Where to write the output: to `stdout` or `file`
    #[structopt(short)]
    out_type: String,

    /// File name: only required when `out-type` is set to `file`
    #[structopt(name = "FILE", required_if("out-type", "file"))]
    file_name: Option<String>,
}

fn main() {
    let opt = Opt::from_args();
    println!("{:?}", opt);
}
```

有一个 main 函数, 直接运行 `cargo run` 看看效果:

```bash
❯ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.03s
     Running `target\debug\structopt_example.exe`
error: The following required arguments were not provided:
    <input>
    -o <out-type>

USAGE:
    structopt_example.exe <input> -o <out-type> --velocity <speed>
```

它报错了, 错误提示很友好, 它要求我们必须提供两个参数 `<input>` 和 `-o <out-type>`。

按照 Rust 的提示, 我们运行 `cargo run D:\scripts -o csv`:

```bash
cargo run D:\scripts -o csv
    Finished dev [unoptimized + debuginfo] target(s) in 0.03s
     Running `target\debug\structopt_example.exe D:\scripts -o csv`
Opt { debug: false, speed: 42.0, input: "D:\\scripts", output: None, out_type: "csv", file_name: None }
```

运行成功了, 并打印出 Opt 结构体的一个实例:

```
Opt { debug: false, speed: 42.0, input: "D:\\scripts", output: None, out_type: "csv", file_name: None }
```

代码 `let opt = Opt::from_args();` 创建了一个 Opt 结构体的实例, 但是我们没有在 Opt 中定义名为 `from_args` 的方法, 那这个方法是怎么来的呢? 答案是 [StructOpt](https://docs.rs/structopt/0.3.21/structopt/trait.StructOpt.html) trait。**StructOpt** trait 中定义了一个名为 `from_args` 的方法:

```rust
pub fn from_args() -> Self where Self: Sized, 
```

这个方法用于从命令行参数构建结构体。`#[derive(StructOpt)]` 为 结构体 `Opt` 自动实现了 `from_args` 方法, 解语法糖之后, 类似于如下代码:

```rust
impl StructOpt for Opt {
    fn from_args() -> Opt {
        ...
    }
}
```

所以 `Opt::from_args()` 返回了一个 Opt 结构体的实例。

## 一个例子: 时间戳转换

```rust
use structopt::StructOpt;
use chrono::{FixedOffset, NaiveDateTime, TimeZone};


/// A command line used to convert unix timestamp and datetime
#[derive(Debug, StructOpt)]
struct Opt {
    /// unix timestamp
    #[structopt(short,long, help = "10位或13位的 unix 时间戳")]
    unixtime: String,
    /// datetime
    #[structopt(short, long, help = "日期时间")]
    datetime: String
}

fn main() {
    let opt = Opt::from_args();
    println!("{:?}", opt); // Opt { unixtime: "1234567890", datetime: "2021-05-08 17:10:12" }

    
    let unixtime = opt.unixtime.trim();
    let datetime = opt.datetime.trim();

    println!("{:?} {:?}", unixtime, datetime);

    let seconds = unixtime.parse::<i64>().unwrap() as i64 + 3600 * 8 as i64;
    // 将 unixtimestamp 转换位 datetime
    let datetime_from_unixtime = NaiveDateTime::from_timestamp(seconds, 0);

    println!("{:?}", datetime_from_unixtime.format("%Y-%m-%d %H:%M:%S").to_string());

    let formatter = "%Y-%m-%d %H:%M:%S";
    // let no_timezone = NaiveDateTime::parse_from_str(&datetime[..], formatter);
    let yes_timezone =  FixedOffset::east(8 * 3600).datetime_from_str(&datetime[..], formatter);

    if let Ok(dt) = yes_timezone {
        println!("{:?} {:?}", dt, dt.timestamp());
    }
}
```

使用 `cargo run` 运行:

```bash
cargo run -- --unixtime 1620465012 --datetime "  2021-05-08 17:10:12 "
```

注意第一个 `--` 是跳过给 cargo 传参。这会打印出:

```txt
Opt { unixtime: "1620465012", datetime: "  2021-05-08 17:10:12 " }
"1620465012" "2021-05-08 17:10:12"
"2021-05-08 17:10:12"
2021-05-08T17:10:12+08:00 1620465012
```

调试完成后, 使用 `cargo install --path .` 命令将编译后的二进制文件安装到 cargo 所在的 bin 目录下:

```bash
$HOME\.cargo\bin\u2t.exe
```

这时可以使用 `u2t` 这个命令并传参直接运行了:

```bash
u2t -d "2021-05-08 18:30:40" -u 1620469840
```

## 参考链接

- https://crates.io/crates/structopt
- https://crates.io/crates/chrono
- https://crates.io/crates/clap