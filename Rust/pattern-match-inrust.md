# Rust 中的模式匹配

```rust
match value {
    Some(2 | 3 | 5 | 7) => println!("prime"),
    Some(0 | 1 | 4 | 9) => println!("square"),
    None => println!("nothing"),
    _ => println!("something else"),
}
```

之前得这样写:

```rust
match value {
    Some(2) | Some(3) | Some(5) | Some(7) => println!("prime"),
    Some(0) | Some(1) | Some(4) | Some(9) => println!("square),
    None => println!("nothing"),
    _ => println!("something else"),
}
```

Using `if-let`:

```rust
let extension = "pm6";
if let Some("pm6" | "rakumod") = extension {
    println!("Perl 6 模块的后缀名");
}
```

多个 `|` 操作符尝试所有的组合:

```rust
match vec {
    (0, 0) => println!("here"),
    (-1 | 0 | 1, -1 | 0 | 1) => println!("close"),
    _ => println!("far away"),
}
```

结合 @ 绑定使用:

```rust
match value {
    Some(p  @ 2 | 3 | 5 | 7) => println!("{p} is a prime"),
    Some(sq @ 0 | 1 | 4 | 9) => println!("{sq} is a square"),
    None => println!("nothing"),
    Some(n) => println!("{n} is something else"),
}
```

checking an integer against a small set of values:

```rust
let some_value = 3;

if let 1 | 2 | 3 = some_value {
    println!("yep");
}
```

最终代码如下:

```rust
fn main() {
    let lan = Some("Perl6");
    let rs = match lan {
        Some("Perl6") | Some("Raku")    => "100 hundred years language",
        Some("Julia") | Some("Python")  => "科学计算",
        Some("Rust")  | Some("Haskell") => "学废了",
        _ => "Programming is hard, let's go shopping",
    };
    println!("{:?}", rs);

    let rs = match lan {
        Some("Perl6" | "Raku") => "100 hundred years language",
        Some("Julia" | "Python") => "科学计算",
        Some("Rust" | "Haskell") => "学废了",
         _ => "Programming is hard, let's go shopping"
    };

    println!("{:?}", rs);

    let extension = Some("pl");
    if let Some("pm6" | "rakumod") = extension {
        println!("Perl 6 模块的后缀名");
    } else {
        println!("Perl 5???");
    }

    let vec = (-1, 0);
    match vec {
        (0, 0) => println!("here"),
        (-1 | 0 | 1, -1 | 0 | 1) => println!("close"),
        _ => println!("far away"),
    }

    let number = 42;
    let alpha = 'C';

    // 匹配范围
     match number {
        1..=12 => println!("{:?}", "1..12"),
        13..=41 => println!("{:?}", "13..41"),
        41..=45 => println!("{:?}", "41..45"),
         _ => println!("{:?}", "huep")
    }

    // 匹配字母
    match alpha {
        first@ 'A' ..= 'F' => println!("{:?}", first),
        second@ 'G' ..= 'Z' => println!("{:?}", second),
        _ => println!("{:?}", "othrers")
    }

    // 匹配数组
    let arr = [1,2,3,6];
    match arr {
        [1,2,3,_] => println!("{:?}", "head"),
        _ => println!("others")
    }

    // 匹配切片
    let slice = &[5,6,7,8];
    match slice {
        [5,6,_,8] => println!("{:?}", "slice"),
        _ => println!("others")
    }

    #[derive(Debug)]
    struct Point {x: i32, y: i32, z: i32}
    let p = Point {x: 4, y: 5, z: 56};

    // 匹配引用, 如果这段代码放在 `match p` 的下面, 会发生 move 错误
    match &p {
        pp @ &Point {x, y, z} => println!("{:?} {} {} {}", pp, x, y, z),
        _ => println!("{:?}", "other")
    }

    // 匹配结构体, 消费了 p
    match p {
       pp @ Point {x, y, z} => println!("{:?} {} {} {}", pp, x, y, z),
        _ => println!("{:?}", "other")
    }

    let value = Some(7);
    match value {
        Some(p  @ (2 | 3 | 5 | 7)) => println!("{p} is a prime"),
        Some(sq @ (0 | 1 | 4 | 9)) => println!("{sq} is a square"),
        None => println!("nothing"),
        Some(n) => println!("{n} is something else"),
    }

    // if-let
    let some_value = 3;
    if let 1 | 2 | 3 = some_value {
        println!("yep");
    }
}
```
