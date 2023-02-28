# 第二天 更少的变量功率 = 更多的流动

原文地址: https://raku-advent.blog/2022/12/02/day-2-less-variable-wattage-more-flow/

在编码过程中寻找流动有时是很难做到的-当遇到"别人的代码"时就更难了。我们都有过这样的经历：读完代码后大喊："什么(WAT)?"。

与高功率(high wattage)的代码打交道不仅令人不快, 而且既花时间又花钱。程序包含的 WAT 越多, 就越可怕, 可悲的是, [恐惧是流动的阻碍](https://raku-advent.blog/2020/12/02/day-1-perl-is-dead-long-live-perl-and-raku/)。

相比之下, 编写低功率的代码可以通过保持自己和其他程序员在认知上的舒适来促进流动。让我们从一些高功率的代码开始, 然后用 Raku 重写它。

看看这段 Rust 代码(来自 [RosettaCode.org](https://rosettacode.org/wiki/Concurrent_computing#Rust))。

```rust
extern crate rand;
use std::thread;
use rand::thread_rng;
use rand::distributions::{Range, IndependentSample};

fn main() {
    let mut rng = thread_rng();
    let rng_range = Range::new(0u32, 100);
    for word in "Enjoy Rosetta Code".split_whitespace() {
        let snooze_time = rng_range.ind_sample(&mut rng);
        let local_word = word.to_owned();
        std::thread::spawn(move || {
            thread::sleep_ms(snooze_time);
            println!("{}", local_word);
        });
    }
    thread::sleep_ms(1000);
}
```

你猜这段 Rust 代码的作用是什么? 你如何评价它的认知舒适度？**0u32** 究竟是什么？

遗憾的是, 这段 Rust 程序的 happy path 被所有的导入库、类型处理、作用域变化和变量等所掩盖。每一个都为整个程序增加了一点点功率。完全理解它需要在认知上处理所有的中间变量（例如, **snooze_time**、**local_word**、**rng** 和 **rng_range** 等）, 同时在脑子里逐行过一遍这个程序。

我们怎样才能提高 Rust 的认知舒适度呢？

用 Raku 重写吧!

```raku
my @words = <Enjoy Rosetta Code>;
@words.race(:batch(1)).map: { sleep rand; say $_ };
```

你在这段代码中抓住了要点：以并行的批次在单词列表中角逐(`:race`), 并在打印出一个单词之前随机睡眠一段时间。

Raku 版本的代码在认知上更加舒适：更少的代码行, 没有外部库, 只有两个变量（**@word** 和主题 **$_**）。需要更少的心智把戏, 工作记忆被释放出来以促进流动。

甚至有可能只用一行代码就搞定了:

```raku
<Enjoy Rosetta Code>.race(:batch(1)).map: { sleep rand; say $_ };
```

但这增加了一个潜在的 WAT。当然, 单行版本有吹嘘的权利, "妈耶, 你看, 只有一行！", 但它不如双行版本容易理解。对于 Rosetta Code 的读者来说, 环缀运算符 "< >" 构建了一个由空白符分隔的单词列表, 这一点并不一定明显。然而, 在双行版本中加入 `@words` 变量, 就有助于理解了。很明显, `@words` 是一个变量, `.race()` 是一个作用于它的方法。

```raku
my @words = <Enjoy Rosetta Code>;
@words.race(:batch(1)).map: { sleep rand; say $_ };
```

像这样微妙的决定是对流动友好的代码所需要的。优化程序的流动需要调整它的认知负荷, 使其更容易被自己和他人理解。计算机并不关心变量是叫 **@r2d2c3pO** 还是 **@star-wars-droids-**, 但这对可怜的人类来说有很大区别。

优化代码的流动是一个很大的话题。让我们只关注编程的一个方面：变量。好的变量名称可以封装问题领域中的概念, 为程序员和维护者减少复杂性。与大多数语言不同的是, Raku 的变量名包括额外的流动友好功能：sigil 和 twigil。

sigil, 是提示读者变量的基本性质的符号（即 **$** **@** **%** **&**）：`$scalar`, `@positional`, `%associative` 或 `&code`。例如:

```raku
my $student        = 'Joe Bloggs';     # scalar: (Str)
my $total-students =  3;               # scalar: (Number)
my @students       = <Joe Mary Dave>;  # positional: (Array) 
my %cs100-scores   = (                 # associative: (Hash) 
                     'Joe'   => 87,
                     'Mary'  => 92,
                     'Dave'  => 63,
                     );
my &hello          = sub { say "hi"; } # code: (Sub)
```

大多数编程语言都有最基本的、无符号的变量。为了充分理解这些语言中的变量, 程序员通常需要向后追溯到变量的首次声明位置。这种认知成本随着变量和其声明之间的距离而增加。

Raku 中的符号有助于减少这种成本, 因为它在任何地方使用时都会显示出变量的性质。例如, 当你遇到一个以 **@** 符号开头的变量时, 你就知道这个变量是位置性的, 可迭代的, 而且它的元素可以用下标来访问（例如, `@students[0]`）。

同样, 对于 `%associative-variable`（例如, %cs100-scores）, 其内容是关联性的, 可迭代的, 其元素可以这样访问:

```raku
%cs100-scores{'Joe'};   # 87
%cs100-scores<Mary>;    # 92
``` 

Twigil, 或次级符号, 进一步阐明了变量的作用域。例如, `*` 表示一个动态变量, 可以在你的 Raku 程序的任何地方使用。

```raku
$*CWD   #   the current working directory    
@*ARGS  #   a list of command-line arguments
%*ENV   #   environment variables
```

按照惯例, 带有 `*` twigil 的变量都是大写的, 在访问时要进行查询:

```raku
say $*CWD.Str;  # /home/nige/raku/advent-2022
chdir('/tmp');
say $*CWD.Str;  # /tmp
```

其他变量, 在编译时设置, 用 `?` twigil 表示。比如说:

```raku
say $?FILE;    # test.raku - filename
say $?LINE;    # 2         - line number
$?LINE = 100;  # BOOM      - immutable, can't modify
```

`^` twigil 用于块和子程序中的位置参数。含有 `^` twigil 的变量其作用域只限于当前的子程序或块, 就像参数占位符一样。比如说:

```raku
sub full-name {
    # the Unicode order of the variable names matches 
    # the positional order of the parameters.
    return join(' ', $^b, $^a);
}

say full-name('Wall', 'Larry');  # Larry Wall
```

`:` twigil 用于子程序和块中的命名参数占位符。比如说:

```raku 
sub full-name {
    return join(' ', $:first, $:last);
}

say full-name(last => 'Wall', first => 'Larry'); # Larry Wall
```

在类中, `!` twigil 表示对私有属性的访问:

```raku
my class Student {
    has $.first-name;
    has $.last-name;

    method full-name() {
        return join(' ', $!first-name, $!last-name);
    }
}
```

变量名中的 sigil 和 twigil 的组合使程序员立即了解到变量的作用域以及如何访问它。

对于 Raku 新手程序员来说, 这些 sigil 和 twigil 可能看起来就像线路噪音(line-noise), 但是一旦度过了小的学习曲线（见上文）, 它们就会帮助程序员向前走而不是向后退。

不同的变量在 Raku 中看起来是不同的, 尽管有最初的学习曲线, 但它降低了它们的总体功率, 有助于流动的能力。然而, 有时, 你需要深入研究一个变量。"这是什么？" 那就用 `WHAT` 来找出它的类型。

```raku
note $*CWD.WHAT;    # (Path)
```

为了了解变量的大意, 调用 `.gist` 方法:

```raku
note $*CWD.gist;    # "/home/nige/raku/advent-2022".IO
```

要查看变量的内容, 可以对其调用 [raku](https://docs.raku.org/routine/raku#(Mu)_method_raku) 方法, 或者将变量传递给内置的数据转储函数 [dd](https://docs.raku.org/programs/01-debugging#Dumper_function_(dd))。

```raku
note $*CWD.raku;  # also dd($*CWD)

IO::Path.new(
    "/home/nige/raku/advent-2022",
    :SPEC(IO::Spec::Unix), 
    :CWD("/home/nige/raku/advent-2022"))
```

为什么 `$*CWD` 变量会有这样的作用？就问[为什么](https://docs.raku.org/syntax/WHY)...

```raku
note $*CWD.WHY;
```

这会打印出:

```
No documentation available for type 'IO::Path'. 
Perhaps it can be found at https://docs.raku.org/type/IO::Path
```

甚至变量如何(`HOW`)工作--它的高阶工作原理(Higher Order Working), 可以像这样用 `^` 来访问:

```raku
note $*CWD.^attributes;     # attributes it contains
note $*CWD.^methods;        # a full list of methods
note $*CWD.^roles;          # roles it does
note $*CWD.^mro;            # method resolution order
```

Raku 变量包含了你需要了解如何使用它们的一切。对于 "WAT!?" 这个问题总是有答案的。

自省、sigil 和 twigil, 意味着 Raku 变量在设计上是低功率的, 这有助于代码的流动。

圣诞快乐。
