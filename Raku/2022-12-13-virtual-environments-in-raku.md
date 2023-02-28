原文链接: https://raku-advent.blog/2022/12/13/virtual-environments-in-raku/

羡慕吗？如果没有，运行 `zef install Envy`，让我们开始探索虚拟编译单元库。

拿着电话! 我们在做什么？我们将探索使用一个模块，允许我们在我们非常喜欢的 raku 中拥有虚拟模块环境。

为什么我们要这样做？很多原因，但有几个原因包括。

    开发和测试环境
    按项目/环境/其他东西隔离模块库
    更安全地使用多个版本的 raku

成交吗？继续吧!
开始吧

用 `zef install Envy` 来安装环境管理器是很容易的。现在在这个教程中，我们要建立一个进程间的工作池，它不做任何事情，但不是全局安装所有东西，而是用一个自定义模块库来完成。

在 `parent.raku` 中转储以下内容。

```raku
use Event::Emitter::Inter-Process;

my $event = Event::Emitter::Inter-Process.new;

my Proc::Async $child .= new(:w, 'raku', '-Ilib', 'child.raku');

$event.hook($child);

$event.on('echo', -> $data {
  # got $data from child;
  say $data.decode;
});

$child.start;
sleep 1;


$event.emit('echo'.encode, 'hello'.encode);
$event.emit('echo'.encode, 'world'.encode);

sleep 5;
```

然后在 child.raku 中:

```raku
use Event::Emitter::Inter-Process;

my $event = Event::Emitter::Inter-Process.new(:sub-process);

$event.on('echo', -> $data {
  "child echo: {$data.decode}".say;
  $event.emit('echo'.encode, $data);
});

sleep 3;
```

好吧，这只是示例代码，但程序并不是重点。现在开始安装 `Event::Emitter::Inter-Process` 到一个虚拟仓库。

我们需要创建一个环境，并在安装我们的依赖项之前启用它。

```bash
$ envy init tutorial
==> created tutorial
    to install to this repo with zef use:
      zef install --to='Envy#tutorial' <your modules>

$ envy enable tutorial
==> Enabled repositories: tutorial

$ zef install --to='Envy#tutorial' 'Event::Emitter::Inter-Process'
===> Searching for: Event::Emitter::Inter-Process
===> Searching for missing dependencies: Event::Emitter
===> Testing: Event::Emitter:ver<1.0.3>:auth<zef:tony-o>
===> Testing [OK] for Event::Emitter:ver<1.0.3>:auth<zef:tony-o>
===> Testing: Event::Emitter::Inter-Process:ver<1.0.1>:auth<zef:tony-o>
===> Testing [OK] for Event::Emitter::Inter-Process:ver<1.0.1>:auth<zef:tony-o>
===> Installing: Event::Emitter:ver<1.0.3>:auth<zef:tony-o>
===> Installing: Event::Emitter::Inter-Process:ver<1.0.1>:auth<zef:tony-o>
```

现在你应该可以直接运行你的应用程序了:

```bash
$ raku parent.raku
child echo: hello
child echo: world
hello
```

然后，如果你禁用了环境:

```bash
$ envy disable tutorial
==> Disabled repositories: tutorial
$ raku parent.raku
===SORRY!=== Error while compiling /private/tmp/parent.raku
Could not find Event::Emitter::Inter-Process in:
Envy<3697577031872>
…
at /private/tmp/parent.raku:1
```

关于 Envy 的其他说明

Envy 还处于测试阶段，可能会有一些不尽人意的地方。我们非常欢迎 PR，也非常欢迎 BUG。两者都可以在这里提交。

这篇文章最初发布在这里。