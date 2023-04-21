https://github.com/scopt/scopt

简单的 scala 命令行选项解析

scopt 是一个小小的命令行选项解析库。

## Sonatype

```
libraryDependencies += "com.github.scopt" %% "scopt" % "X.Y.Z"
```

查看上面的 Maven Central badge 

## 使用方法

scopt 提供了两种解析方式：immutable 和 mutable。无论哪种情况，首先您需要一个表示配置的 case class：

```java
import java.io.File
case class Config(foo: Int = -1, out: File = new File("."), xyz: Boolean = false,
  libName: String = "", maxCount: Int = -1, verbose: Boolean = false, debug: Boolean = false,
  mode: String = "", files: Seq[File] = Seq(), keepalive: Boolean = false,
  jars: Seq[File] = Seq(), kwargs: Map[String,String] = Map())
```

在不可变的解析样式中，config 配置对象作为参数传递给 *action* 回调。另一方面，在可变解析样式中，你需要修改配置对象。

## 不可变解析

下面是一个你怎么创建 `scopt.OptionParser[Config]` 的例子。有关各种构建器方法的详细信息，请参阅 [Scaladoc API](http://scopt.github.io/scopt/3.5.0/api/index.html#scopt.OptionParser)。

```java
val parser = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "3.x")

  opt[Int]('f', "foo").action( (x, c) =>
    c.copy(foo = x) ).text("foo is an integer property")

  opt[File]('o', "out").required().valueName("<file>").
    action( (x, c) => c.copy(out = x) ).
    text("out is a required file property")

  opt[(String, Int)]("max").action({
      case ((k, v), c) => c.copy(libName = k, maxCount = v) }).
    validate( x =>
      if (x._2 > 0) success
      else failure("Value <max> must be >0") ).
    keyValueName("<libname>", "<max>").
    text("maximum count for <libname>")

  opt[Seq[File]]('j', "jars").valueName("<jar1>,<jar2>...").action( (x,c) =>
    c.copy(jars = x) ).text("jars to include")

  opt[Map[String,String]]("kwargs").valueName("k1=v1,k2=v2...").action( (x, c) =>
    c.copy(kwargs = x) ).text("other arguments")

  opt[Unit]("verbose").action( (_, c) =>
    c.copy(verbose = true) ).text("verbose is a flag")

  opt[Unit]("debug").hidden().action( (_, c) =>
    c.copy(debug = true) ).text("this option is hidden in the usage text")

  help("help").text("prints this usage text")

  arg[File]("<file>...").unbounded().optional().action( (x, c) =>
    c.copy(files = c.files :+ x) ).text("optional unbounded args")

  note("some notes.".newline)

  cmd("update").action( (_, c) => c.copy(mode = "update") ).
    text("update is a command.").
    children(
      opt[Unit]("not-keepalive").abbr("nk").action( (_, c) =>
        c.copy(keepalive = false) ).text("disable keepalive"),
      opt[Boolean]("xyz").action( (x, c) =>
        c.copy(xyz = x) ).text("xyz is a boolean property"),
      opt[Unit]("debug-update").hidden().action( (_, c) =>
        c.copy(debug = true) ).text("this option is hidden in the usage text"),
      checkConfig( c =>
        if (c.keepalive && c.xyz) failure("xyz cannot keep alive")
        else success )
    )
}

// parser.parse returns Option[C]
parser.parse(args, Config()) match {
  case Some(config) =>
    // do stuff

  case None =>
    // arguments are bad, error message will have been displayed
}
```

以上生成以下用法文本：

```
scopt 3.x
Usage: scopt [update] [options] [<file>...]

  -f, --foo <value>        foo is an integer property
  -o, --out <file>         out is a required file property
  --max:<libname>=<max>    maximum count for <libname>
  -j, --jars <jar1>,<jar2>...
                           jars to include
  --kwargs k1=v1,k2=v2...  other arguments
  --verbose                verbose is a flag
  --help                   prints this usage text
  <file>...                optional unbounded args
some notes.

Command: update [options]
update is a command.
  -nk, --not-keepalive     disable keepalive
  --xyz <value>            xyz is a boolean property
```

### Options（选项）

命令行选项是使用 `opt[A]('f', "foo")` 或 `opt[A]("foo")` 定义的, 其中 `A` 是任意类型, 它是 `Read` typeclass 的实例。

- `Unit` 作为普通标记 `--foo`  或 `-f`
- `Int`, `Long`, `Double`, `String`, `BigInt`, `BigDecimal`, `java.io.File`, `java.net.URI` 和 `java.net.InetAddress` 接收诸如 `--foo 80` 或 `--foo:80` 那样的值。
- `Boolean` 接收 `--foo true` 或 `--foo:1` 这样的值
- `java.util.Calendar` 接收 `--foo 2018-07-16` 这样的值
- `scala.concurrent.duration.Duration` 接收 `--foo 30s` 这样的值
- `(String, Int)` 这样的 types 对儿接收 `--foo:k=1` 或 `-f k=1` 那样的键值对儿
- `Seq[File]` 接收 `--jars foo.jar,bar.jar` 这样的逗号分割的字符串值
- `Map[String, String]` 接收 `--kwargs key1=val1,key2=val2` 这样的逗号分割的 pairs 字符串值

这可以通过在作用域中定义 `Read` 实例来扩展。例如，

```java
object WeekDays extends Enumeration {
  type WeekDays = Value
  val Mon, Tue, Wed, Thur, Fri, Sat, Sun = Value
}
implicit val weekDaysRead: scopt.Read[WeekDays.Value] =
  scopt.Read.reads(WeekDays withName _)
```

默认情况下，这些选项是可选的

### Short options

对于普通的标记(`opt[Unit]`) 短的选项可以被分组为 `-fb` 来表示 `--foo --bar`。

`opt` 只接收单个字符, 但是使用 `abbr("ab")`, 还可以使用字符串：

```
opt[Unit]("no-keepalive").abbr("nk").action( (x, c) => c.copy(keepalive = false) )
```

### Help, Version, and Notes

预定义 action 有一些特殊选项，名为 `help("help")` 和 `version("version")`，分别打印用法文本和标题文本。当定义 `help("help")` 时，解析器将在失败时打印出短错误消息，而不是打印整个 usage 文本。可以通过重写 `showUsageOnError` 来更改此行为，如下所示：

```
override def showUsageOnError = true
```

`note("...")` 用于将给定的字符串添加到 usage 文本中。

### Arguments

命令行参数用 `arg[A]("<file>")` 定义. 它与选项类似，但它接收不含 `--` 或 `-` 的值。默认情况下，参数接受单个值并且是必需的。

```
arg[String]("<file>...")
```

### Occurrence

每个 opt/arg 都带有出现信息 `minOccurs` 和 `maxOccurs`。 `minOccurs` 指定 opt/arg 至少必须出现的次数，maxOccurs 指定 opt/arg 最多可能出现的次数。

可以使用 opt/arg 上的方法设置出现次数：

```
opt[String]('o', "out").required()
opt[String]('o', "out").required().withFallback(() => "default value")
opt[String]('o', "out").minOccurs(1) // same as above
arg[String]("<mode>").optional()
arg[String]("<mode>").minOccurs(0) // same as above
arg[String]("<file>...").optional().unbounded()
arg[String]("<file>...").minOccurs(0).maxOccurs(1024) // same as above
```

