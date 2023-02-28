原文链接: https://raku-advent.blog/2022/12/15/day-15-junction-transformers/

考虑到一个数字的 Junction:

```raku
say any 0..9; # OUTPUT: any(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
```

它将 `any` 作为操作类型，将 `0..9` 作为内部特征状态的列表。在智能匹配上下文中，它可以匹配任何可以对其任何数字特征状态进行智能匹配的对象。虽然这些列表没有公开，但有一种方法可以遍历其内容。

`~~` 智能操作符在对其结果进行 Bool 强制处理之前委托给 RHS 上的 ACCEPTS 方法。例如，我们将直接依赖 `Code.ACCEPTS` 作为向智能匹配注入行为的手段。

```raku
sub sum(Mu $topic is raw) {
    my $sum is default(0);
    sub sum($topic) { cas $sum, * + $topic }
    &sum.ACCEPTS: $topic;
    $sum
}

say sum any 0..9; # OUTPUT:
# 45

say sum 0 & (9 ^ 9) & 0; # OUTPUT:
# 18
```

在这种情况下，它将一个参数（它的"主题"）转发给它自己的调用，使我们能够得到一个特征状态的总和。

我们给 `&sum` 一个闭包，为每次调用提供新的 `$sum`。因为内部 `&sum` 的 `$topic` 没有类型，它像外部的 `$topic` 一样携带一个 `Mu` 类型，但会在任何特征状态上自动读取一个 `Junction:D` 参数。因为外层的 `$topic` 是明确的 `Mu` 类型，并且是原始的，但是它将单独离开输入的 Junction 和容器。请注意，自动线程会在 `Junction:D` 的特征状态上递归，虽然我们可以使用+=，但Junction的实现可能是并行的。

如果我们打算只接受一个给定 Junction 的参数，它也可以是一个 Mu 特征态而不是结点本身。Mu.ACCEPTS 可以在 Mu 而不是 Any 上穿行它的主题，给定一个 `Mu:U` 调用者（`Mu:D` 是 NYI； `Any:D` 默认为 `&[===]`）。类似地，`Junction.CALL-ME` 将其调用者穿透 `Mu`。因为 Junction 不会因为它的线程而短路，这些 Junction 可以被链起来，以递归地遍历它的的特征状态。

```raku
class JMap does Callable {
    has &!transform is built(:bind);

    multi method ACCEPTS(::?CLASS:U: Mu $topic is raw) {
        self.bless: transform => {
            &^function($topic)
        }
    }
    multi method ACCEPTS(::?CLASS:D: Mu $topic is raw) {
        &!transform.ACCEPTS: -> Mu $thread is raw {
            $thread.ACCEPTS: $topic
        }
    }

    proto method CALL-ME(Mu) {*}
    multi method CALL-ME(::?CLASS:U: Mu $topic is raw) {
        self.ACCEPTS: $topic
    }
    multi method CALL-ME(::?CLASS:D: &function) is raw {
        &!transform(&function)
    }
}

say JMap(any 0..9)(*[]); # OUTPUT:
# any(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

say JMap(any 0..9)(2 ** *); # OUTPUT:
# any(1, 2, 4, 8, 16, 32, 64, 128, 256, 512)

say JMap(0 & (9 ^ 9) & 0)(?*); # OUTPUT:
# all(False, one(True, True), False)
```

JMap 有一次机会将一个 `Junction:D` 作为一个类型对象，所以我们在它的 Callable 之前将 Junction 转发给 map。在 `CALL-ME` 之后，我们最终得到的要么是一个可调用的，要么是一个新的可调用的结点，该结点是可调用的，但本身并不符合可调用的条件。尽管 ACCEPTS 是用 Mu topic 打出的，而不是 JMap，但 Junction 的线程仍然在调度中获胜。

JMap 可以通用地处理 Junction 的特征状态，但在任何针对结果的智能匹配之前，它在 `CALL-ME` 中的自动线程中带有开销。如果你心中有一个特定的 Callable 来映射，可以遵循这个 JTransformer 模板。

```raku
class JTransformer does Callable is repr<Uninstantiable> {
    multi method ACCEPTS(Mu --> Code:D) { ... }

    method CALL-ME(Mu $topic is raw) {
        self.ACCEPTS: $topic
    }
}
```

一般来说，`CALL-ME` 将被用来将其 `Mu $topic` 通过 `ACCEPTS` 进行线程化。而不是将调用者实例化，这将返回一个裸块或匿名 sub，它将执行一个定制的智能匹配操作，给定其上下文中的线程 `Mu` 和来自所述代码对象上任何后来的智能匹配的主题。

如果由 `CALL-ME` 产生的 Junction 被缓存了，所写的 `ACCEPTS` 候选者可以承担其结果 thunk 的部分工作，使之更便宜地进行智能匹配，例如通过预处理到特定块的路径。在这个意义上，可以通过直接对 `Mu` 进行子类型化而不是默认的 `Any` 来进一步降低调度的成本，尽管这样做会变得更加难以操作。

```raku
class JTransformer is Mu does Callable is repr<Uninstantiable> { ... }
```

一个类似于 JTransformer 的实际例子是内部的 `Refine` 类，它从 v1.0.3 开始支持我的 Kind subsets 的细化（where 从句）。因为它涉足了元对象（例如 `Mu`、`Junction`），所以 `Any` 不能被假设，但同时，Junction 可以允许对多个元对象进行复杂的检查。如果一个由它的 ACCEPTS 调用线程的元对象由于任何原因不能作为 `Mu` 进行类型检查，它将用一个包着低级类型检查的块来替代它，否则将对 ACCEPTS 调用进行 bool 化。