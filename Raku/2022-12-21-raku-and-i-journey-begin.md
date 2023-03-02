原文链接: https://raku-advent.blog/2022/12/21/day-21-raku-and-i-journey-begin/

![img](https://rakuadventcalendar.files.wordpress.com/2022/12/raku-and-i.png)

我已经很久没有在博客上写过关于 Raku 的文章了。唯一的一次，是我参加[每周挑战赛](https://theweeklychallenge.org/)时写的博客。但最近这种情况也发生了变化，因为我终于找到了时间为每周的趣味挑战做贡献了，但仍然没有写博客。

我想说这都是我的精神状态问题，因为我要谈论的东西太多了。最近，一位非常亲爱的朋友和 Raku 社区的资深成员找到我，问我是否有兴趣为2022年的 [Raku 降临节](https://raku-advent.blog/category/2022)做贡献。因此，正如你所猜测的那样，我有了一个令人信服的理由重新开始写博客。

但是，你知道....

我总是有太多的事情要做，所以要完成一些新的事情总是很棘手。然而，我已经下定决心，无论如何我都要给它一个最好的机会。

我做到了...

那我要谈些什么呢？

了解我的人都知道，我本质上是一个 Perl 迷。尽管如此，最近我开始玩其他语言，这要感谢 PWC 团队这个充满活力的团体。在这篇博文中，我想谈谈我对新发现的 Raku 语言的每周挑战的一些贡献。

# 1: Prime Sum

给你一个数字 `$N`。编写一个脚本来找到所需的最小素数，这些素数的和为 `$N`。

由于 Raku 强大的内置功能，如果你知道你在做什么，这就是小菜一碟。对我来说，所有的问题都可以在 Raku 官方文档中找到答案。如果找不到，那么我就在各种社交平台上问我的朋友。十有八九我都能立即得到答案。

所以在这个例子中，所有的艰苦工作都是由 `is-prime` 完成的。我是方法链的忠实粉丝，你可以在下面看到。为了方便读者，我遍历了列表 `2..$sum`，并过滤出了所有 `is-prime` 的内容。

不是很美吗？对我来说，确实。

```raku
sub find-prime-upto(Int $sum) {
    return (2..$sum).grep: { .is-prime };
}
```

现在有了这个方便的子程序，我们就可以像下面这样解决这个任务了。

对于刚接触 Raku 的 Perl 朋友来说，唯一可能困扰你的是 `[+]` 的使用，对吗？

它是归约运算符 `[]`，适用于值的列表。

```raku
sub prime-sum(Int $sum) {
    my @prime = find-prime-upto($sum);
    my @prime-sum = Empty;

    for 1..$sum -> $i {
        for @prime.combinations: $i -> $j {
            my $_sum = [+] $j;
            @prime-sum.push: $j if $_sum == $sum;
        }
    }

    return @prime-sum;
}
```

现在把所有东西粘在一起，像下面这样:

```raku
use v6.d;

sub MAIN(Int $SUM where $SUM > 0) {
    prime-sum($SUM).join("\n").say;
}
```

这还没完，加上单元测试就很好了:

```raku
use Test;

is-deeply prime-sum(6).<>,  [],                  "prime sum = 6";
is-deeply prime-sum(9).<>,  [(2, 7),],           "prime sum = 9";
is-deeply prime-sum(12).<>, [(5, 7), (2, 3, 7)], "prime sum = 12";

done-testing;
```

# 2: Fibonacci Sum

编写一个脚本，找出所有可能的斐波那契数的组合，以便相加后得到 `$N`。

你不允许重复数字。如果没有找到就打印 0。

你可能会发现下面的解决方案与上面的工作有些类似，但对于 Perl 迷来说，还有一些新的东西。在 Perl 中，我们可以用 `$list[-1]` 得到列表中的最后一个元素，但在 Raku 中，情况略有不同，如下所示。

还有一件事，如果你细看，参数检查是在签名本身中完成的，这在 Perl 中是没有的。

Raku rocks!!!

```raku
sub fibonacci-series-upto(Int $num where $num > 0) {
    my @fibonacci = (1, 2);
    while @fibonacci.[*-1] + @fibonacci.[*-2] <= $num {
        @fibonacci.push: @fibonacci.[*-1] + @fibonacci.[*-2];
    }

    return @fibonacci;
}
```

现在我们准备解决下面的任务。

你注意到这里有什么特别之处吗？

是的，`.combinations` 同样都是内置的，不需要导入任何库。它生成了所有给定尺寸的可能组合。

```raku
sub fibonacci-sum(Int $sum where $sum > 0) {
    my @fibonacci     = fibonacci-series-upto($sum);
    my @fibonacci_sum = Empty;

    for 1 .. $sum -> $i {
        last if $i > @fibonacci.elems;
        for @fibonacci.combinations: $i -> $comb {
            my $_sum = [+] $comb;
            @fibonacci_sum.push: $comb if $_sum == $sum;
        }
    }

    return |@fibonacci_sum;
}
```

最后的应用程序如下:

```raku
use v6.d;

sub MAIN(Int :$N where $N > 0) {
    fibonacci-sum($N).join("\n").say;
}
```

也是时候进行一些单元测试了:

```raku
use Test;

is-deeply fibonacci-sum(6), ((1,5), (1,2,3)), "fibonacci sum = 6";
is-deeply fibonacci-sum(9), ((1,8), (1,3,5)), "fibonacci sum = 9";

done-testing;
```

# 3: Count Set Bits

给你一个正数 `$N`。

编写一个脚本来计算从 `1` 到 `$N` 的所有数字的二进制表示的总位数并返回 `$total_count_set_bit % 1000000007`。

对于这个任务，Raku 已经内置了大部分的功能，所以没有什么需要发明的。

正如你所看到的，这是一个单行代码，`(1..$n).map(-> $i { $c += [+] $i.base(2).comb; });` 所有的工作一行就完成了。

`.map()` 的工作原理与 Perl 中的相同。在这个例子中，每个元素被分配给 `$i`。此外，`$i` 被转换为基数2，即二进制形式，然后使用 `.comb` 将其分割成单个数字。

你怎么能不爱上 Raku 呢？

```raku
sub count-set-bits(Int $n) {
    my $c = 0;
    (1..$n).map( -> $i { $c += [+] $i.base(2).comb; });
    return $c % 1000000007;
}
```

这是与之配套的单元测试:

```raku
use Test;

is count-set-bits(4), 5, "testing example 1";
is count-set-bits(3), 4, "testing example 2";

done-testing;
```

# 4: Smallest Positive Number

给你一个未经排序的整数列表 `@N`。

编写一个脚本，找出缺少的最小的正数。

这个任务向我介绍了一些我以前没有意识到的新东西。

我一直想对输入列表中的元素进行检查。在这个任务中，我检查给定的输入列表中的每个元素都是整数。同时，返回值也是整数类型的。所有这些都通过一行 `@n where .all ~~ Int --> Int` 完成。这就是 Raku 的威力，我们可以在我们的脚本中拥有这种威力。

同样，要对一个列表进行排序，只需使用 `.sort` 和 `.grep` 就可以使它非常强大。

`.elems` 给出列表中元素的总数。

```raku
sub smallest-positive-number(@n where .all ~~ Int --> Int) {

    my @positive-numbers = @n.sort.grep: { $_ > 0 };
    return 1 unless @positive-numbers.elems;

    my Int $i = 0;
    (1 .. @positive-numbers.tail).map: -> $n {
        return $n if $n < @positive-numbers[$i++]
    };

    return ++@positive-numbers.tail;
}
```

最终的应用看起来像下面这样。

你看到一些新的东西了吗？

嗯，它显示了如何设置默认参数值。

```raku
use v6.d;

sub MAIN(:@N where .all ~~ Int = (2, 3, 7, 6, 8, -1, -10, 15)) {
    say smallest-positive-number(@N);
}
```

又到了单元测试的时间:

```raku
use Test;

is smallest-positive-number((5, 2, -2, 0)),  1,
   "testing (5, 2, -2, 0)";
is smallest-positive-number((1, 8, -1)),     2,
   "testing (1, 8, -1)";
is smallest-positive-number((2, 0, -1)),     1,
   "testing (2, 0, -1)";

done-testing;
```

# 结论

学习 Raku 是一个持续的旅程，我很喜欢它。说实话，我还没有分享所有的东西。如果你有兴趣，那么你可以在我的[收藏](https://theweeklychallenge.org/blogs)中查看其余的内容。

享受休息，保持安全。