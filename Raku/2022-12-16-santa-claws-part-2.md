原文链接: https://raku-advent.blog/2022/12/16/day-16-santa-claws-part-2/

...在这个冬季戏剧的第一部分，我们让 CL::AWS 夫人陷入了困境。

到目前为止的故事：小精灵们需要在 AWS EC2 上重建他们的电子圣诞网站--CL::AWS 夫人很快就编写了一个最小的 raku 脚本，以使用 AWS CLI 的基本程序编码方法和所需命令的 shell 执行。

但是，这段代码是不是太程序化了，是不是太难维护了，精灵们在极地的冰层下冬眠后，明年还能拿起它，摸索它，扩展它吗？Raku 是正确的选择吗？

她想起了她的口头禅："我们需要一种厨房水槽语言[呻吟]，程序化、CLI、OO 和功能化都是一流的公民--我们为什么不试试 raku 呢？"

这又是 raku 的拯救。为了改善情况，她又回到了键盘前，将版本1的 raku 程序化 CLI 代码重构为版本2的 raku 面向对象代码....。

版本1 - raku 程序性 CLI 代码。

![img](https://rakuadventcalendar.files.wordpress.com/2022/12/screenshot-2022-12-02-at-14.11.13.png.webp?w=829)

作者注：这段代码真的有效，只要去 "apt-get install awscli && aws configure" 并运行它就可以了! 然后在你的 AWS EC2 控制台看一下。请注意--这些例子会让你的 AWS 账单迅速攀升!

第二版 - raku 面向对象的代码。

![img](https://rakuadventcalendar.files.wordpress.com/2022/12/screenshot-2022-12-04-at-20.38.10-1.png?w=796)

驯鹿们宣布了他们的代码评论：-

Doner 说："OMG，我只是喜欢你把41行代码增加到 152 行的方式......这是对 vim 折叠的厚颜无耻的使用...因为我们是按行付费的，所以我们是在为我们的 zR 提供 quids in"

Blitzen 说："我非常期待使用 Inline::Perl5 并在没有礼物包装的情况下调用 PAWS cpan 模块，现在你在 raku 中写了一个如此酷的附加值层，我无法抗拒了"

Rudolph 说："我们应该使用 Python，因为它有很好的函数库（好吧，它们实际上并不是语言的一部分），这样我们就可以结构化和组成方法，并从这个低层次中抽象出来"

让我们来挖一挖，说说小矮人[啊？ ~ed]。

Raku 中的面向对象

我喜欢把 Raku 的 OO 想象成一个齿轮箱。你可以用 "小 Raku  "从一档开始，就像这里做的那样。[见 Think Raku 中的第二节为例]。它快速而简单，与其他语言熟悉的 OO 工具相呼应，如 Python 和 Ruby。

Raku 类是一种非常简单的处理"块状"数据模型的方法。作为重构的一部分，这个数据模型（Instance 有 Session 有 KeyPair 有 name）是在简单地把事情安排在最自然的地方出现的。这避免了其他一些 OO 语言（尤其是 C++）从一开始就采用正式数据结构的挑战。

然后，随着你的代码的发展，用 Raku 你可以通过范围的变化来更紧密地应用类型和 SOLID 原则、多态性、角色、多重继承、接口等等。

CL::AWS 夫人卡在了1档。

```raku
class Config {…}

class Config {
    has $.image;
    has $.type;

    method TWEAK {
        my %y := load-yaml:
          '../.racl-config/aws-ec2-launch.yaml'.IO.slurp;
        $!image := %y<instance><image>;
        $!type  := %y<instance><type>;
    }
}
```

编码是所有关于选择的问题。首先，选择哪种装备。其次，选择将配置加载到一个类中。

你可以选择加载一个脚本范围内的 Config Hash，但在这里我们觉得类的模型可以作为这段代码期望在 YAML 文件中找到的定义。

在类 `Config {...}` 中，属性是以 `$.image` 来声明的。`$.` 符号提供了公共访问器，这样你就可以像这样获得值。

```raku
my $c = Config.new;
say $c.image;
```

简单、易读、熟悉。

你能指定这个属性是私有的吗？- 当然可以，用 `$!` 符号代替。

你能检查它是一个字符串类型吗？- 当然，像这样...有 `Str $.image`。

你能指定它是只读的吗？- 呃，可以。

设置一个默认值怎么样？ 是的--有 `Str $.image = 'ami-0f540e9f488cfa27d'`

...但请记住，雪橇在一档，目的是为了代码的清晰。

在方法 `TWEAK {...}` 中，这个构造方法在创建对象的后期被调用，给了我们一个机会来做属性的初始化。它在对象被最终确定为公共访问器之前运行，所以我们必须通过它们的私有名称 `$!image` 来访问属性。

```raku
class Instance {...}
```

有一段时间，我们为 Instance 应该包含 Session 还是 Session 应该包含 Instance 而苦恼。这正是 Raku OO 所面临的那种设计选择，而且，编码人员再次面临选择。

这个决定最终是由调用惯例驱动的。最终，这段代码可以在命令行中被调用，例如：`raws -ec2 -instance launch`。这将返回我们刚刚启动的 AWS EC2 实例的 ssh 连接字符串。

在脚下，我们已经有了 `Instance.new.connect.say;` 来做这件事了。

所以，在顶层，我们想要的是一个实例，然后对其调用 `.connect`。

因此，所有其他的东西，KeyPair、VPC、Elastic IP 等等都应该放在 Instance 中，它有 `$.s = Session.new;` 作为放置它的地方，并以正确的顺序将其全部集合。

这就使得意图明确，可以设置和执行实际的 awscli 调用，以进行提升。

```raku
my $cmd :=
    "aws ec2 run-instances " ~
    "--image-id {$!c.image} " ~
    "--instance-type {$!c.type} " ~
    "--key-name {$!s.kpn} " ~
    "--security-group-ids {$!s.sg.id}";
    
qqx`$cmd` andthen
    $!id = .&from-json<Instances>[0]<InstanceId>;
```

这篇文章的第一部分解释了在这里工作的 Raku 好东西。

作者注：这个小的代码片断展示了编程语言是否应该限制使用空白和制表符。

补货

总结一下，这里有一些 Raku 在路上帮助的代码片段，以及一些没有被列入清单的东西。

使用绑定 `:=` 而不是赋值 `=` 告诉读者，该值不打算改变。

`<>` 哈希访问器引用了键名，以减少行噪音。

```raku
$!image := %y<instance><image>;
```

而不是:

```raku
$!image := %y{"instance"}{"image"};
```

`class Config {...}` 可以是一个 Singleton - 但额外的逻辑是我们不需要的开销，因为我们可以控制其使用。

我们可以选择将所有 YAML 字段自动加载到类中，而不考虑通过 `FALLBACK` 方法访问的内容，我们仍然可以选择将 `Config` 类的属性作为一个 Hash 来使用。我们可以使用 `Config` 模块。

方法 `TWEAK {...}` 可以是一个子方法，但我们选择保留最简单的选项，以减少代码量，因为这里没有类的继承。

角色而不是类......当改变到第二档时，我们可能会想把所有的，但最像"名词"的类重构为角色...通常角色可以代替类，因为无论如何 Raku 都是双关的角色。这样一来，就可以通过行为的混合来实现强大的代码组合。

功能性的未来

所以，这种从 Raku 程序化到 Raku OO 的重构（即使是在第一档）已经极大地提高了代码的清晰度和可组合性。

但由于我们多次使用 awscli，如果能有一些可重复使用和可连锁的函数，如 `aws().ec2().instance().run()`，"知道"它们何时必须以目标格式生成键值对，如 `-image-id {$!c.image}`，`-instance-type {$!c.type}` 等，那就更好了。

在未来，也许它可以像这样简单[因为在 raku 中你可以丢弃空的 ()]。

```raku
aws.ec2.instance.run($:image-id, $:instance-type);
```

因此，Raku 的功能特性可以帮助我们更多的提高清晰度和可组合性！。

作者注：大多数功能编码技术都是 Raku 的原生技术，这很可能是我今后在博客上发表的一个主题，网址是 https://p6steve.com

但这是下一次了...

~p6steve