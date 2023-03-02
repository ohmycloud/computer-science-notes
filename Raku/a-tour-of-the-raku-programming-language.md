原文链接: https://blog.matatu.org/aoc-2022

# Raku 编程语言之旅

[2022 年的 advent of code](https://adventofcode.com/2022) 有各种各样的好问题，这就就有借口使用 Raku 编程语言的一些独特功能了。下面是我的一些 Raku 答案，加上了一些解释。这个问题集有一些共同的主题，所以我把它们放在了一起。我可能会在未来的文章中写出另一个合集。

请注意，要浏览这些问题和输入，你需要点击下面的链接。我只写了答案，以及对它们如何工作的评论。如果你还没有读过这些问题，或者没有尝试过自己解决这些问题，那下面的一些内容可能就没有意义了。

## [第1天](https://adventofcode.com/2022/day/1)：计算卡路里

在这个问题中，我们想找到一连串列表的总和，然后找到最大值，再找到前三个值。

为了读取输入，我们使用 `$*ARGFILES`，它指的是命令行上给出的文件。即：要运行这个程序，把它保存为 **day-01.raku**，把输入保存为 **input.txt**，然后输入 **raku day-01.raku input.txt**。

`map` 是一个方法调用，`*` 创建一个匿名函数。方法调用可以使用冒号或圆括号。还有其他方法来制作匿名函数 -- 例如，这几行中的每一行都做了完全相同的事情。

```raku
.map: *.lines
.map( *.lines )
.map( { .lines } )
.map( { $_.lines } )
.map( { $^l.lines } )
.map(-> $l { $l.lines } )
```

当这些行被 [sum](https://docs.raku.org/type/List#routine_sum) 使用时，它们被强制为数字值。

```raku
my $input = $*ARGFILES.slurp;

my $elves = $input.split("\n\n");
my @totals = $elves.map: *.lines.sum;

# part 1
put @totals.max;

# part 2
put @totals.sort.tail(3).sum;
```

## [第三天](https://adventofcode.com/2022/day/3)：重新组织背包

我们有一个字母串的列表，我们想找到 1）每个列表的前半部分和后半部分有共同点的字母，以及 2）三个字符串的组有共同点的字母。然后我们要对这些字母对应的数值进行求和。

我们用 `%vals` 的来映射字母和它们的值。注意，`Z` 代表 "zip" -- 它结合了两个列表。它需要一个操作符作为参数，所以通过给它一个配对构造操作符，`=>`，我们构造一个配对列表。当我们把它存储在 `%vals` 中时，这就变成了一个哈希值。`Z` 被称为"元运算符"，因为它是一个使用其他运算符的运算符。

另一个元运算符是 `[]` -- 也被称为 `reduce`。它将一个二元运算符应用于列表的连续元素。

例如, `[+] (a,b,c,d)` 即 `a + b + c + d`。

当我们使用[集合相交](https://docs.raku.org/language/operators#index-entry-Intersection_operator)，`∩` 与元规约运算符时，我们是取一个列表的交集。所以对于 part 1，`[∩]` 是列表的前半部分和后半部分的共同元素，而对于 part 2，`[∩]` 是三个列表的交集。

另外，[comb](https://docs.raku.org/type/Str#routine_comb) 将一个字符串分成若干个字符，而 [rotor](https://docs.raku.org/type/Any#method_rotor) 一次取几个列表的元素。

顺便说一下，`∩` 可以写成 `(&)`: 所有 Raku 的 unicode 操作符都有 ASCII 的对应物。

```raku
my $in = $*ARGFILES.slurp;

my %vals = ('a'..'z','A'..'Z').flat Z=> 1..52;

# part 1
say sum $in.lines.map: -> $backpack {
    %vals{ [∩] $backpack.comb[0 .. */2 - 1, */2 .. * ] }
}

# part 2
say sum $in.lines.rotor(3).map: -> $group {
  %vals{ [∩] $group.map(*.comb) }
}
```

## [第6天](https://adventofcode.com/2022/day/6)：调优问题

我们要找到第一次连续四个字符都不一样的情况。第二部分是 14 个。

我们将字符串梳理(`comb`)成一个字母序列(`sequence`)，并将该序列转换成一个列表。

然后 -- 还记得上面的 [rotor](https://docs.raku.org/type/Any#method_rotor) 吗？ 它可以接受一个 `Pair` 作为参数来返回一个有重叠的列表(即1,2,3,2,3,4 等)。这对这个问题来说是很方便的!

同样 [first](https://docs.raku.org/type/List#routine_first) 搜索一个列表的元素。而当我们给它加上副词 `:k` 时，我们得到的是索引，而不是元素。这对今年的几个问题很有用。

```raku
my $in = $*ARGFILES.slurp.comb.list;

# part 1
say 4 + $in.rotor(4 => -3).first: :k, *.unique.elems == 4;

# part 2
say 14 + $in.rotor(14 => -13).first: :k, *.unique.elems==14
```

## [第7天](https://adventofcode.com/2022/day/7)：设备上没有剩余空间了

我们正在检查各种 `cd` 和 `ls` 命令的输出，以计算文件系统上目录的大小，并找到使用空间最多的目录(part 1)和要删除以释放一些空间的最小目录集(part 2)。

这里有几件有趣的事情。

首先，我们可以制作一些 `regex`es，作为 `when` 语句中匹配的构造块儿。然后可以在相应的语句中使用这些 regexes 的名称。也就是说，我们制作一个名为 `dir` 的 regex，然后在使用 `<dir>` 进行匹配后，我们可以引用 `$<dir>` 来获得匹配结果。`$<dir>` 完全等同于 `$/<dir>` -- 特殊变量 `$/` 包含了匹配的结果，它持有命名捕获，像 `dir`、`size` 和 `filename`。Raku 的一个很好的特点是它使 regexes 成为可组合的 -- 这是一个使用这一特点的小例子。

另外，`when` 子句中的 `:s` 意味着空白是重要的：例如 `cd` 和 `<dir>` 之间的空格将与输入中的空白匹配。

第二，还记得上面的元规约运算符 `[]` 吗？那么还有一个带有 `\` 的版本，叫做"三角形"元规约运算符。不同的是，这个会返回中间的结果:

- `[+] (a,b,c,d)` 即 `a + b + c + d`
- `[\+] (a,b,c,d)` 即 `(a), (a+b), (a+b+c), (a+b+c+d)`

我们可以使用连接法，即 `~`，而不是 `+`, 来获得某个子目录的所有父目录。( `/a`, `/a/b`, `/a/b/c`...)

另外，`»+=»` 是另一个超运算符--这在两个列表之间成对地应用 `+=`，即执行向量加法。(它也可以写成 `>>+=>>`）。列表重复操作符 `xx`，只是重复一个元素来创建一个列表。

```raku
my $in = $*ARGFILES.slurp;

my @cwd = '/';
my %totals;

my regex dir { <[a..z]>+ }
my regex size { <[0..9]>+ }
my regex filename { \w+ }

for $in.lines {
  when /:s '$' cd '/'    / { @cwd = ('/')         }
  when /:s '$' cd <dir>  / { @cwd.push("$<dir>/") }
  when /:s '$' cd '..'   / { @cwd.pop             }
  when /:s <size> <filename>/ {
    %totals{ [\~] @cwd } »+=» $<size> xx *
  }
}

# part 1
say %totals.values.grep( * <= 100_000).sum;

# part 2
my $total-space = 70_000_000;
my $unused = $total-space - %totals{ '/' };
my $need = 30_000_000;
my %choices = %totals.grep: { $unused + .value > $need }
say %choices.values.min;
```

## [第8天](https://adventofcode.com/2022/day/8)：树顶树屋

我们有一个数字网格，我们想: (1) 找到所有从网格外可以看到的树，(2) 找到最"风景优美"的地方。

首先，`X` 是交叉乘积元运算器。像 `Z`（上文）一样，它需要两个列表，但不是对应的元素，而是需要所有可能的配对。也就是说，`1,2 X~3,4` 是 `13,14,23,24`。

顺便说一下，你可以制作你自己的中缀运算符。所以，`🌳` 是一个运算符，它可以找到一个列表中第一个大于给定值的元素的索引。

然后，我可以用 `X` 在所有四个方向上应用这个，并取得乘积（用 `[*]` 来化简它），然后跟踪最大值（用于 part 2）。

对于第一部分 -- [all](https://docs.raku.org/type/Any#method_all) 和 [any](https://docs.raku.org/type/Any#method_any) 是 [Junction](https://docs.raku.org/type/Junction)。Junction 是一个很好的结构，因为它们把单个的值变成了值的叠加--一个更简单的例子是 `1 == any(1,2,3)`，它把 1 和其他三个值进行比较。这些都是自动运行的--意味着表达式可能同时在不同的线程中被并行评估。

另一个很好的事情是能够在一个二维数组的任何方向上取一个片断，像这样: `@forest[row^...N;col]`。

范围操作符，`..`，构造了一个有两个端点的 `Range`，变体 `^..` 和 `..^` 可以用来切除左边或右边的端点。另外，`^5` 也是一个范围--从 0 到 4 的数字。

哦，还有，表达式 `$in.lines».comb` 将 `.comb` 应用到每一行。操作符 `»` 是一个"超操作符" -- 它等同于 `map`，除了它也可能自动线程化。

你可能还注意到，其中一些变量是用 `\` 声明的 -- 这使得它们可以在没有符号的情况下使用，例如，`N`、`height`、`row` 和 `col`。在很明显的情况下，如果某样东西是什么类型的变量，不加符号会更干净，而不是每次都在它前面加个 `$`。

```raku
my $in = $*ARGFILES.slurp;
my @forest = $in.lines».comb;
my \N = @forest.elems - 1;

sub infix:<🌳>(@trees,\height) {
  return $_ + 1 with @trees.first: :k, * >= height;
  @trees.elems
}

my ($visible, $scenic-score) = (0,-Inf);
for 0..N X 0..N -> (\row, \col) {
  my \height = @forest[row;col];

  $visible++ if [
    @forest[row;^col].all, @forest[row;col^..N].all,
    @forest[^row;col].all, @forest[row^..N;col].all
  ].any < height;

  $scenic-score max= [*] [
    @forest[row;^col].reverse, @forest[row;col^..N],
    @forest[^row;col].reverse, @forest[row^..N;col]
  ] X🌳 height
}

say $visible;     # part 1
say $scenic-score # part 2
``` 

## [第13天](https://adventofcode.com/2022/day/13)：求救信号

第 13 天，我们被要求创建一个新的比较运算符。根据操作数是整数还是列表，该操作符应该有不同的表现。

首先，为了将一串括号和逗号转换成一个嵌套的列表，我们使用 `JSON::Fast` 的 `from-json`。(用 `zef install JSON::Fast` 来安装它 )

我们在输入中使用两次超运算符 `»` -- 一次将所有的 Pair 变成两个字符串，然后一次将两个字符串中的每一个变成 json。同样，这个操作符的工作原理和 `map` 一样。

这个问题是制作自定义运算符的一个更好的例子--因为这个问题基本上描述了一个新的运算符。这次我们做了一个叫做 `◆` 的运算符，我们可以使用多重分派。

当我们用 `multi` 定义一个函数时，它就是一个多重分派的候选函数；也就是说，参数中的调用被映射到具有匹配签名的版本中。我们是在比较两个整数吗？我们是在将一个列表与一个整数进行比较吗？我们是在比较两个列表吗？这些候选者与问题描述中的可能性相对应。

我们可以递归地使用我们自定义的这个操作符，我们可以和 `Z` 一起使用，我们也可以退回到众所周知的宇宙飞船操作符 `<=>`，它只是比较两个整数。

最后，当我们对列表进行扁平化处理时，我们使用语法 `@lines[*;*]` -- 这将一个列表的列表变成一个列表，然后我们可以在找到它们的索引前将哨兵值附加到这个列表上（再次使用 `first` 方法）。

```raku
use JSON::Fast;

my $in = $*ARGFILES.slurp;
my @lines = $in.split("\n\n")».lines».map: &from-json;

# ◆: compare packets
multi infix:<◆>(Int $a, Int $b) { $a <=> $b   }
multi infix:<◆>(@a, Int $b)     { @a ◆ [ $b ] }
multi infix:<◆>(Int $a, @b)     { [ $a ] ◆ @b }
multi infix:<◆>(@a, @b) {
  (@a Z◆ @b).first(* != Same) or (@a.elems <=> @b.elems)
}

# part 1
my @less = @lines.grep: :k, { .[0] ◆ .[1] == Less }
say sum @less »+» 1;

# part 2
my @flat = |@lines[*;*], [[2],], [[6],];
my @sorted = @flat.sort: &infix:<◆>;
my $first  = 1 + @sorted.first: :k, * eqv [[2],];
my $second = 1 + @sorted.first: :k, * eqv [[6],];
say $first * $second;
```

## 结语

这篇文章展示了 Raku 编程语言的一些独特功能：超运算符、元运算符、自定义运算符、可组合的 regexes、Junction，以及各种用于制作匿名函数的结构。

其他代码问题的解决方案可以在[这里](https://git.sr.ht/~bduggan/advent-of-code/tree/master/item/2022)找到。未来的一篇博文可能会对每一个问题有更多的阐述。
