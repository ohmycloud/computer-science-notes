# 创建 Python 虚拟环境

## 安装 miniconda3

## 创建一个环境 + 指定 Python 版本

```bash
conda create --name my_app python==3.9.0
```

## 激活环境

```bash
conda activate my_app
```

## 安装模块

```bash
pip install polars==0.16.14
conda install polars
```

## 销毁环境

```bash
conda deactivate
```

## 列出 packages

```bash
conda list -n my_app
```
