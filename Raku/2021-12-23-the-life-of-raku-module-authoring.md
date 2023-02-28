你好，世界! 这篇文章有很多关于 fez 的内容，以及你如何开始编写你的第一个模块并让它对其他用户可用。假设你已经安装了 rakudo 和 zef，请安装 fez!

```bash
$ zef install fez
===> Searching for: fez
===> Updating fez mirror: https://360.zef.pm/
===> Updated fez mirror: https://360.zef.pm/
===> Testing: fez:ver<32>:auth<zef:tony-o>:api<0>
[fez]   Fez - Raku / Perl6 package utility
[fez]   USAGE
[fez]     fez command [args]
[fez]   COMMANDS
[fez]     register              registers you up for a new account
[fez]     login                 logs you in and saves your key info
[fez]     upload                creates a distribution tarball and uploads
[fez]     meta                  update your public meta info (website, email, name)
[fez]     reset-password        initiates a password reset using the email
[fez]                           that you registered with
[fez]     list                  lists the dists for the currently logged in user
[fez]     remove                removes a dist from the ecosystem (requires fully
[fez]                           qualified dist name, copy from `list` if in doubt)
[fez]     org                   org actions, use `fez org help` for more info
[fez]   ENV OPTIONS
[fez]     FEZ_CONFIG            if you need to modify your config, set this env var
[fez]   CONFIGURATION (using: /home/tonyo/.fez-config.json)
[fez]     Copy this to a cool location and write your own requestors/bundlers or
[fez]     ignore it and use the default curl/wget/git tools for great success.
===> Testing [OK] for fez:ver<32>:auth<zef:tony-o>:api<0>
===> Installing: fez:ver<32>:auth<zef:tony-o>:api<0>
 
1 bin/ script [fez] installed to:
/home/tonyo/.local/share/perl6/site/bin
```

确保最后一行在你的 $PATH 中，这样下一组命令就能顺利运行。现在我们可以开始写实际的模块了，让我们来写 ROT13，因为这是一个相当容易解决的问题，而且这篇文章与其说是关于模块内容，不如说是关于如何使用 fez。

## 编写模块

我们的模块目录结构。

```
.
├── lib
│   └── ROT13.rakumod
├── t
│   ├── 00-use.rakutest
│   └── 01-tests.rakutest
└── META6.json
```

**lib** 是你的模块的主要内容，它是你的模块的所有实用程序、助手和组织发生的地方。每个文件对应一个或多个模块或类，在下面的 **META6.json** 段中有更多介绍。

META6.json 是 zef 知道模块是什么的方式，它是 fez 知道它正在上传什么的方式，它是 rakudo 知道如何加载什么和从哪里加载的方式。让我们看一下 META6.json 的结构。

META6.json 包含你所有模块的测试。如果你有"仅限作者"的测试，那么你也会有一个 **xt** 目录，该目录的工作原理大致相同。为了你的用户的理智，请写出测试!

```json
{
  "name": "ROT13",
  "auth": "zef:tony-o",
  "version": "0.0.1",
  "api": 0,

  "provides": {
    "ROT13": "lib/ROT13.rakumod"
  },

  "depends":       [],
  "build-depends": [],
  "test-depends":  [],

  "tags":        [ "ROT13", "crypto" ],
  "description": "ROT13 everything!"
}
```

关于 **dist** 的简单讨论。一个 dist 是你的模块的完全合格的名称，它包含名称、授权和版本。它是 zef 区分你的 ROT13 模块和我的模块的方法。它与 use 一起使用，例如 `use ROT13:auth<zef:tony-o>`，以及在 zef 中：`zef install ROT13:auth<tony-o>:ver<0.0.1>`。在 raku 和生态系统中，dist 字符串总是与 `:auth` 和 `:ver` 一起被限定，但如果最终用户对他们想要的模块的版本/作者不那么挑剔，就不需要输入完全限定的 dist。在使用声明中，你可以结合 auth 和 ver 来获得你所期望的作者或版本，或者你可以省略一个或两个。

最好的做法是完全限定你的使用声明；随着越来越多的模块以相同的名字进入生态系统，这种做法将有助于保持你的模块顺利运行。

- name：这是模块的名字，也是你的 dist 的一部分，当你的消费者输入 `zef install ROT13` 时，它就会被引用。
- auth：这是生态系统知道谁是作者的方式。在 fez 上这是严格的，没有其他 rakudo 生态系统保证这与上传者的用户名相匹配。
- version：版本必须是唯一的认证和名称。例如，你不能以 `ROT13:auth<zef:tony-o>:ver<0.0.1>` 的值上传两个磁盘。
- provides：在提供中是模块和类的名称的键/值对，它们属于哪个文件。如果你在一个文件中有两个模块，那么你应该把同一个文件列出来两次，每次的键是每个类/模块的名字。lib 中的所有 - rakumod 文件都应该在 META6.json 文件中。这里的键是 rakudo 如何知道在哪个文件中寻找你的类/模块。
- depends: 你的运行时部署的列表

让我们快速建立一个 ROT13 模块，在 lib/ROT13.rakumod 中转储以下内容:

```raku
unit module ROT13;

sub rot13(Str() $text) is export {
    $text.trans('a..zA..Z'=>'n..za..mN..ZA..Z')
}
```

很好，你现在可以用 `raku -I. -e 'use ROT13; say rot13("hello, WoRlD!");` 来测试它（从你的模块根目录）。你应该得到的输出是 `uryyb, JbEyQ!`。

现在填入你的测试文件，用 `zef test .` 运行测试。

## 发布你的模块

### 注册

如果你没有在 fez 注册，现在是时候了!

```bash
$ fez register
>>= Email: omitted@somewhere.com
>>= Username: tony-o
>>= Password:
>>= Registration successful, requesting auth key
>>= Username: tony-o
>>= Password:
>>= Login successful, you can now upload dists
```

### 自我检查

```bash
$ fez checkbuild
>>= Inspecting ./META6.json
>>= meta<provides> looks OK
>>= meta<resources> looks OK
>>= ROT13:ver<0.0.1>:auth<zef:tony-o> looks OK
```

哦，快，我们看起来不错！"。

### 发布

```bash
$ fez upload
>>= Hey! You did it! Your dist will be indexed shortly.
```

这里唯一需要注意的是，如果在索引你的模块时出现问题，那么你会收到一封电子邮件，说明你在哪里出现了问题。

## 进一步阅读

你可以在这里阅读更多关于 fez 的信息。

- [(FEZ|ZEF) – Raku 生态系统和认证](https://deathbykeystroke.com/articles/20210116-fezzef---a-raku-ecosystem-and-auth.html)
- [faq: zef 生态系统](https://deathbykeystroke.com/articles/20210120-faq-zef-ecosystem.html)
- [Fez 组织: 冬至的奇迹](https://deathbykeystroke.com/articles/20211220-fez-orgs-a-winter-solstice-miracle.html)

也许你更喜欢听。

- [Fez/Zef，Raku 生态系统和架构](https://conf.raku.org/talk/143)

就这些了! 如果你还想知道关于 Fez、Zef 或生态系统的其他事情，请在 IRC 上给 tony-o 发一些聊天记录或电子邮件