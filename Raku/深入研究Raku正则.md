# 深入研究 Raku 的 regexes ，并带回了一个更好的 grammar 协作方式

在我[上一篇关于在 Raku 中协调多个 grammar 的文章](https://www.codesections.com/blog/grammatical-actions/)得到一些[很好的反馈](https://www.reddit.com/r/rakulang/comments/stpvft/grammatical_actions_further_thoughts_on/)后，我意识到我在 Raku(do) 中对 regexes 心智模式的认知基本上是错误的。这个有缺陷的模式并没有阻止我使用 regexes ，但它是错误的 - 它使我无法正确地掌握 grammar 中涉及的一些更复杂的行为。现在我已经纠正了这个误解，一切都变得更有意义了！

> 注意：这不是关于实现一个 regexes 引擎的问题（也是非常重要的！）；对有限状态机、NFA 和 DFA 以及所有这些有趣的主题的关注都不在我们的范围之内。当我在这篇文章中提到 Raku 的 regex “实现”时，我指的不是运行 regex 的底层低级实现；相反，我说的是 Raku 如何处理用户提供的 Regexes 的语法和语义，“然后它执行 regex”是一个小步骤。

在这篇文章中，我将简要介绍我的错误观点（希望有足够的轮廓，使你能理解我的出发点，但不会陷入到同样的困惑中），然后介绍正确的（或至少是较少的错误）心智模式。对这个模式的探索将使我们对 Raku 的 regexes 工作原理有更深的理解（或者，至少，比我一周前的理解更深刻；正如他们所说，YMMV）。接下来，我将解释这种新的理解是如何让我构建一个 trait 的 - 我相信这将使组合多个 grammar 变得更加容易。最后，我将快速带你浏览一下实现该 trait 所涉及的大约 100 行代码。

让我们一起学习一下 Raku 吧 **»ö«**

## 为 Raku regexes 建立正确的心智模式

也许我们已经有了 Raku 的 regexes 多年使用经验, 但并不了解它们是如何工作的。它们是一个很好的抽象，像所有好的抽象一样，它们的大部分力量来自于你不需要了解它们的具体实现。尽管如此，我总是发现，当遇到困难的时候，拥有一个好的抽象下的细节的一般模式是非常有帮助的，我认为 Raku 的 regexes 是这个原则的一个很好的例子。

> 从我们讨论实现细节的事实中可以明显看出，这篇文章的大部分内容将集中在 Raku**do** 上 - Raku 作为一个整体是由 [Roast](https://github.com/Raku/roast) 指定的，它不致力于具体的实现。也就是说，我们要讨论的大部分 regexes/grammar 行为都是特定的，其余大部分都与 [NQP](https://github.com/Raku/nqp/) 有很深的关系。所以我非常确定，这篇文章中的几乎所有内容都将适用于任何未来的 Raku 实现，而不仅仅是 Rakudo。

## Regex.isa(Method)。好吧，这是什么意思？

我很早就知道 `Regex` 是 `Method` 了；文档在这一点上非常清楚，而且我在多个帖子中都提到了这一点。(首先，[Regex 类型文档](https://docs.raku.org/type/Regex)中的第一行就是 `Class Regex is Method { }`！）。但是，即使我知道这一点，我也没有深入研究过 - 更不用说深刻理解它的含义了。

具体说来：Regex 是一个方法这一事实在实践中意味着什么？我们可以把 regex 作为子例程来调用吗？如果可以，如何调用？而且它是一个方法，但是是什么对象上的方法？它的签名是什么？它返回什么？像大多数 rakoons 一样，我总是通过像 `'foo' ~~ /<word>/` 这样的语法与 regexes 交互，而不是把 regex 当作一个 `Routine`。而且，为了清楚起见，这绝对是我们应该在几乎所有的时间里都使用 regexes 的方式 - 但是，为了更深入地理解 regex 作为例程的后果，让我们研究一下，假设我们如何以更多的 `Routine` 方式与 regex 互动。

## 一个糟糕的和错误的心智模式

在没有深思熟虑的情况下，我把 regexes 想象成一个经典的类，在面向对象编程的意义上，或多或少。也就是说，我把 `Regex` 想象成一个为任何特定搜索创建新对象的类，每个对象根据它所搜索的文本存储和更新内部状态。

为了使这个模式更加具体，我想象 `my Regex Rx { foo \s bar}` 这一行创造了一些大致如下的伪代码（不过，很遗憾，我没有完全思考过的心智模式没有附带代码样本，所以我几乎没有考虑到这么多细节）。**请注意，下面的写法是完全错误的:**

```raku
# Broken, do not try
my class Rx is Regex {
    my $rx-body = ' foo \s bar ';

    has     @!input-chars;
    has Int $!pos = 0;

    method CALL-ME(Rx:U: Str() $input  - > Match) {
       my $rx = self.bless: :input-chars($input.comb);
       $rx!match
    }

    method !match {
        while 0 ≤ $!pos ≤ @!input-chars.elem {
            my $c := @!input-chars[$pos];
            if MATCHER($c, $rx-body) === PartMatch { $pos++ }
            #  ^^^ somehow handles backtracking?
            if MATCHER($c, $rx-body) === FullMatch {
                return Match(FullMatch) }
            else { $pos -  }
        }
        $pos < 0 { return Match('#<failed match>') }
    }
}

# Hypothetical useage:
Rx('foo bar');
```

而将这种基于 OOP 的心智模式扩展到 grammar 上感觉非常简单。一个 `Grammar` 只需要存储多个 `%rx-bodies`，并能够在它们和该 `Grammar` 声明中描述的 token/rule 名称之间进行转换（哦，我想还有一点设置和调用 action 对象的逻辑）。

正如我们将看到的，这个模式被证明是完全错误的。但是，我希望你能从上面的大纲中看到，它是合理的错误。而且，事实上，它是合理的，以至于我能够在相当长的一段时间内使用 regexes 和 grammar 而没有意识到它错得有多离谱。

## 摇摇欲坠的地基

这个有缺陷的心智模式，无论多么有道理，都经不起我上一篇文章之后的讨论中出现的证据。特别是，它经不起我从 Matthew Stuckwisch（[#raku IRC 频道](https://raku.org/community/irc)上的 guifa，r/rakulang 和 GitHub 上的alatennaub；我在这里用 "guifa"）那里学到的东西。

Guifa 的评论与[引发整个讨论的帖子](http://clarkema.org/lab/2022/2022-02-09-raku-multiple-grammars/)有关。在那篇文章中，Mike Clark 介绍了一种 grammar，它可以解析一种主语言，然后使用第二种 gramamr 来解析嵌套在主语言中的类似 lisp 的语言。

下面的代码显示的是删除了 Mike 的注释后的简化版本；如果你想了解更多细节，请看[原帖](http://clarkema.org/lab/2022/2022-02-09-raku-multiple-grammars/)。

```raku
grammar InnerLang {
    rule TOP { \s+ | ['(' ~ ')' .* ] }
}
grammar MainLang  {
    rule TOP       { [<.text-like> <lisp-like>*]* }
    rule text-like { [ <.alpha>+ ]+}

    rule lisp-like {
        :my $inner;
        <?{ $inner
              = InnerLang.subparse: $/.orig, :pos($/.to) }>
        .**{$inner.to - $/.pos}
    #   ^^^^^^^^^^^^^^^^^^^^^^^ I really dislike this part
    }
}
```

正如我在上面的评论中指出的，我真的不喜欢需要在我们的外部 grammar 中这样管理状态的想法 - 在简单的情况下还不算太糟，但随着 grammar 越来越大，它给我的印象是很多容易出错的、棘手的工作。而且，即使做得正确，我仍然会有与并发有关的担忧 - 让我们的代码的两个部分对我们已经解析的输入量有不同的看法，似乎会招致那种调试起来是噩梦的错误。(也许这是偏执狂，但我以前被坑过）。

但是 [guifa 的回答](https://www.reddit.com/r/rakulang/comments/stpvft/comment/hx5f750/?utm_source=share&utm_medium=web2x&context=3)指出了上述代码的一些问题，这确实让我感到惊讶，一旦我想清楚了其中的含义，就会推翻我上面描述的心智模式。Guifa 的评论并没有完全这样说，但主要的启示是，我们可以把上面的 `lisp-like` 的 rule 改写成:

```raku
method lisp-like {
    InnerLang.subparse: $.orig, :pos($.to)
}
```

也就是说，如果我们把 `rule lisp-like` 改为 `method lisp-like`，把我们的 `$/.` 调用改为 `$.`，那么我们就可以把我们的代码减少一半，并去掉前一个版本中困扰我的所有记帐。当我意识到这一点时，我立即有两种反应："这真是太棒了！"和"等等，但是怎么做呢？

如果你没有同样的 "但是怎么做？"的反应，这里有一些我很疑惑的问题。

- 如果我们在 `MainLang` 中更新当前的匹配位置，为什么方法会[自动地](http://www.catb.org/jargon/html/A/automagically.html)设置该状态？Raku 通常很好地避免了这种魔法，所以在这里看到它很奇怪。
- 为什么 rule/token 不以同样的方式更新状态？*rule* 是一个方法 - 具体地说，是[定义它的](https://stackoverflow.com/a/56799018) `Grammar` 的[一个方法](https://stackoverflow.com/a/56799018)，所以任何适用于 `Method` 的魔法行为都应该包括 *rule* 和 *token*。
- 即使抛开任何神奇的行为，为什么我似乎不能从 rule 的主体中手动更新 `MainLang` 的状态？我可以用 `$.pos` 查看当前的位置，而且这个方法似乎也在修改这个状态，但是从 rule 内部看来，它确实是私有的 - 这怎么可能呢？

在对着这些问题一通操作之后，我意识到答案就在第一句话里。"如果我们正在更新 `MainLang` 中的当前匹配位置......"  - 好吧，事实证明，我们根本没有更新任何 `MainLang` 的状态；事实上，从我们的角度来看，`MainLang` 几乎是无状态的。

## 范式的转变

我们没有更新 `MainLang` 中的位置状态，因为 - 与我的假设相反，尽管有 `$.pos` 方法的存在 -  `MainLang` 并没有存储任何（可变的）状态。而这又是因为我上面提出的基于 OOP 的全状态心智模式是错误的。不仅仅是 grammar，它对 regexes 也是错误的。

这方面的第一个线索是，我们实际上不能用我上面想象的 `Rx('some text')` 调用语法来调用 *regex*、*token* 或 *rule*。如果我们尝试了，我们会得到以下错误：

```raku
my regex Rx { . }
say Rx('some text');
# OUTPUT: «No such method '!cursor_start' for invocant of type 'Str'»
```

这条错误信息并不直观；如果 Raku 能达到其通常的令人惊叹的错误信息的标准，它应该得到这样的错误:

    Type check failed in binding to parameter 'topic'; expected Match but got Str ("foo")

> 我相信有 Junction/autothreading 的原因，regexes 需要有一个 `Mu` 类型约束。但如果能有一个更清晰的错误就更好了。

好的，所以 `Rx('text')` 不起作用，因为它不做类型检查；我们需要提供一个 `Match` 而不是文本。但为什么呢？如果我已经有了一个匹配，为什么还要把这个匹配传给 regex？难道 regexes 不是搜索字符串并返回匹配吗？

不，事实证明，regexes（或者说 `Regex`）并不搜索字符串 - 因为要这样做，它们就必须按照我想象的思路来跟踪和改变状态。相反，最佳的方式是把 `Regex` 想像成一个无状态函数，其签名是 `method(Match:D  --> Match:D)`：`Regex` 接收一个 `Match` 并返回一个 `Match`，`Match` 的工作就是包含关于现有状态的数据。

这意味着用 `Routine` 语法调用 regexes 的实际方法是下面这样的：

```raku
my rule word { <alpha>+ }
say &word.WHAT;            # OUTPUT: «(Regex)»
#   ^ & sigil required b/c it does Callable
try word('a');
#        ^^^ Regexes don't take Str arguments
say $!.^name;              # OUTPUT: «(X::Method::NotFound)»

my $match = Match.new: :orig('Raku is -Ofun');
# call with ^^^^^^ a Match:D with the Str in :orig
say word($match);          # OUTPUT: «｢Raku｣»

# We can build a non-zero match using :to and :from
my $m2 = Match.new: :orig('Raku is -Ofun'), :from(0) :to(8);
say $m2;                   # OUTPUT: «｢Raku is ｣»
# And we can use that Match normally:
say $m2.&(/'-' \w**4/);    # OUTPUT: «｢-Ofun｣»
#         ^^^^^^^^^^^ regex-literal syntax also works

# A Regex is a Method and a Routine
say &word.^mro[1..4];      # OUTPUT: «((Method) (Routine) (Block) (Code))»
say $match.&word;          # OUTPUT: «｢Raku｣»
# so using ^^^^^^ method syntax might be more fitting

# A regex also returns a Match:
my $res = word $match;
say $res.WHAT;             # OUTPUT: «(Match)

# But *not* the same Match it got:
say $match.WHICH;          # OUTPUT: «Match|94080907590240»
say $res.WHICH;            # OUTPUT: «Match|94080907590384»
say $match, $res;          # OUTPUT: «(｢｣ ｢Raku｣)»
#   ^^^^^^ the Match we started with is unchanged

# The returned Match records where we are in the input string:
say $res.raku; #`[ OUTPUT: «Match.new( :orig("Raku is -Ofun"),
                                       :from(0), :pos(5) )» ]
# Which lets us use it as input for a new match:
say my $r2 = $res.&word; # OUTPUT: «｢is ｣»
say $r2.raku;  #`[ OUTPUT: «Match.new( :orig("Raku is -Ofun"),
                                       :from(5), :pos(8) )» ]
```

上面的代码中值得强调的一点是：不仅 regexes(纯的) 是签名为 `Match --> Match` 的函数，它们还返回一个与它们所给的不同的 `Match`。也就是说，regexes 与 `Match` 交互，就好像后者是不可变的数据容器。

> 我不想把这一点扯的太远：在现实中，`Match` 不是不可变的 - 事实上，上面的代码故意省略了更复杂的匹配，因为复杂的匹配不经过改变(mutation)就无法最终确定。这种改变并不发生在 `Regex` 代码内部，而且据我所知，并不涉及来自 `Match` 外部的任何数据 - 从外部来看，它们实际上仍然是不可变的。但是建立我们习惯起效的匹配对象需要改变。

```raku
my $match = Match.new: :orig('The language Raku is -Ofun');
my $res = $match.&(/:s[\w+ ]**2<($<name>=[\w+] is (.*)/);
say $res;       # OUTPUT: «｢The language Raku is -Ofun｣»
# No capture groups, etc   ^^^^^^^^^^^^^^^^^^^^^^^^^^^

#    vvvvv the `MATCH` method `is implementation-detail`
$res.MATCH;
#    ^^^^^ $res is modified in place
say $res;       # OUTPUT: «｢Raku is -Ofun｣
                #           name => ｢Raku｣
                #           0 => ｢-Ofun｣»
```

> (我**认为**，`Match` 的（不）可变性与 `Cursor` 和 `Match` 之间的历史区别有关。我相信过去有一个单独的不可变的 `Cursor` 类，用于正在进行的匹配，并被折叠到 `Match` 中。我怀疑 `Match` 是不可变的，如果它们以前是 `Cursor` 的话 - 但是我欢迎对这段历史有更多了解的人进行确认/纠正）。

> 但是 `Match` 有时是可变的这一事实并不影响我的观点：我从来没有声称 Raku 的 regex 实现 100% 地遵守了一些严格的纯函数的概念 - 相关的方法并没有用 `is pure` 标记，而且，无论如何，Raku 的自然舒适区是一个更实用的编程风格。

> 相反，我的观点是，在心理上把 regexes 建模为从一个不可变的匹配到另一个不可变的匹配的函数是一个（更）有用的模式，而不是把它们想象成具有封装状态的 OOP 对象。像大多数模式一样，它不是在所有情况下都是正确的，但它是一个非常有用的起点。

## 新范式解决了老问题

现在我们已经有了一个更坚实的基础，让我们回到 grammar 和之前令我困惑的问题：为什么我们把 `rule lisp-like` 改成 `method lisp-like` 就不需要执行记账(bookkeeping)任务了？

让我们在一个稍高的通用水平上回答这个问题：`rule` 声明会被解语法糖成什么方法？也就是说，我们知道 *rule*（像所有的 Regexes 那样）在底层确实是方法。这意味着，如果 Raku 没有给我们 `rule` 声明符，我们可以把我们的 *rule* 写成方法，但要多做一点工作。

而事实上，编写 *rule* 方法仍然是非常可能的。要把替换 *rule* 替换为方法，我们只需要写一个 `Regex` 的方法；这意味着它需要有我们现在熟悉的 `Match --> Match` 签名。这个方法只需要完成以下三个任务。

1. 声明一个有棘轮的、空格有意义的 *Regex*
2. 以该 grammar 为参数调用这个 regex
3. (如果已经设置了 action 对象)调用与该 *token* 同名的 action 方法

或者，把上面的任务写成代码，我们可以把下面这段代码：

```raku
grammar G {
    token TOP { <word>   }
    rule word { <alpha>+ }
}
```

替换为这段代码：

```raku
grammar G {
    token TOP { <word>   }
    method word( --> Match:D) {
        my Match $new := regex {:r:s <alpha>+ }(self);
        $.actions.?word($new) if $new;
        $new
    #   ^^^^ NOTE: returns $new, **not** self. Here, $new is
    # a Grammar (which isa Match), but could be any Match:D
    }
}
```

你知道为什么我们要返回 `$new` 而不是 `self` 吗？我们将 `self` 传给了 regex，regex 将其视为不可变的。所以关于 `self` 的任何信息都不会被改变或更新 - 返回它将是一个空操作，所以我们当然会返回新创建的 `Match`。

这意味着上面声明的 **lisp-like** rule 被解构为这样的东西:

```raku
method lisp-like {
    my Match $new := my regex {:r:s
        :my $inner;
        <?{ $inner
            = InnerLang.subparse: $/.orig, :pos($/.to) }>
        .**{$inner.to - $/.pos}
    }
    $.actions.?word($new) if $new;
    $new
    }
```

而 **lisp-like** 方法则保持原样:

```raku
method lisp-like {
    InnerLang.subparse: $.orig, :pos($.to)
}
```

一旦我们看到这个去语法糖的形式，之前那些令人困惑的问题的答案就非常清楚了。

- 为什么方法要设置 `$.pos`(`$.pos`ition) 的状态？它没有 - 它返回一个新的 Match, 这个新的 `Match` 带有自己的新位置。
- 为什么同样的过程不会为 *rule*(或 *token*)自动设置 `$.pos` 呢？因为 *rule* 的返回值来自于以 Grammar 为调用者调用该 *rule*（一个 `Regex`） - 而不是来自于 *rule* 的 *regex* 内部任何代码块的返回值。
- 为什么我们不能通过 `$.pos`、`$/.pos` 或 `$¢` 手动设置位置？因为我们需要设置的 `$.pos` 是将从 *rule* 中返回的新 `Match` 上的位置，而这些变量都没有指向该 `Match`（也不可能，因为它还没有被构建）。

我不知道你怎么想的，但是当我从第一个（不正确的）心智模式转向第二个时，我有一种奇妙的感觉，以前一大堆混乱的东西突然变得有意义了。由于这种转变是如此有帮助(至少对我的理解是如此)，我在这里重申一次：

拒绝这种（非常不正确的）模式：

- `Regex` 是一个封装了当前解析状态的类，并在字符串被匹配时更新该状态。
- `Grammar` 是一种超级 regex，它为一起工作的多个 regex 管理/更新状态，并代表这些 regex 调用解析后的 action 方法。
- `Match` 是用一个 regex 或 grammar 成功解析一个字符串后产生的数据结构，它的存在是为了使这个结果更容易被使用。

采用这种（不太正确的）模式：

- `Match` 是一个部分/全部解析过的字符串的不可改变的快照。
- `Regex` 是一个纯函数，其输入是一个 `Match`，其输出是一个新的（更多解析的）`Match`。
- `Grammar` 是一个匹配，它提供了局部作用域的 regex 方法并调用相应的 action 方法 - 但它仍然是一个不可变的匹配。任何匹配（包括 grammar）都不会被就地更新；相反，它们会被一个新的副本所取代。

## 让心智模式支付租金

这个心智模式当然感觉与我以前从 Raku 的 grammar 和 regexes 中观察到的行为相一致。但是对任何模式的真正测试是它是否能帮助我们对未来有更准确的预期。因此，让我们通过考虑如何改进我们在上面看到的 `MainLang` grammar 来尝试这个模式。这里是我们离开代码的地方。

```raku
grammar InnerLang {
    rule TOP { \s+ | ['(' ~ ')' .* ] }
}

grammar MainLang  {
    rule TOP { [<.text-like> <lisp-like>*]* }
    rule text-like { [<.alpha>+ ]+ }

    method lisp-like {
        InnerLang.subparse: $.orig, :pos($.to)
    }
}

say MainLang.parse($input);
```

这很好 - 简洁得令人惊叹。但它有一个相当大的遗漏：它没有使用任何 action 对象。部分原因是：我不使用 action 对象是为了使代码更加清晰。在 Mike Clark 的[原帖](http://clarkema.org/lab/2022/2022-02-09-raku-multiple-grammars/)中，`MainLang.parse` 和 `InnerLang.parse` 的调用都指定了 action 对象。但我认为这不是一个特别令人满意的解决方案。

特别是，把 action 对象传递给 `InnerLang.subparse` 让我很困扰。在我上一篇文章的 reddit 讨论中，[P6steve 提出了一个重要的观点](https://www.reddit.com/r/rakulang/comments/stpvft/comment/hx7fx3y/?utm_source=share&utm_medium=web2x&context=3)：在一个 grammar 中使用多个 action 对象是 grammar 如此强大的一个重要来源。例如，在上面的语言解析用例中，我们可能想要检查语法而不实际执行代码 - 而传递不同的 action 对象可以让我们做到这一点，而不需要对 grammar 的源代码做任何修改（毕竟，这些代码可能在不同的模块中，并且/或者由其他人维护）。

我将为 OOP 爱好者指出，在运行时传递 action 对象是面向对象设计原则应用的一个绝好例子：用行话说，我们通过使用依赖注入来确保我们的 grammar 满足开放-闭合原则。
看，尽管我对 Raku 的 regexes 背后的函数式设计表达了热情，但我还是可以承认多范式的力量！但是，我们目前的设计牺牲了一个重要的功能。

然而，我们目前的设计牺牲了一大块我们通常从 action 对象中得到的力量：在 `InnerLang.parse` 调用的 `lisp-like` 方法中放入一个特定的 action 对象，实际上已经硬编码了该对象，至少从 MainLang 调用者的角度看是这样。回到语法检查的情况，`MainLang` 调用者可以传入一个 **CheckMainLangSyntax** action 对象，并获得主语言所需的语法检查行为。但是一旦 grammar 进入内部语言，它就会马上回到使用 `lisp-like` 方法中列出的 **ExecuteInnerLang**（或其他）action 对象。如果不打开 `MainLang` 的源代码，`MainLang` 的调用者就没有办法解决这种情况。让我们来解决这个问题。

好吧，这完全是个谎言：这是 Raku，所以当然有不止一种方法可以做到。他们可以对 MainLang 进行子类化，用一个使用不同 action 对象的等价方法覆盖 *lisp-like*。或者他们可以把 *MainLang.lisp-like* 包裹起来。或者使用元对象协议来干扰 MainLang 的方法。或者可能还有其他一些事情。但是，你知道吗，这不是重点 - 重点是，如果我们的 API 设计得好，用户不应该需要借助这些黑魔法来传递 action 对象。

那么，我们该如何改变我们的 API 呢？最明显的（但仍然不是很好）的选择是通过 *parse* 的 `:args` 参数传递一个 action 对象。下面是它的样子。

```raku
grammar MainLang  {
    rule TOP(:$lisp-like-actions)  {
        [<.text-like> <lisp-like(:$lisp-like-actions)>*]* }

    rule text-like {  [<.alpha>+ ]+ }

    method lisp-like(:lisp-like-actions($actions)) {
        InnerLang.subparse: $.orig, :pos($.to), :$actions
    }
}

MainLang.parse: $input,
            :args(\(:lisp-like-actions(CheckLispSyntax)));
```

我们已经解决了我们的问题，但我仍然不感到兴奋。为什么？有两个问题。首先，我们需要把 action 对象先通过 `TOP`，然后再到 *lisp-like* - 在这里并不是什么大问题，但如果 *lisp-like* 被深度嵌套，很快就会失控。这个问题广为人知，以至于解决它在文档中有[自己的小节](https://docs.raku.org/language/grammars#Dynamic_variables_in_grammars)。那里提出的解决方案是使用动态变量，这将是调用上下文的作用域；这是一个好的解决方案，也是我们要使用的。

> 我们更好的心智模式让我们理解为什么（如[文档中的下一小节](https://docs.raku.org/language/grammars#Attributes_in_grammars)所述）在 grammar 中使用属性不是一个好主意（尽管这将是使一个变量在多个方法中可用的标准方式）。有趣的是，这并不是因为文档中所说的原因 - "*token* 是 Match 的方法，而不是 grammar 本身"。正如我们已经看到的，*token* 是 *grammar* 本身的方法；该 grammar 继承自 `Match`，但 *token* 不是 `Match` 的方法。(Rakudo 在其 `X::Attribute::Regex` 异常中重复了这个不正确的理由）。

相反，对属性 grammar 持怀疑态度的原因是，正如我们所看到的，grammar 不会被就地修改 - 这意味着它们被频繁复制。当一个 grammar 被复制时，其所有的属性都被克隆到新的 grammar 中。然而，动态变量不需要被克隆：新的 grammar 将从当前的动态范围内被调用，因此必然会访问相同的动态变量。

所有这些拷贝使属性在两个方面不适合 grammar：首先，属性经常会产生性能损失，特别是当它们存储大型数据结构时。第二，拷贝会使使用（可变）属性更容易出错 - 特别是对于那些不完全了解 grammar 被拷贝的频率以及这些拷贝被嵌套的（当时很复杂）顺序的用户。例如，如果一个 *token* 修改了一个属性，而另一个 *token* 读取了"相同"的属性，那么第二个 *token* 就有可能得到一个意想不到的不同的值。这种情况可能发生，正如我们新的心智模式所帮助澄清的那样，因为第二个 *token* 实际上不是在读取同一个属性，而是一个不再与原始属性相联系的独立副本。

总而言之，除非我们有非常好的理由喜欢 grammar 属性（我们在这里没有），否则最好避免 grammar 属性。但我确实怀疑目前的例外（和文档）在提供的解释中是否有点不正确或过时。

我们的 MainLang 代码的第二个问题是，我们正在使用 `:args`，而 `:args` 感觉像是用来定制特定 *rule* 的行为的东西。但我们用它来设置一个 action 对象 - 这似乎更适合作为解析时的配置。为了解决这个问题，我们可以覆盖 MainLang 从 Grammar 继承的 `parse` 方法，该方法接受一个额外的参数，用于内部 action 对象。

下面是我们的代码在这两种解决方案中的样子。

```raku
grammar MainLang  {
    method parse(:$lisp-like-actions, |) {
        my $*lisp-like-actions = $lisp-like-actions;
        nextsame
    }

    rule TOP       { [<.text-like> <lisp-like>*]* }
    rule text-like {  [<.alpha>+ ]+ }

    method lisp-like {
        InnerLang.subparse: $.orig, :pos($.to),
                    :actions($*lisp-like-actions)
    }
}
```

注意在解析方法中使用了 `nextsame` - 这使得插入我们的方法并抓取 `$lisp-like-actions` 参数变得微不足道，而不需要重新实现 Grammar 的解析方法或以其他方式打破我们对 Grammar 的依赖性。

事实上，这种调度模式提供了一个很好的例子，说明为什么 Raku 的方法会自动接受 `*%`。前几天我回答了一个 StackOverflow 关于 `*%` 如何有用的问题，我希望我有这段代码可以指出来。因为有了自动的 `*%`，插入我们的包装方法几乎是微不足道的：我们的 API 可以让用户传入新的命名参数，我们可以在我们的方法中处理这些命名参数，然后在我们继续分派过程中把它们传下去。我们这样做的时候，知道我们不会破坏任何不期待这些命名参数的方法 - 那些方法只会吞下我们在 `*%` 中的参数，并继续正常工作。

如果没有 `*%`（以及对所有方法都有 `*%` 的期望），试图实现这种包装而不破坏 MRO 中更多的方法将是一项更多的工作 - 我们必须放弃 `nextsame`，走遍所有的参数，以弄清哪些参数应该传递下去。更糟糕的是，从任何更高级的类的角度来看，摆脱那些"意外"的参数也会让其他类摆脱这些参数 - 包括那些可能想要使用这些参数的类。因此，无论我们做出什么选择，我们都会冒着破坏别人的风险。因此，缺少 `*%` 会使一个微不足道的包装方法变成一个很难做到的方法，而且完全不可能做到 100% 正确。

在这一点上，我对我们的代码非常满意：MainLang 的调用者可以通过 API 为 InnerLang 传递 action，这个 API 与他们用于传递 MainLang action 的 API 非常相似 - 唯一的区别是，命名参数是 `:lisp-lang-actions` 而不是 `:actions`。回想一下语法检查的用例，用户现在可以传入一个检查 Lisp 语法的 action 对象，得到他们想要的主语言和嵌套语言的行为。我们已经完成了我们要做的事情。

但为什么要就此打住呢？

考虑到我们正在处理的用例 - 一种内部编程语言嵌套在一种外部语言中 - 我们似乎很有可能要支持在我们的外部语言中嵌套 Lisp 以外的语言。我们已经增加了很多的灵活性 - 要增加这些灵活性需要什么呢？

事实证明，不需要太多：我们只需调整我们的 API，让调用者传入一个哈希而不是一个 action 对象，然后存储该哈希的内容。我们甚至可以把它设置成 InnerLang 和 InnerLangActions 是默认的 grammar 和 action 对象，假设我们希望这些是最常用的。

还有什么我们应该添加的吗？哦，好吧，我们一直在关注 `parse` 方法，但 grammar 也有 `subparse` 和 `parsefile` 方法。我想我们应该把它们也包起来，以提供一个一致的 API。这样做是很容易的，尽管它确实需要比我更多的复制和粘贴。

有了所有这些变化，这就是我们最终的 MainLang 类，以及一个调用的例子。

```raku
grammar MainLang  {
    method parse(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }
    method subparse(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }
    method parsefile(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }

    rule TOP       { [<text-like> <nested-lang>*]* }
    rule text-like { [<.alpha>+ ]+ }

    method nested-lang {
        %*nested-lang<grammar>
            .subparse: $.orig, :pos($.to),
                       :actions(%*nested-lang<actions>)
    }
}

say MainLang.parse: $input,
                    :nested-lang{ :grammar(OtherLang),
                                  :actions(OtherLangActions)};
```

看看这个，我认为可以说我们的心智模式正在支付租金 - 我们用这个模式大大增强了 `MainLang`，使它同时变得更强大和更灵活。

## 从思维模式到生产模块

我们的 `MainLang` grammar 增加了相当多的功能，而且，至少在我看来，对于调用者来说会更容易使用。但是，这种增加的功能在声明方面是有代价的：我们已经把一个简单的 8 行 grammar 增加到 32 行 - 其中有 15 行基本上是模板，不能帮助读者理解 grammar 的目的。这似乎是一个完美的机会，可以将一些模板抽象为一个模块。

让我们做一个模块，让我们更简洁地写一个像 `MainLang` 这样的语法。具体来说，我们的模块将让一个 grammar 委托给不同的 grammar，该 grammar 知道如何处理这些调用，并允许用户在运行时传入适当的 action 对象。

正如这个框架所暗示的，我们的模块基本上是 Raku 的 handles trait 的 Grammar 版本。如果你以前没有接触过它，handles 可以让你把一个方法调用委托给另一个对象（就像我们要委托给另一个 grammar 一样）。从调用你的代码的人的角度来看，一个委托的方法就像你在你的类中手动定义的方法一样；唯一的区别是，实际的执行是，呃，由你委托的对象处理的 - 同样，这也是我们的 grammar 想要的行为。事实上，由于我们所构建的功能与 handles 的功能如此相似，但对于 grammar 来说，这就是我们的模块的名称: Grammar::Handles。

为了实现我们的功能，Raku 很有帮助地将 handles trait 定义为一个 `multi`，所以我们可以通过给现有的 handles trait 添加一个新的候选者来实现 `Grammar::Handles`。这样做将给我们的用户提供一个与 Raku 其他部分自然匹配的 API，而且就我个人而言，我非常喜欢这样的 API  - 类似于。


```raku
grammar MainLang handles(OtherLang) {...}
```

我们的候选 handles 需要完成以下三个任务。

1. 让用户提供 *token* 名称和每个 *token* 应该委托给的 grammar（例如，在 MainLang 中，嵌套语言 token 应该委托给 OtherLang grammar）。
2. 让用户通过 [sub]? parse [file]? 方法为委托给的 grammar 传递 action 对象。
3. 在用户提供的名称下设置实际的委托/安装 token

如第1点所述，我们将允许用户提供一个与 grammar 名称不同的 *token* 名称。但通常他们很可能想使用相同的名字（例如，一个 LispLang grammar，处理对 LispLang token 的调用）。但是 handles API 已经通过接受 Pairs 进行重命名来满足这两种使用情况；我们也将这样做。

&trait_mod:<handles>

我们决定实现一个对 grammar 进行操作的 handles trait，这有几个连锁反应，我们应该在进入代码之前讨论一下。

首先，与对 Subs 或 Variables 进行操作的 trait（也许更熟悉）不同，我们的第一个参数不是一个有定义值 - 事实上，它甚至不是一个完全初始化的未定义值。它是一个仍在创建中的对象，甚至不知道谁是父母(`.^parents`)。这又意味着它不知道自己是 Grammar，因此我们不能使用类型约束 `&trait_mod` 的签名。幸运的是，Raku 在这里又救了我们，因为 grammar 有自己的元对象，所以我们可以针对它而不是类型进行测试。

第二，因为我们正在声明一个 handle trait，我们将得到一个稍微不寻常的第二个参数：`&thunk`。`&thunk` 是一段尚未执行的代码；我们将需要调用这段代码来访问用户调用 handle 的任何参数。这并不是什么大问题；它只是意味着我们必须稍微努力地工作，以便与调用者可能提供的不同输入相匹配（例如，我们不能根据第二个参数的类型使用多重调度）。

我相当肯定的是，尽管有这个名字，`&thunk` 在技术上并不是 "没有立即执行，但没有独立作用域的代码"意义上的 thunk。例如，下面这一行产生了一个真正的 thunk。

```raku
42 < 2 ?? (my $a = 2) !! 1; say $a # OUTPUT: «(Any)»`
#          ^^^^^^^^^  THUNK!
```

代码 `my $a = 2` 是一个 thunk：它没有被求值（`$a` 不是2），也没有得到它自己的范围（`say $a` 不是一个编译错误）。相反，我非常肯定，handle 的第二个参数确实有自己的作用域 - 所以我们的 `&thunk` 不是。我认为。

但是我们会坚持使用 `&thunk` 这个名字，因为这是其他 handles 候选者使用的名字，而且我不倾向于让迂腐的做法妨碍一个描述性的名字。我只是想分享这些细节，以防你和我一样觉得有趣。

现在我们清楚了为什么我们的签名需要是 `(Mu:U $grammar, &thunk)`，我们准备好了多 `trait_mod:<handles>` 代码 - 它实际上非常短，至少如果你忽略了对尚未定义的辅助函数的调用。(所以在这一点上，也许它更像是一个待办事项清单，而不是一个实际的实现......）。总之，它在这里。

```raku
multi trait_mod:<handles>(Mu:U $grammar, &thunk) {
    import Grammar::Handles::Helpers;
    # Ensure we don't mess w/ non-grammar &handles candidates
    when $grammar.HOW
           .get_default_parent_type !=:= Grammar { nextsame }

                     # vvv The name for our new token
    my Grammar %tokens{Str} = build-token-hash &thunk;
    #  ^^^^^^^ the Grammar the token delegates to

    my %delegee-args;
    #  ^^^^^^^^^^^^^ where [sub]?parse[file]? methods save
    #  args for the delegee Grammar (keyed by token name)
    $grammar.&wrap-parse-methods: :%delegee-args,
                                  :token-names(%tokens.keys);
    $grammar.&install-tokens:     :%tokens, :%delegee-args;
}
```

基于这段代码，我们只需要实现 `&build-token-hash`（将用户提供的 `&thunk` 映射成 `$token-name =>Grammar` 对），`&wrap-parse-methods`（覆盖 Grammar 的 `parse`、`subparse` 和 `parsefile` 方法，其版本将存储每个委托 grammar 的 `:actions` 参数等），以及  `&install-tokens`（安装具有指定 `$token-name` 的方法，委托给正确的 grammar）。让我们按顺序一个一个地看。

## 构建 token 哈希

正如我们刚刚看到的，这个函数得到了 `&thunk` 作为它的单一参数，并且需要返回 `$token-name => Grammar` 对（或者如果 `&thunk` 不是一个我们可以建立这样一个对的值，则引发一个错误）。具体来说，我们需要处理 Grammar、Strs（我们希望它是一个 Grammar 的名字）和 Pairs（我们希望它有一个 Str 键来作为我们的 `$token-name`，以及一个 Grammar 或 Str 的值，它是一个 Grammar 的名字）。

这与其他候选 handles 的 API 略有不同。其他候选者要求任何 Pair 参数的 `Str()` 值等于一个方法名 - 你不能直接传递一个 Method。这对方法来说是有意义的：直接访问它们有点笨拙，而且方法是非常晚的。但是这两点都不适用于 grammar，所以我们的 API 除了允许 Strs 之外，还允许字面 Grammar 值。

处理每一种情况都是相当直接的，这要再次感谢 Raku 的模式匹配。

```raku
#| Transforms the &thunk passed to `handles` into a hash
#| where the keys provide token names to install and the
#| values are the delegee Grammars
sub build-token-hash(&thunk  - > Map()) {
    proto thunk-mapper(|  - > Pair)   {*}
    multi thunk-mapper(Grammar $g)   {
        $g.^name => $g }
    multi thunk-mapper(Pair $renamed (Grammar :$value, |)) {
        $renamed }
    multi thunk-mapper(Str $name) {
        my Grammar $gram = try ::($name);
        $! ?? pick-err($!, :$name) !! $name => $gram }
    multi thunk-mapper(Mu $type) {
        pick-err (try my Grammar $ = $type) // $!}

    thunk().map: &thunk-mapper
}
```

[图中没有：隐藏在 `&pick-err` 后面的额外的 ~25 行错误处理代码。`&pick-err` 所做的就是决定抛出 `Grammar::Handles` 的哪些自定义异常，并将相关参数传递给它。但是，不幸的是，正如我所期望的那样，错误处理最终会比 Raku 中的快乐路径要冗长得多] 。

除了使用 `multis` 来处理我们的各种情况外，这段代码唯一有点奇特的特点是它使用了运行时插值来查找 `my Grammar $gram = try ::($name)` 中的 grammar - 我并不经常需要在源代码中输入类或其他符号来查找，但能有这样的选择也很不错。而且这正是我们在这里需要的，因为它让我们把用户提供的 Str 翻译成我们需要的实际 grammar。

好了，我们现在有了我们的 token 哈希；进入下一个步骤。

&wrap-parse-methods

我们的主要目标之一是为用户提供在调用 `.parse` 和 friends 时指定动作对象的能力。让我们现在就增加这种能力。

我们的基本方法与我们在给 MainLang 添加 parse 方法时的方法相同：检查我们感兴趣的命名参数，以某种方式保存它，然后使用 nextsame 继续调度过程 - 这种强大的模式只有通过 `*%_` 才能实现。唯一真正的区别是，这次我们处理的不是单一的、硬编码的命名参数，而是任何与 `$token-name` 匹配的命名参数。这意味着我们需要把 `.parse` 得到的所有命名参数放入 `%args` 哈希中，然后在该哈希中搜索我们关心的任何命名参数。

另一个区别是，我们接受的参数会更全面一些：在 MainLang 中，我们只关心 `:actions`，但 `.parse` 也接受 `:args` 和 `:rule`（当然，还有 `*%_`）。为了做到这一点，我们只需将所有适当的对传递给 delegee grammar。一旦我们这样做了，我们就用 `nextsame` 来恢复调度，这就像我们的封装方法根本没有被调用一样。

下面是代码。

```raku
#| Overrides the &parse, &subparse, and &parsefile methods with
#| a method that loads %delegee-args with named arguments whose
#| name matches a known $token-name
my method wrap-parse-methods(Mu: :@token-names,
                             :%delegee-args) is export {
    # despite the |, without vv, this sig rejects positionals
    my multi method wrapper ($?, *%args, |)
                             is hidden-from-backtrace {
        for @token-names -> $name {
            next unless %args{$name}:exists;
            if %args{$name}.first({$_ !~~ Map|Pair}, :p) {
                die X::TypeCheck::Binding::Parameter.new:
                        :symbol($name), :expected(Hash()),
                        got => %args{$name} }
            %delegee-args{$name}
              = %args{$name}.Hash;
        }
        nextsame }

    for |<parse subparse parsefile> -> $meth-name {
        self.^add_multi_method: $meth-name, &wrapper }
}
```

而留给我们的只有一个函数需要实现。

&install-tokens

`&install-tokens` 与 `&wrap-parse-methods` 很像，但正好相反。就像在 `&wrap-parse-methods` 中，我们将声明一个新的方法，并将该方法添加到我们的 grammar 中。而且，我们将再次依靠我们的 `%delege-args` 哈希来完成这项工作 - 唯一不同的是，这次我们不是向哈希添加新的条目，而是检查现有的条目以找到正确的参数。当我们在这里时，我们也会给用户在声明他们的 grammar 时定义默认的 `:action`, `:args`, 和 `:rule` values 的选项。这些默认值仍然可以在运行时通过向 `.parse` 传递值来覆盖，但默认值的存在可以使典型的使用情况明显地更符合人体工程学。

```raku
#| Install a method for each known token-name that delegates
#| to the correct Grammar delegee and passes the arguments
#| that the user supplied in their .parse call
my method install-tokens(Mu: :%tokens,
                   :%delegee-args) is export {
    for %tokens.kv -> $name, Grammar $delegee {
        my method TOKEN(:$actions, :$rule='TOP',
                        :$args) is hidden-from-backtrace {
            given %delegee-args{$name} {
                .<actions> = $actions unless .<actions>:exists;
                .<args>    = $args    unless .<args>:exists;
                .<rule>    = $rule    unless .<rule>:exists }
            $delegee.subparse: $.orig, :pos($.to),
                         :from($.from), |%delegee-args{$name}
        }
        self.^add_method: $name, &TOKEN }
}
```

在这一点上，上面的代码并不令人惊讶（或者，至少，我希望不会！）。然而，值得关注的是，这段代码（以及所有 `Grammar::Handles` 的代码，真的）在多大程度上依赖于我们在本帖第一节中开发的正确的心智模式。我们知道当我们调用 `$delegee.subparse` 时，我们可以安装一个 *token* 来做正确的事情，唯一的原因是我们理解了 Raku 在引擎盖下做什么，以及支撑 Raku 的 Regex 和 Grammar 类的奇妙功能设计。

好了，回顾够了 - 我们已经实现了我们所有的功能，所以是时候看看我们的 trait 在行动了

## 比较性演示和结论

为了避免你滚动起来，这里是没有 `Grammar::Handles` 的 MainLang grammar 的定义和使用情况（在屏幕外定义了 OtherLang、OtherLangActions 和 `$input`）。

```raku
grammar MainLang  {
    method parse(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }
    method subparse(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }
    method parsefile(:%nested-lang, |) {
        my %*nested-lang = (:grammar(InnerLang),
                            :actions(InnerLangActions),
                            |%nested-lang);
        nextsame
    }

    rule TOP       { [<text-like> <nested-lang>*]* }
    rule text-like { [<.alpha>+ ]+ }

    method nested-lang {
        %*nested-lang<grammar>
            .subparse: $.orig, :pos($.to),
                       :actions(%*nested-lang<actions>)
    }
}

say MainLang.parse: $input,
                    :nested-lang{ :grammar(OtherLang),
                                  :actions(OtherLangActions)};
```

而这里是 `Grammar::Handles` 的等效定义和用法。

```raku
grammar MainLang handles(:nested-lang(OtherLang))  {
    rule TOP       { [<text-like> <nested-lang>*]* }
    rule text-like { [<.alpha>+ ]+ }
}

say MainLang.parse: $input,
                    :nested-lang{:actions(OtherLangActions)};
```

从 32 行到 4 行 - 大约减少了 87%。我认为这可以说是一次成功的去样板化。而且，更重要的是，我希望那些走到这一步的人至少学到了一些关于 Raku 的东西，而且，也许是带着一个稍微改进的心智模式离开。

`Grammar::Handles` 的完整代码在下面和 gist 中。我还计划在几天内将其作为一个模块发布，一旦我有机会添加一些额外的测试，并纳入围绕这篇文章的讨论中出现的任何建议。我期待着听到你的任何想法/问题 - 特别是，我期待着将 `Grammar::Handles` 中的方法与 guifa 的 Token::Foreign 中的方法进行比较，后者从不同的角度（呃，或者说是三个不同的角度）来解决同一个问题。


```raku
# Grammar::Handles
my module Grammar::Handles::Helpers {

class X::Grammar::Can'tHandle is Exception {
    # extra ' to fix my blog’s syntax highlighter (aka hlfix)
    has $.type is required;
    multi method CALL-ME(|c) { die self.new(|c)}
    method message { q:to/§err/.trim.indent(2);
      The `handles` grammar trait expects a Grammar, the name
      of a Grammar, a Pair with a Grammar value, or a list of
      any of those types.  But `handles` was called with:
          \qq[{$!type.raku} of type ({$!type.WHAT.raku})]
      §err
}}

class X::Grammar::NotFound is Exception {
    has $.name;
    multi method CALL-ME(|c) { die self.new(|c)}
    method message { qq:to/§err/.trim.indent(2);
      The `handles` grammar trait tried to handle a grammar
      named '$!name' but couldn't find a grammar by that name
      §err
}}

#| A helper select the right error more concisely on the happy path
sub pick-err($_, :$name, |c) {
    when X::TypeCheck::Assignment { X::Grammar::Can'tHandle(:type(.got))  } # hlfix '
    when X::NoSuchSymbol          { X::Grammar::NotFound(:$name) }}

#| Install a method for each known token-name that delegates
#| to the correct Grammar delegee and passes the arguments
#| that the user supplied in their .parse call
my method install-tokens(Mu: :%tokens,
                   :%delegee-args) is export {
    for %tokens.kv -> $name, Grammar $delegee {
        my method TOKEN(:$actions, :$rule='TOP',
                        :$args) is hidden-from-backtrace {
            given %delegee-args{$name} {
                .<actions> = $actions unless .<actions>:exists;
                .<args>    = $args    unless .<args>:exists;
                .<rule>    = $rule    unless .<rule>:exists }
            $delegee.subparse: $.orig, :pos($.to),
                         :from($.from), |%delegee-args{$name}
        }
        self.^add_method: $name, &TOKEN }
}

#| Transforms the &thunk passed to `handles` into a hash
#| where the keys provide token names to install and the
#| values are the delegee Grammars
sub build-token-hash(&thunk  - > Map()) is export {
    proto thunk-mapper(|  - > Pair)   {*}
    multi thunk-mapper(Grammar $g)   { $g.^name => $g }
    multi thunk-mapper(Str $name) {
        my Grammar $gram = try ::($name);
        $! ?? pick-err($!, :$name)
           !! $name => $gram }
    multi thunk-mapper(Pair (:key($name), :value($_), |)) {
        when Grammar { $name => $_ }
        when Str     { $name => thunk-mapper($_).value }
        default      { #`[type err] thunk-mapper $_ }}
    multi thunk-mapper(Mu $invalid-type) {
        pick-err (try my Grammar $ = $invalid-type) // $! }

    thunk().map: &thunk-mapper
}

#| Overrides the &parse, &subparse, and &parsefile methods with
#| a method that loads %delegee-args with named arguments whose
#| name matches a known $token-name
my method wrap-parse-methods(Mu: :@token-names,
                             :%delegee-args) is export {
    # despite the |, without vv, this sig rejects positionals
    my multi method wrapper ($?, *%args, |)
                             is hidden-from-backtrace {
        for @token-names -> $name {
            next unless %args{$name}:exists;
            if %args{$name}.first({$_ !~~ Map|Pair}, :p) {
                die X::TypeCheck::Binding::Parameter.new:
                        :symbol($name), :expected(Hash()),
                        got => %args{$name} }
            %delegee-args{$name}
              = %args{$name}.Hash;
        }
        nextsame }

    for |<parse subparse parsefile> -> $meth-name {
        self.^add_multi_method: $meth-name, &wrapper 
    }
}

#`[end module Grammar::Handles::Helpers] }

multi trait_mod:<handles>(Mu:U $grammar, &thunk) {
    import Grammar::Handles::Helpers;
    # Ensure we don't mess w/ non-grammar &handles candidates
    when $grammar.HOW
           .get_default_parent_type !=:= Grammar { nextsame }

                     # vvv The name for our new token
    my Grammar %tokens{Str} = build-token-hash &thunk;
    #  ^^^^^^^ the Grammar the token delegates to

    my %delegee-args;
    #  ^^^^^^^^^^^^^ where [sub]?parse[file]? methods save
    #  args for the delegee Grammar (keyed by token name)
    $grammar.&wrap-parse-methods: :%delegee-args,
                                  :token-names(%tokens.keys);
    $grammar.&install-tokens:     :%tokens, :%delegee-args;
}
```