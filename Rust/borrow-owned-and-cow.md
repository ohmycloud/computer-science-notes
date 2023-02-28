## Borrow、Owned 和 Cow

- Borrow

The Borrow trait is used when you’re writing a data structure, and you want to use either an owned or borrowed type as synonymous for some purpose.



Cow: copy on write


- AsRef
- AsMutRef
- Borrow
- ToOwned
- Cow
- Deref
- From/Into


使用 Cow 的一个场景:

https://stackoverflow.com/questions/33419422/return-original-or-modified-string/33419930#33419930

```rust
fn clean(s: &str) -> &str { // but not sure about return type
    if /* needs cleaning */ {
        let cleaned: String = s.chars().filter( /* etc */ ).collect();
        cleaned
    } else {
        s
    }
}
```

只是这并不像写的那样工作，因为 `cleaned` 是 `String` 类型的，而不是 `&str` 类型的。

这里的目标是只在必要时执行分配(allocation ) - 如果字符串需要修改，我想用一个新的字符串替换它，如果不需要，我不想对它调用 `to_string()`。理想情况下，我希望这对调用者来说是透明的，但也不必如此 - 我对调用代码也有控制权。即便如此，我也没有找到一个解决方法，因为如果新创建的 `String`，甚至是它的一个借用，最后出现在调用者的某种 if 或 else 块中，它的寿命就不够长，无法在原始字符串被使用的情况下使用。例如，这也是行不通的:

```rust
fn caller(s: &str) {
    if needs_cleaning(s) {
        let cleaned = clean(s); // where clean always returns a new String
        s = &cleaned;
    }

    / * do stuff with the clean string */
}
```

使用 Cow 来拯救:

```rust
use std::borrow::Cow;

fn clean(s: &str) -> Cow<str> {
    if /* needs cleaning */ {
        let cleaned: String = s.chars().filter(/* etc */).collect();
        Cow::Owned(cleaned)
    } else {
        Cow::Borrowed(s)
    }
}
```