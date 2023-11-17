- Option

```rust
pub enum Option<T> {
    None,
    Some(T),
}
```

实现:

- pub const fn is_some(&self) -> bool

如果 option 是 Some 值, 则返回 `true`。

例子:

```rust
let x: Option<u32> = Some(2);
assert_eq!(x.is_some(), true);

let x: Option<u32> = None;
assert_eq!(x.is_some(), false);
```

- pub fn is_some_and(self, f: impl FnOnce(T) -> bool) -> bool

如果 option 是 `Some` 并且它里面的值匹配一个断言, 则返回 `true`。

例子:

```rust
let x: Option<u32> = Some(2);
assert_eq!(x.is_some_and(|x| x > 1), true);

let x: Option<u32> = Some(0);
assert_eq!(x.is_some_and(|x| x > 1), false);

let x: Option<u32> = None;
assert_eq!(x.is_some_and(|x| x > 0), false);
```

- pub const fn is_none(&self) -> bool

如果 option 是 `None` 值, 则返回 `true`。

例子:

```rust
let x: Option<u32> = Some(2);
assert_eq!(x.is_none(), false);

let x: Option<u32> = None;
assert_eq!(x.is_none(), true);
```

- pub fn map<U, F>(self, f: F) -> Option<U> where F: FnOnce(T) -> U

通过将函数应用于所包含的值(如果是 `Some`)或返回 `None`(如果是 `None`) 把 `Option<T>` 映射到 `Option<U>`。

例子:

计算 `Option<String>` 的长度, 其结果为 `Option<usize>`, 消耗原始值:

```rust
let may_be_some_string = Some(String::from("Rakulang Rocks!"));

// `Option::map` 按值接收 self, 消耗 `may_be_some_string`
let may_be_some_len = may_be_some_string.map(|s| s.len());
assert_eq!(maybe_some_len, Some(15));

let x: Option<&str> = None;
assert_eq!(x.map(|s| s.len()), None);
```

- pub fn map_or<U, F>(self, default: U, f: F) -> U where F: FnOnce(T) -> U

返回提供的默认结果(如果没有)，或者将函数应用于包含的值(如果有)。

传递给 `map_or` 的参数被急切地求值; 如果要传递函数调用的结果，建议使用 `map_or_else`，它是惰性求值的。

```rust
let x = Some("foo");
assert_eq!(x.map_or(42, |v| v.len()), 3);

let x: Option<&str> = None;
assert_eq!(x.map_or(42, |v| v.len()), 42);
```

- pub fn map_or_else<U, D, F>(self, default: D, f: F) -> U where D: FnOnce() -> U, F: FnOnce(T) -> U

计算默认函数结果(如果没有)，或者对包含的值应用不同的函数(如果有)。

例子:

```rust
let k = 21;
let x = Some("foo");
assert_eq!(x.map_or_else(|| 2 * k, |v| v.len()), 3);

let x: Option<&str> = None;
assert_eq!(x.map_or_else(|| 2 * k, |v| v.len()), 42);
```

- pub fn ok_or<E>(self, err: E) -> Result<T, E>

把 `Option<T>` 转换成 `Result<T, E>`, 将 `Some(v)` 映射为 `Ok(v)`, 将 `None` 映射为 `Err(err)`。

传递给 `ok_or` 的参数被急切地求值; 如果要传递函数调用的结果，建议使用 `ok_or_else`，它是惰性求值的。

```rust
let x = Some("foo");
assert_eq!(x.ok_or(0), Ok("foo"));

let x: Option<&str> = None;
assert_eq!(x.ok_or(0), Err(0));
```

- pub fn ok_or_else<E, F>(self, err: F) -> Result<T, E> where F: FnOnce() -> E

把 `Option<T>` 转换为 `Result<T, E>, 将 `Some(v)` 映射为 `Ok(v)`, 将 `None` 映射为 `Err(err())`。

例子:

```rust
let x = Some("foo");
assert_eq!(x.ok_or_else(|| 0), Ok("foo"));

let x: Option<&str> = None;
assert_eq!(x.ok_or_else(|| 0), Err(0));
```

- pub const fn as_ref(&self) -> Option<&T>

从 `&Option<T>` 转换为 `Option<&T>`。

例子:

不移动 `String`, 计算 `Option<String>` 的长度为 `Option<usize>`。`map` 方法按值接受 `self` 参数, 消耗原始值, 因此该技术首先使用 `as_ref` 将 `Option` 作为对原始值的引用（即 Option<&T>）。

```rust
let text: Option<String> = Some("Perl 6 Rocks".to_string());

// 首先, 用 `as_ref` 把 `Option<String>` 转换为 `Option<&String>`
let text_length: Option<usize> = text.as_ref().map(|s| s.len());

if let Some(text_length) = text_length {
    println!("{:?}", text_length);
}

