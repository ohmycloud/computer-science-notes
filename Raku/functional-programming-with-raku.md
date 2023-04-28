# Functional Programming with Raku

Raku 是一种很棒的函数式编程语言, 它支持匿名函数（块）、通过 `assuming` 进行部分应用等等。

在这篇文章中, 我希望概述我如何将 Raku 用作函数式（面向对象）编程语言, 类似于我编写 Scala 等语言的方式。

## 组合运算符

在 Raku 中, `o` 是一个运算符（一个二元函数）。这意味着我们可以将两个函数组合在一起以创建一个新函数。这让我们可以在我们的函数上构建非常酷的抽象。例如, 我们可以使用它来创建具有隐藏副作用的函数：

```raku
my $logger = -> $m { say $m; $m };
my $add-five = -> $x { $x + 5 };
my $add-five-and-log = $add-five o $logger;

say $add-five-and-log(25); # Prints 25, then prints 30
```

请注意, 组合以某种方式向后发生, `$add-five o $logger` 等同于 `-> x { $add-five($logger(x)) }`。很整洁吧！

这也使我们能够简单地将函数数组简化为单个函数, 在 Humming-Bird 源代码中, 你可以在实践中看到路由结束 hook 的“建议”:

```raku
method !add-route(Route:D $route, HTTPMethod:D $method --> Route:D) {
        my &advice = [o] @!advice;
        my &cb = $route.callback;
        my $r = $route.clone(path => $!root ~ $route.path,
                             middlewares => [|@!middlewares, |$route.middlewares],
                             callback => { &advice(&cb($^a, $^b)) });
        @!routes.push: $r;
        delegate-route($r, $method);
    }
```

Router 类上的这个方法将路由对象添加到应用程序的上下文中, 你会注意到该方法的第一行, 我们在缩减中应用 `o` 以从建议数组生成单个函数。 `@!advice` 是此路由器上的所有建议。通知只是接受响应并返回响应的函数。所以你可以想象组合运算符是如何将它们分层的：

```raku
-> x { advice-four(advice-three(advice-two(advice-one(x)))) }
```

然后, 要调用建议, 我们所要做的就是将响应传递给组合, 其余的将由它处理。

## Assuming

Assuming 是从 `Code` 类派生的方法, 它允许我们对函数执行部分应用。Partial application 非常简单, 它意味着调用一个参数少于它需要的函数, 它反过来返回一个包含你已经提供的参数的新函数。例如, 如果我们有一个接受两个数字的 `add` 函数, 我们可以像这样部分应用它：

```raku
my $add = -> $x, $y { $x + $y };

my $add-five = $add.assuming(5);

say $add-five(10); # prints 15
say $add-five(5);  # prints 10
```

在 `add` 函数上调用 `.assuming(5)` 的结果是一个新函数, 如下所示：`-> $y { 5 + $y }`。

这是一个非常巧妙的功能, 它让我们可以创建我喜欢称之为“无状态状态”的东西, 这意味着我们可以将状态添加到我们的函数中, 而无需实际将其暴露给函数的消费者。

在野外使用 `.assuming` 的一个相当复杂但优雅的例子是 Humming-Birds 中间件系统：

```raku
my &composition = @!middlewares.map({ .assuming($req, $res) }).reduce(-> &a, &b { &a({ &b }) });
&composition(&!callback.assuming($req, $res))
```

我们必须映射所有中间件以部分应用将在整个请求链中使用的请求和响应对象, 然后减少为将采用另一个函数的单个函数。最后, 使用用户提供的回调调用组合。这就是允许中间件具有 `$request`、`$response` 和 `&next` 参数的原因。调用 `&next()` 只是调用链中下一个部分应用的函数！

## 匿名函数（块）

Raku 是我所知道的仅有的一种语言有不止一种方法来声明匿名函数（又名 lambda）。在 Raku 中, 我们有尖号块（我最喜欢的）、普通块、[WhateverCodes](https://docs.raku.org/type/WhateverCode.html) 和匿名子例程。

通常, 根据我的经验, 对于大多数事情, 使用普通块就可以了, 除非你想严格定义参数, 否则最好使用尖号块或匿名子例程。如果你需要显式返回即短路, 你可能需要使用匿名 sub, 否则使用尖号块就可以了。

这是使用每种类型的块编写的相同函数 `add`:

### 普通块

```raku
my &add = { $^a + $^b };
```

### Whatever Code

```raku
my &add = * + *;
```

### Pointy block

```raku
my &add = -> $a, $b { $a + $b };
```

### Anonymous sub

```raku
my &add = sub ($a, $b) { $a + $b };
```

你可以使用 `&` sigil 以更 “Raku-ish” 的方式声明存储在变量中的函数, 这将告诉其他开发人员该变量是一个 `Callable`。

你可以将这些匿名函数传递给其他函数, 这在反应式编程领域中得到了相当广泛的使用。`whenever` 使用匿名函数（块或尖号块）注册回调时：

```raku
react {
    whenever Supply.interval(1) -> $second {
        say 'Current second: $second';
    }
}
```

例如, 在 Raku 的标准库中, `for` 循环将块或尖号块作为参数, 你以前可能从未这样想过吧？

```raku
for [1,2,3,4] -> $x { say $x }; # That block can be thought of as a lambda!
```

在 Humming-Bird 中, 当你声明如下例程时：

```raku
get('/', -> $request, $response {
    $response.write('Hello World!');
});
```

在后台, 该块由 `get` 函数接收, 然后注册为路由器收到请求时要调用的内容。

总的来说, Raku 有一些非常有趣和可用的功能模式。我个人是部分应用程序和组合运算符的忠实拥护者。这真的很有趣！

最后我想留下一个有趣的例子, 看看你是否可以预测结果：

```raku
([o] [-> $a { $a + 1 }, -> $a { $a + 1 }])(2).say
```

当心! Raku rocks!

## 原文链接

https://dev.to/rawleyfowler/functional-programming-with-raku-9ib
