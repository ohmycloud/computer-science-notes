在整个圣诞节期间，圣诞老人意识到，把东西打包好，随时准备运送是一个相当好的主意。因此，它看中了集装箱。不是那些可能或不可能真正为把礼物带给世界上所有好男孩和女孩做所有粗重工作的容器，而是用来包装 Raku 和运输它或用它来测试的容器。一些你迟早需要做的事情，而且需要真正快速地做。

## 基础容器

基础容器需要干净、小巧，并且只包含建立你的应用程序所必需的东西。所以它需要一堆二进制文件，仅此而已。没有辅助工具，没有这样的东西。进入 jjmerelo/raku，一个非常简陋的容器，它只需要 15MB 字节，只包含 Rakudo 编译器和它需要工作的一切。它也可以从 GHCR 获得，如果这更符合你的口味。

你只需要它来运行你的乐道程序。例如，只需打印容器内所有可用的环境变量。

```bash	
time podman run --rm -it ghcr.io/jj/raku:latest -e 'say %*ENV'
```

这在我的机器上需要大约 6 秒钟，其中大部分时间用于下载容器。考虑到所有的事情，这并不是一个糟糕的交易，真的。

问题是，它有两种口味。另一种被称为 jj/raku-gha，原因显而易见。它是真正能在 GitHub 边上工作的，你们中的许多人最终会在那里使用它。有什么不同？嗯，一个很小的区别，但花了一些时间才发现：它的默认用户，叫 raku，使用 1001 作为 UID，而不是默认的 1000。

    对了，我可以直接用 1001 作为所有用户的单一 UID，但那样的话，我可能要为 GitHub Actions 再做一些改动，何必呢？

本质上，运行 GitHub 行动的用户使用这个 UID。我们希望我们的软件包用户与 GHA 用户保持和谐。我们通过这个实现了和谐。

但我们还想要一丁点。

我们可能需要 zef 来安装新模块。当我们在做这件事的时候，我们可能还需要以一种更简单的方式使用 REPL。输入 alpine-raku，再一次有两种口味：普通和 gha。和上面的区别一样：用户的 UID 不同。

另外，这也是我已经维护了一段时间的 jjmerelo/alpine-raku 容器。它的管道现在已经完全不同了，但它的功能是完全一样的。只是它更薄了，所以下载起来更快。再一次

```bash
time podman run --rm -it ghcr.io/jj/raku-zef:latest -e 'say %*ENV'
```

将需要 7 秒以北的时间，结果完全相同。但我们会在这个结果中看到一个有趣的位子。

```
{ENV => /home/raku/.profile, HOME => /home/raku, HOSTNAME => 2b6b1ac50f73, PATH => /home/raku/.raku/bin:/home/raku/.raku/share/perl6/site/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin, PKGS => git, PKGS_TMP => make gcc linux-headers musl-dev, RAKULIB => inst#/home/raku/.raku, TERM => xterm, container => podman}
```

这就是 RAKULIB 的位置。我想说的是，无论环境如何，我们都要在那个精确的目录下安装 RAKULIB。也就是主目录，它应该工作，对吗？但事实并非如此，因为 GitHub Actions 任意改变了 HOME 变量，而这正是 Raku 获取它的地方。

这又是一件需要花点功夫和了解 Rakudo 从哪里获取配置的事情。如果我们运行

```bash
raku -e 'dd $*REPO.repo-chain'
```

我们将得到这样的东西。

```
(CompUnit::Repository::Installation.new(prefix => "/home/jmerelo/.raku"),CompUnit::Repository::Installation.new(prefix => "/home/jmerelo/.rakubrew/versions/moar-2021.10/install/share/perl6/site"), CompUnit::Repository::Installation.new(prefix => "/home/jmerelo/.rakubrew/versions/moar-2021.10/install/share/perl6/vendor"), CompUnit::Repository::Installation.new(prefix => "/home/jmerelo/.rakubrew/versions/moar-2021.10/install/share/perl6/core"), CompUnit::Repository::AbsolutePath.new(next-repo => CompUnit::Repository::NQP.new(next-repo => CompUnit::Repository::Perl5.new(next-repo => CompUnit::Repository))), CompUnit::Repository::NQP.new(next-repo => CompUnit::Repository::Perl5.new(next-repo => CompUnit::Repository)), CompUnit::Repository::Perl5.new(next-repo => CompUnit::Repository))
```

