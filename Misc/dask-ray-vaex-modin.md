# Pandas 瓶颈

运行在单核 CPU 上, 不能处理超过内存的数据。

# modin 报错

```python
# script.py
from distributed import Client
import modin.pandas as pd
import modin.config as cfg

cfg.Engine.put("dask")

if __name__ == "__main__":
  client = Client() # Explicit Dask Client creation.
  df = pd.DataFrame([0, 1, 2, 3])
  print(df)
```

```
RuntimeError:
        An attempt has been made to start a new process before the
        current process has finished its bootstrapping phase.

        This probably means that you are not using fork to start your
        child processes and you have forgotten to use the proper idiom
        in the main module:

            if __name__ == '__main__':
                freeze_support()
                ...

        The "freeze_support()" line can be omitted if the program
        is not going to be frozen to produce an executable
```

解决办法:

把 import 语句放在 `if __name__ == '__main__'` 下面:

```python
if __name__ == "__main__":
    from distributed import Client
    import modin.pandas as pd
    import modin.config as cfg
    
    cfg.Engine.put("dask")
    client = Client() # Explicit Dask Client creation.
    df = pd.DataFrame([0, 1, 2, 3])
    print(df)
```
