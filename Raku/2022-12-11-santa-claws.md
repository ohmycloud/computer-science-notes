原文链接: https://raku-advent.blog/2022/12/11/day-11-santa-claws/

圣诞老人的精灵们每年都负责更新电子圣诞网站，由于该网站使用 WordPress，所以每次都需要全面重建，以确保它为所有的孩子发布他们的圣诞清单做好准备，而不会在流量的重压下垂头丧气。

今年冬天，他们认为通过使用亚马逊网络服务将他们的 WordPress 网站转移到云端，使他们的礼品包装区没有服务器和路由器架，这将是一件很酷的事情。

他们寻找一种工具，帮助他们管理启动一个干净的 WordPress 构建的所有阶段。

    用 Ubuntu 22.04LTS 启动一个干净的 AWS EC2 服务器，设置安全组和弹性 IP（通过 awscli），然后 ssh 进入新实例
    使用 apt-get（在 EC2 实例的 Ubuntu cli 上）来安装运行 docker-compose 的最小软件包集
    使用 git clone 获取平台 docker-compose.yaml，从而运行干净的 MySQL、WordPress 和 NGINX 实例，并提供端口和 SSL 证书。
    在实例中安装一套预定义的 WordPress 主题和插件（通过 WordPress cli），并通过移动内容文件填充页面和内容。

设置所有这些将是一些工作，但分层的方法（ssh'ing 进入 AWS 基本实例，然后进入子 Docker 虚拟机）将意味着 WordPress 网站的"模式"可以是标准化的和可重复的。而且，这些层可以扩展到其他云供应商、其他网络应用等等。配置可以存储在一组分层的 `.yaml` 文件中。

作者注：我仍在进行第1步的工作......所以这就是这篇文章的主题。请密切关注我的博客，以便将来在 https://p6steve.com，了解其他步骤的情况。

在开始之前，圣诞老人问他的驯鹿什么是最好的语言。

Doner 说："我想用 Bash，但它很笨重，可能需要添加一些 awk，这样我就可以对 JSON 结果进行重码处理，而且它缺乏任何合理的类/对象方式来建模，另外我还得学习它，嗯"

Blitzen 说："perl5--它无处不在，而且速度很快，它有一些有用的 CPAN 模块，比如 AWS CLI 和 PAWS（哦，看，有一个 WordPress CLI...需要为它写一个模块），但不幸的是，它现在对我来说缺少-Ofun和维护性"

Rudolph 说："Python--好吧，我在 Python 中做了一些编码，它对于简单的 OO 是很好的，而且有大量的模块和包--但实际上 Python 对于安装和 CLI 脚本的圆洞来说是一个方钉子"

讨论被 CL::AWS 夫人解决了，"我们需要一种厨房水槽语言(geddit?!)，CLI、OO 和模块都是一等公民--我们为什么不试试 Raku 呢？

这是第一版的一个片段......

```raku
use Paws:from<Perl5>;
use Paws::Credential::File:from<Perl5>;

# will open $HOME/.aws/credentials
my $paws = Paws.new(config => {
  credentials => Paws::Credential::File.new(
    file_name => 'credentials',
  ),  
  region => 'eu-west-2',
  output => 'json',
});

my $ec2 = $paws.service('EC2');

my $result = $ec2.DescribeAddresses.Addresses;
dd $result;
```

看，我们可以通过超棒的 CPAN perl5 Paws 模块直接使用 awscli，不需要礼物包装器或其他东西。

作者注：我链接了 Reddit 上最近的一次讨论，在那里我终于相信 perl5 模块不需要包装器...关于这一点，你可以从片段中看到，raiph 是正确的。同样，我个人对这种方法有两个不相关的问题：（i）Paws 很大，一下子吞下去很吓人，我只想应用最小的一组东西；（ii）这需要我的主管机安装 awscli 和 Python（awscli 是用 Python 写的！）、perl5、cpanm 和 Paws 以及 Raku，这是相当多的东西，我真的不希望在我有 penv 和所有这些东西的主开发机上。

嗯--在 Advocaat 上的一个深夜说服了 CL::AWS 夫人再试一次，但要把事情缩减到最小，真正需要的是 "apt-get install awscli && aws configure"，然后采取与 perl5 相同的方法，通过 shell 命令和回车键。

让我们看看，我是否需要像 Raku 文档中这样的东西。

```raku
my $proc = run 'echo', 'Rudolph is Great!', :out;
$proc.out.slurp(:close).say; # OUTPUT: «Rudolph is Great!␤» 

That seems a bit less handy than perl5 backticks, surely I can do better:

my $word = "kids";
say qqx`echo "hello $word"`;  # OUTPUT: «hello kids␤»
```

作者注：`qqx` 是完美的，因为它的双引号性质会自动插值变量名，如 '$word'，而且它返回的 stdout 是我们需要的 awscli 响应。一个非常酷的事情是，定界符，通常是 "qqx{...}"，可以是任何字符，所以我使用反斜线，是为了看在旧时代的份上，也是为了避免函数调用的 `{}`。

因此，这里有一些 2.0 版本。

```raku
use JSON::Fast;

my $image-id = 'ami-0f540e9f488cfa27d';
my $instance-type = 't2.micro';

qqx`aws ec2 run-instances --image-id $image-id --count 1 --instance-type $instance-type --key-name $key-name --security-group-ids $sg-id` andthen 

say my $instance-id = .&from-json<Instances>[0]<InstanceId>;
```

Raku 的其他一些小礼物是。

    `qqx` 将主题设置为 cli 响应。
    然后将主题从左到右移动
    然后，我可以使用 `.` 将任何方法应用到主题上
    `&` 将 `sub from-json` 转换为一个方法调用
    `<>` 自动引号将访问器精简到 json 结果中。

这里是整个事情的一个快照（针对步骤1），在 gist 中。


![img](https://rakuadventcalendar.files.wordpress.com/2022/12/screenshot-2022-12-02-at-14.11.13.png)

作为一个引导 perl5 后缀并应用一些 cli 魔法的方法，这个 gist 展示了 raku 如何在 perl5 cli 遗产的基础上很好地发展，并避免将 awscli 命令埋在分散注意力的模板中，从而使编码者/维护者清楚其意图。但是，这是一个线性文件，已经到了程序性步骤的极限，很难再利用和/或扩展。

我们的时间和空间已经不多了，因为我必须为圣诞老人和精灵们烧水壶了。也许我可以晚点再来，展示如何用 raku OO 挑出固有的结构和关系，以提供一个可以推理的更深入的模型。

祝大家圣诞快乐!

~p6steve