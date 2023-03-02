Day 6: Immutable data structures and reduction in Raku

对于我一直在写的一个[小型编译器](https://wimvanderbauwhede.github.io/articles/uxntal-to-C/)，我越来越觉得需要不可变的数据结构，以确保没有任何东西在传递过程中被引用。我喜欢 Perl 和 Raku，但我骨子里是个函数式程序员，所以我更喜欢 `map` 和 `reduce` 而不是循环。在一个可变的数据结构上应用 `reduce`，这让我很困扰。所以我做了一个[小的库](https://codeberg.org/wimvanderbauwhede/nito/src/branch/main/lib/ImmutableDatastructureHelpers.rakumod)，使其更容易处理不可变的 map 和列表。

`reduce` 将一个列表的所有元素合并成一个结果。一个典型的例子是一个列表中所有元素的总和。根据 Raku 的文档，reduce() 有如下签名

```raku
multi sub reduce (&with, +list)
```

一般来说，如果我们有一个类型为 T1 的元素列表和一个类型为 T2 的结果，Raku 的 reduce() 函数的第一个参数是一个函数，形式为:

```raku
-> T2 \acc, T1 \elt --> T2 { ... }
```

我使用 `reduce` 的形式，它需要三个参数：`reduce` 函数、累加器（Raku 文档中称为初始值）和列表。正如文档中所解释的，Raku 的 `reduce` 从左到右操作。(用 Haskell 的说法，它是一个 **foldl :: (b -> a -> b) -> b -> [a]**) 。

这个用例是对一个基于角色的数据结构 ParsedProgram 的遍历，它包含一个 map 和一个有序的键列表。map 本身包含 ParsedCodeBlock 类型的元素，本质上是一个标记的列表。

```raku
role ParsedProgram {
    has Map $.blocks = Map.new; # {String => ParsedCodeBlock}
    has List $.blocks-sequence = List.new; # [String]
    ...
}

role ParsedCodeBlock {
    has List $.code = List.new; # [Token]
    ...
}
```

`List` 和 `Map` 是不可变的，所以我们有不可变的数据结构。我想做的是使用一个嵌套的 `reduce` 来更新这些数据结构，在这里我遍历块序列 List 中的所有键，然后修改相应的 ParsedCodeBlock。为此，我写了一个小的 API，在下面的代码中，`append` 和 `insert` 是该 API 的一部分。他们所做的是创建一个新的 List resp. Map，而不是在原地更新。

我更喜欢对不可变的数据使用无符号的变量，所以我代码中的符号显示我在哪里使用了可变的变量。

下面的代码是一个典型的遍历例子。我们遍历一个程序中的代码块列表，parsed_program.blocks-sequence；在每次遍历中，我们都会更新程序 parsed_program（累加器）。 `reduce()` 调用了一个带有累加器（ppr_）和一个列表元素（code_block_label）的 lambda 函数。

我们从程序的块图中获得代码块，并再次使用 `reduce()` 来更新代码块中的标记。因此，我们遍历原始的标记列表（parsed_block.code）并建立一个新的列表。因此，lambda 函数的累加器是更新的列表（mod_block_code_），元素是一个标记（token_）。

内层 Reduce 创建一个修改过的 token 并使用 append 将其放入更新的列表中。然后，外部还原使用 clone 来更新代码块，并使用 insert 来更新程序中的代码块 map，如果该条目存在，则更新该条目。最后，我们使用 clone 来更新程序。

```raku
reduce(
    -> ParsedProgram \ppr_, String \code_block_label {
        my ParsedCodeBlock \parsed_block =
            ppr_.blocks{code_block_label};

        my List \mod_block_code = reduce(
            -> \mod_block_code_,\token_ {
                my Token \mod_token_ = ...;
                append(mode_block_code_,mod_token_);
            },
            List.new,
            |parsed_block.code
        );
        my ParsedCodeBlock \mod_block_ =
            parsed_block.clone(code=>mode_block_code);
        my Map \blocks_ = insert(
            ppr_glob.blocks,code_block_label,mod_block_);
        ppr_.clone(blocks=>blocks_);
    },
    parsed_program,
    |parsed_program.blocks-sequence
);
```   


整个库只有少数几个函数。这些函数的命名是基于 Haskell 的，除了 Raku 已经将一个名字作为关键字的地方。

map 操作

在 Map 中插入、更新和删除条目。给定一个现有的键，插入将更新该条目。


    sub insert(Map \m_, Str \k_, \v_ --> Map )
    sub update(Map \m_, Str \k_, \v_ --> Map )
    sub remove(Map \m_, Str \k_ --> Map )
    

列表操作

有更多的列表操作函数，因为减法对列表进行操作。

在前面添加/删除一个元素。

```
    # push
    sub append(List \l_, \e_ --> List)
    # unshift
    sub prepend(List \l_, \e_ --> List)
```

将一个列表分割成它的第一个元素和其他元素。

```raku
# return the first element, like shift
sub head(List \l_ --> Any)
# drops the first element
sub tail(List \l_ --> List)

# This is like head:tail in Haskell
sub headTail(List \l_ --> List) # List is a tuple (head, tail)
```

headTail 的典型用法是这样的:

```raku
my (Str \leaf, List \leaves_) = headTail(leaves);
```

类似的操作，但针对最后一个元素。

```raku
# drop the last element
sub init(List \l_ --> List)
# return the last element, like pop.
sub top(List \l_ --> Any) ,
# Split the list on the last element
sub initLast(List \l_ --> List) # List is a tuple (init, top)
```

initLast 的典型用法是这样的。

```raku
my (List \leaves_, Str \leaf) = initTail(leaves);
```