println!("still can print text: {text:?}");
```

- pub fn as_mut(&mut self) -> Option<&mut T>

把 `&mut Option<T>` 转换为 `Option<&mut T>`。

例子:

```rust
let mut x = Some(2);

match x.as_mut() {
    Some(v) => *v = 42,
    None => {},
}

assert_eq!(x, Some(42));
```

像 Scala 中的 Option 那样, Rust 中的 Option 也可以表现的像列表那样。

- pub fn zip<U>(self, other: Option<U>) -> Option<(T, U)>

把 `self` 和另一个 `Option` zip 到一块儿。
如果 `self` 为 `Some(s)` 并且 `other` 为 `Some(o)`, 那么这个方法会返回 `Some((s, o))`, 否则返回 `None`。

例子:

```rust
let x = Some(1);
let y = Some("rakulang");
let z = None::<u8>;

assert_eq!(x.zip(y), Some((1, "rakulang")));
assert_eq!(x.zip(z), None);
```

- pub fn zip_with<U, F, R>(self, other: Option<U>, f: F) -> Option<R> where F: FnOnce(T, U) -> R

使用函数 `f` 把 `self` 和 另一个 `Option` zip 到一块儿。

如果 `self` 为 `Some(s)` 并且 `other` 为 `Some(o)`, 那么该方法返回 `Some(f(s, o))`。否则, 返回 `None`。

例子:

```rust
#![feature(option_zip)]

#[derive(Debug, PartialEq)]
struct Point {
    x: f64,
    y: f64,
}

impl Point {
    fn new(x: f64, y: f64) -> Self {
        Self {x, y}
    }
}

let x = Some(17.5);
let y = Some(42.7);

assert_eq!(x.zip_with(y, Point::new), Some(Point {x: 17.5, y: 42.7}));
assert_eq!(x.zip_with(None, Point::new), None);
```

- pub fn unzip(self) -> (Option<T>, Option<U>)

对含有两个 option 的元组进行 unzip。

如果 `self` 为 `Some((a, b))` 则该方法返回 `(Some(a), Some(b))`。否则, 返回 `(None, None)`。

例子:

```rust
let x = Some((1, "rakulang"));
let y = None::<(u8, u32)>;

assert_eq!(x.unzip(), (Some(1), Some("rakulang")));
assert_eq!(y.unzip(), (None, None));
```

- fn sum<I>(iter: I) -> Option<T> where I: Iterator<Item = Option<U>>

获取迭代器中的每个元素: 如果元素为 `None`, 则不再获取其他元素, 并返回 `None`。如果未出现 `None`，则返回所有元素的和。

例子: 这加总了字符 'a' 在字符串向量中的位置, 如果一个单词没有字符 'a', 则操作返回 `None`:

```rust
let words = vec!["have", "a", "great", "day"];
let find_words: Vec<Option<usize>> = words.iter().map(|w| w.find('a')).collect();
println!("{:?}", find_words); // [Some(1), Some(0), Some(3), Some(1)]
let total: Option<usize> = words.iter().map(|w| w.find('a')).sum();
assert_eq!(total, Some(5));
```

单词 good 中不含字符 'a', `"good".find('a')` 返回 `None`:

```rust
let words = vec!["have", "a", "good", "day"];
let find_words: Vec<Option<usize>> = words.iter().map(|w| w.find('a')).collect();
println!("{:?}", find_words); // [Some(1), Some(0), None, Some(1)]
let total: Option<usize> = words.iter().map(|w| w.find('a')).sum();
assert_eq!(total, None);
```

- pub fn or(self, optb: Option<T>) -> Option<T>

如果包含值则返回该选项，否则返回 `optb`。

传递给 `or` 的参数是急切求值的; 如果要传递函数调用的结果，建议使用 `or_else`，它是惰性求值的。

```rust
let perl6 = Some("Perl 6");
let raku  = Some("Raku");
let nothing: Option<&str> = None;

let language = perl6.or(raku);
println!("{:?}", language); // Some("Perl 6")

let language = nothing.or(raku);
println!("{:?}", language); // Some("Raku")
```

Scala 中有 `Option.orElse`:

```scala
val perl6 = Some("Perl 6")
val raku  = Some("Raku")
val nothing: Option[String] = None

var language = perl6.orElse(raku);
println(language); // Some(Perl 6)

language = nothing.orElse(raku);
println(language); // Some(Raku)
```

- min/max

```rust
let some_int1 = Some(42);
let some_int2 = Some(23);
let nothing: Option<u16> = None;

let some_min = some_int1.min(some_int2);
println!("{:?}", some_min); // Some(23)

let nothing = nothing.min(some_int1);
println!("{:?}", nothing); // None

let nothing = some_int1.min(nothing);
println!("{:?}", nothing); // None
```
