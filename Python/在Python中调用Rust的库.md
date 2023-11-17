# 调用 Python 代码研究

在 Python 里面调用 Rust 中的函数。

```bash
cargo new --lib py_rust
```

在 **Cargo.toml** 文件中添加如下配置:

```toml
[lib]
name = "py_rust"
crate-type = ["cdylib"]

[dependencies]
pyo3 = {version = "0.13.2", features = ["extension-module"]}
```

在 **lib.rs** 中添加如下代码:

```rust
use pyo3::prelude::*;
use pyo3::wrap_pyfunction;

#[pyfunction]
fn add(x: f64, y: f64) -> f64 {
    return x+y
}

#[pyfunction]
fn sum_as_string(a: usize, b: usize) -> PyResult<String> {
    Ok((a + b).to_string())
}

#[pymodule]
fn py_rust(_py: Python<'_>, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(add, m)?)?;
    m.add_function(wrap_pyfunction!(sum_as_string, m)?)?;
    Ok(())
}
```

`#[pyfunction]` 是派生宏, 它自动把 Rust 函数转为 Python 中的函数。

`#[pymodule]` 是派生宏, 用以生成 Python 中的模块。

然后编译这个库:

```bash
cargo build
```

在 windows 下它生成 `.dll` 文件，在 *Unix 下它生成 `.so` 文件， 在 Mac OS 下它生成 `.dylib` 文件。

```bash
...
py_rust.dll
```

重命名 py_rust.dll 为 py_rust.pyd:

```bash
move py_rust.dll py_rust.pyd
```

在 target\debug 目录下编写一个 Python 代码用以测试生成的 dll 文件:

```python
from py_rust import add, sum_as_string

print("add value :",add(1,2))
print("sum_as_string: ",sum_as_string(5,6))
print("hello world")
```

运行:

```bash
python test.py
```

## 优点

- 一次编译, 到处运行。支持跨平台。
- 多语言支持。不仅 Python 自己可以调用, 其他语言也可以调用。

## 参考连接

- https://pyo3.rs/v0.13.2/
- https://github.com/PyO3/pyo3
- https://github.com/PyO3/rust-numpy
