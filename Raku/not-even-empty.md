另一个周末, 另一个兔子洞。在阅读 Arne 针对挑战 [#213](https://theweeklychallenge.org/blog/perl-weekly-challenge-213/) 的[解决方案](https://raku-musings.com/fun-route.html)时, 我心想：“如果任务可以用一句话来写, 为什么答案要多于一行？”。一个合理的问题, 因为答案是用 Raku 写的。经过一番摆动, 我找到了一个较短的版本。

```raku
my @list = <1 2 3 4 5 6>;
@list.classify({ .Int %% 2 ?? 'even' !! 'odd'}){'even','odd'}».sort.put;
```

使用 `.classify`, 正如 Arne 所做的那样, 是关键, 因为 `postcircumfix:<{ }>` 需要不止一个键。结果列表是 `hyper-.sorted` 和 `.put` 不仅会显示超过 100 个元素（请不要使用 `say` 除非你真的想要那个）而且还会展平。

在他的帖子中, 他解决了一些错误处理问题。我也想要那个, 令我高兴的是 `X::Str::Numeric` 将不可转换的东西存储在 `.source` 中。

```raku
CATCH {
    when X::Str::Numeric { put „Sorry, I don't know how to handle "{.source}" in my input list.“ }
}
```

但是我将如何处理未定义的值？这并不牵强。如果你从不太理想的 Excel 工作表中弹出一些 CSV, 或者没有考虑 SQL 空值的可能性, 你很容易得到一个你不想要的类型对象。对于标量, 我们可以使用类型表情来保护代码。

```raku
sub foo(@a) { say @a.elems };
foo(List); # 1
```

对我来说, 数组或列表是一个（半无限长且非常窄的）盒子的地方, 它可能包含东西, 本来可以, 但不是。Rakudo 不关心, 只是将未定义的值绑定到 `@-sigiled` 符号。像往常一样, 我在 IRC 上[受到启发](https://irclogs.raku.org/raku-dev/2023-04-23.html#09:19-0003)。 `Any.list` 会尽量把单个元素变成一个只有一个元素的 List。对于 42, 这非常有意义, 让我们在日常代码中更少担心。对于导致问题的类型对象：“你体内存储了多少东西？”, 用废话来回答。得知这会导致难以追踪错误, 我不会感到惊讶。我的 `.t` 文件通常不会针对未定义的值进行大量测试, 因为我错误地认为 `:D` 会保护我不受伤害。

```raku
sub bar(@a where .[0].defined) { say @a.elems };
bar(List);
```

这是丑陋的, 不精确的, 并没有真正做到我想要的。当 `where` 子句被触发时, 绑定就已经发生了。我觉得正确的解决方案是让 `Any.list` 在调用类型对象时失败。正如 lizmat 指出的那样, 这是一个突破性的变化。它可能看起来是良性的, 但那里有大量依赖于草率处理未定义值的意外容错代码。在 IRC 讨论中, lizmat 表示她不喜欢 `my @a := Int;` 实例。我实际上对此感到还好, 因为 Raku 程序员的意图（我们想要更多, 不是吗？）很明确。当签名中的 `@-sigiled` 符号（不是 `@-sigiled` 容器！）绑定到类型对象时, 无声的情况让我担心。当然可以更改它, 但可能会对性能产生影响。这也可能是一个重大变化, 很难说我们可以通过修复解决多少潜伏的错误。

然而, 我真的希望 Raku 没有 WAT, 因为我当然希望 Raku 更具粘性。

更新:

以下内容可用于使 `.elems` 尽早失败。`prefix:<+>` 没有通过该方法导致 `+@a` 返回 0, 而 `.elems` 为 1。此外, `Parameter.modifier` 是一个 ENODOC。

```raku
Any.^can('elems')[0].candidates.grep({ .signature.params[0].&{ .type, .modifier } ~~ (Any, ':U') }).head\
   .wrap(my method elems { die(‘Abstract containters don't know how to count’) });
```

## 原文链接

https://gfldex.wordpress.com/2023/04/23/not-even-empty/