我们正在谈论版本库链，Raku（通过 Rakudo）保存信息或在哪里找到，实际上，CompUnit 版本库或库，预编译（那些是 CompUnit::Repository::Installation）或不预编译（CompUnit::Repository::AbsolutePath）。但让我们看一下第一个，这是它将开始寻找的地方。它实际上是我们的主目录，或者更准确地说，是在正常情况下安装东西的子目录。Rakudo 从哪里获取这些信息？让我们改变一下 HOME 环境变量，我们就会知道，或者说不知道，因为根据安装情况，它将简单地挂起。然而，如果 RAKULIB 定义如上，比如说$*REPO.repo-chain 会打印出

```
(inst#/home/raku/.raku inst#/tmp/.raku inst#/usr/share/perl6/site inst#/usr/share/perl6/vendor inst#/usr/share/perl6/core ap# nqp# perl5#)
```

我们的 CompUnit::Repository::Installation 在这里变成了 inst#/home/raku/.raku，但是，更重要的是，HOME 环境变量在后面加了一个 `.raku`，在前面加了一个 `inst#`，暗示那是 Rakudo 期望找到它的地方。

这又让我们回到了 GitHub 的操作，它毫无理由地改变了这个变量，使我们的 Rakudo 安装实际上无法使用。不过不用担心，在 alpine-raku 容器（及其 GHCR 变体）中的一个简单的环境变量会让实际的 Rakudo 安装在 GitHub 的行动中得到控制。

## 现在我们都准备好了

我们可以使用这个图像编写我们自己的 GitHub 动作。直接在有乐库的容器里面运行我们所有的东西。比如说，这样
name: "在 Raku 容器中测试"

```yaml
on: [ push, pull_request ]
jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      packages: read
    container:
      image: ghcr.io/jj/raku-zef-gha
    steps:
      – name: Checkout
        uses: actions/checkout@v2
      – name: Install modules
        run: zef install .
      – name: Test
        run: zef –debug test .
```

Pod::Load 中使用的 GHA

这很简单，就像你在控制台中做的那样。安装，然后测试，对吗？就是这样。然而，在这之下，尽管发生了所有的移动和摇晃，容器使用了正确的 UID，而且 Raku 知道在哪里找到自己的安装，这就是使它运行的原因。

你甚至可以做得更多一点。将 Raku 作为一个运行任何东西的外壳。添加这个步骤。

```yaml
- name: Use Raku to run
  shell: raku {0}
  run: say $*REPO.repo-chain
```

有了 shell 魔法，它实际上会直接在 Raku 解释器上运行。你可以做任何你想做的事情：安装东西，运行 Cro，如果你想。所有这些都在 GitHub 的操作中 例如，你想用 Raku 图表显示最新提交的文件中有多少被修改了？给你。

```yaml
      – name: Install Text::Chart
        run: zef install Text::Chart
      – name: Chart files changed latest commits
        shell: raku {0}
        run: |
          use Text::Chart;
          my @changed-files = qx<git log –oneline –shortstat -$COMMITS>
                  .lines.grep( /file/ )
                  .map( * ~~ /$<files>=(\d+) \s+ file/ )
                  .map: +*<files>;
          say vertical(
            :max( @changed-files[0..*-2].max),
            @changed-files[0..*-2]
          );
```

这可以被添加到上面的动作中

几个简单的步骤：安装你需要的任何东西，然后用 Text::Chart 来绘制这些文件。这需要解释一下，或者直接查看源码以了解完整的情况：它使用了一个叫做 COMMITS 的环境变量，这个变量比我们要绘制图表的提交多了一个，已经被用来检查所有这些提交，然后，当然，我们需要弹出最后一个，因为它是一个压扁的提交，包含了 repo 中所有较早的修改，使我们的图表变得丑陋（我们不希望这样）。然而，从本质上讲，这是一个管道，它接收包括文件更改次数在内的日志文本内容，通过搜索匹配提取该数字，并将其送入垂直函数以创建文本图表。这将显示类似这样的内容（点击">"号以显示图表）。

在 Pod::Load 的最后 10 次提交中改变的文件

有了数以千计的文件供你使用，你就有了无限的可能。你想安装 fez 并在标记时自动上传吗？为什么不呢？就这样做吧。上传你的秘密，Bob 就是你的叔叔。你想用 Raku 对来源做一些复杂的分析，或者生成缩略图吗？去吧!

## 快乐的包装!

在这之后，圣诞老人无比高兴，因为他所有的 Raku 的东西都得到了适当的检查，甚至在需要的时候还被装进了容器里！这让他感到非常高兴。于是他坐下来享受他的玉米棒烟斗，这是 Meta-Santa 去年圣诞节为他带来的。

在此，祝你们所有人圣诞快乐!