# 带有角色和内省的通用数据结构遍历

我是一个 [lambdacamel](https://andrewshitov.com/2015/05/05/interview-with-audrey-tang/)，因此我喜欢把函数式编程的概念和技术，特别是 [Haskell](https://www.haskell.org/) 语言的概念和技术，改编成 Raku。我经常使用的技术之一是泛型遍历，也被称为 "Scrap Your Boilerplate"，这是 [Simon Peyton Jones 和 Ralf Lämmel 介绍这种方法的论文标题](https://archive.alvb.in/msc/02_infogp/papers/SYB1.pdf)。用他们的话说:

> 许多程序遍历由丰富的相互递归数据类型构建的数据结构。这样的程序往往有大量的"模板"代码，只是简单地遍历结构，隐藏了少量构成遍历原因的 "真正"代码。"通用编程"是描述针对这一问题的各种编程技术的总称。

因此，为了使你不必编写自己的自定义遍历，这种方法为你提供了在任意数据结构上进行遍历的通用函数。在这篇文章中，我将解释你如何在 Raku 中为任意的基于角色的数据结构轻松实现这种泛型。这篇文章中没有 Haskell。

作为数据类型的角色实例

我实现了这些用于基于角色的数据类型的泛型。Raku 的[参数化角色](https://docs.raku.org/language/objects#index-entry-Parameterized_Roles)使得创建复杂的数据结构非常容易。我纯粹把角色作为数据类型使用，所以它们没有相关的方法。

例如，这里有一个我在研究中使用的小语言的例子代码片段。

```raku
map (f1 . f2) (map g (zipt (v1,map h v2)))
```

基元是 `map`、`.` (函数组合)、Zipt 和元组(...)，以及函数和 vectord 的名称。这个小语言的抽象语法的数据类型被称为 Expr，看起来如下:

```raku
# Any expression in the language
role Expr {}
# map f v
role MapV[Expr \f_,Expr \v_] does Expr {
    has Expr $.f = f_;
    has Expr $.v = v_;
}
# function composition f . g
role Comp[Expr \f_, Expr \g_] does Expr {
    has Expr $.f = f_;
    has Expr $.g = g_;
}
# zipt t turns a tuple of vectors into a vector of tuples
role ZipT[Expr \t_] does Expr {
    has Expr $.t = t_
}
# tuples are just arrays of Expr
role Tuple[Array[Expr] \e_] does Expr {
    has Array[Expr] $.e = e_
}
# names of functions and vectors are just string constants
role Name[Str \n_] does Expr {
    has Str $.n = n_
}
```

`Expr` 角色是顶层数据类型。它是空的，因为它完全是通过其他角色来实现的，由于这些角色都是 `Expr` 类型的。而且大多数角色的属性也是 `Expr` 类型的。所以我们有一个递归数据类型，一个以 `Name` 节点为叶子的树。

我们现在可以使用这个 `Expr` 数据类型来编写示例代码的抽象语法树（AST）。

```raku
my \ast = MapV[ 
    Comp[
        Name['f1'].new,
        Name['f2'].new
    ].new,
    MapV[
        Name['g'].new,
        ZipT[
            Tuple[
                Array[Expr].new(
                    Name['v1'].new,
                    MapV[
                        Name['h'].new,
                        Name['v2'].new
                    ].new
                )
            ].new
        ].new
    ].new
].new;
```

使用这种数据结构的典型方法是使用 `given/when`。

```raku
sub worker(Expr \expr) {
    given expr {
        when MapV {...}
        when Comp {...}
        when ZipT {...}
        ...        
    }
}
```

或者，你可以使用 `multi sub`:

```raku
multi sub worker(Mapv \expr) {...}
multi sub worker(Comp \expr) {...}
multi sub worker(ZipT \expr) {...}
...
```    

在这两种情况下，我们使用角色作为类型来匹配我们想要采取的行动。

(关于代数数据类型的更多细节，请参见我之前的文章《Raku 中作为代数数据类型的角色》）。

泛型

如果我想遍历上面的 AST，我通常会像上面那样写一个 worker 子程序，对于除叶子节点以外的每个节点，我都会递归地调用 worker，比如说:

```raku
sub worker(Expr \expr) {
    given expr {
        when MapV {
            my \f_ = worker(expr.f);
            my \v_ = worker(expr.v);
            ...
        }
        ...        
    }
}
```

但是，如果我根本就不用写这些代码，那不是很好吗？进入泛型。

我的命名和函数参数是基于 Haskell 库 Data.Generics 的。它为遍历提供了许多方案，但最重要的是 `everything` 和 `everywhere`。

> everything 是一个函数，它接收一个数据结构、一个匹配函数、一个累积器和一个累积器更新函数。匹配函数定义了你要在数据结构中寻找的东西。使用更新函数将结果放入累加器。

```raku
sub everything( Any \datastructure, Any \accumulator, &joiner, &matcher --> Any){...}
```

> everywhere 是一个函数，它接收一个数据结构和一个修改器函数。修改函数定义了你要修改的数据结构的哪些部分。遍历的结果是数据结构的一个修改版本。

```raku
sub everywhere( Any \datastructure, &modifier --> Any){...}。
```

累加器最常见的情况是使用一个列表，所以更新的函数将列表追加到累加器中。

```raku
sub append(\acc, \res) {
    return (|acc, |res);
}
```

作为一个匹配函数的例子，让我们举例在上面的 AST 中找到所有的函数和向量名称。

```raku
sub matcher(\expr) {
    given expr {
        when Name {
            return [expr.n]
        } 
    }
    return []
}
```

因此，如果我们找到一个 `Name` 节点，我们就把它的 n 属性作为一个单元素的列表返回；否则我们就返回一个空列表。

```raku
my \names = everything(ast,[],&append,&matcher); 
# => returns (f1 f2 g h v1 v2)
```

或者说我们想改变这个 AST 中的名字。

```raku
sub modifier(\t) {
    given t {
        when Name {
            Name[t.n~'_updated'].new 
        }
        default {t}
    }
}

my \ast_ = everywhere(ast,&modifier); 
# => returns the AST with all names appended with "_updated"
```

实现泛型

那么，我们如何实现这些神奇的一切和所有地方的函数呢？要解决的问题是，我们要遍历每个角色的属性，而不需要为其命名。这方面的解决方案是使用 Raku 的 Metaobject 协议（MOP）进行自省。在实践中，我们使用 Rakudo 特有的 Metamodel。我们只需要三个方法：`attribute`、`get_value` 和 `set_value`。通过这些，我们可以遍历属性并递归访问它们。

属性可以是 `$`、`@` 或 `%`（甚至还有 `&`，但我将跳过这一点）。就 Raku 的类型系统而言，这意味着它们可以是标量、Iterable 或 Associative，而我们需要区分这些情况。有了这个，我们就可以把所有的东西都写成下面这样:

```raku
sub everything (\t, \acc,&update,&match) {
    # Arguments a immutable, so copy to $acc_
    my $acc_ = acc;
    # Match and update $acc_
    $acc_ =update($acc_,match(t));
    # Test the attribute type
    if t ~~ Associative {
        # Iterate over the values
        for t.values -> \t_elt  {
            $acc_ = everything(t_elt,$acc_,&update,&match)
        }
        return $acc_; 
    }     
    elsif t ~~ Iterable {
        # Iterate
        for |t -> \t_elt  {
            $acc_ = everything(t_elt,$acc_,&update,&match)
        }
        return $acc_; 
    }

    else { 
        # Go through all attributes
        for t.^attributes -> \attr {
            # Not everyting return by ^attributes 
            # is of type Attribute
            if attr ~~ Attribute {
                # Get the attribute value
                my \expr = attr.get_value(t);
                if not expr ~~ Any  { # for ContainerDescriptor::Untyped
                    return $acc_;
                }
                # Descend into this expression
                $acc_ = everything(expr,$acc_,&update, &match);
            }
        }
    }
    return $acc_
}
```

因此，我们在这里所做的基本上是:

- 对于 `@` 和 `%` 我们迭代值
- 使用 `^attributes` 迭代属性
- 对于每个属性, 使用 `get_value` 获取表达式
- 在那个表达式上调用 `everything`
- `everything` 做的第一件事情是更新累积器

到处都是类似的情况:

```raku
sub everywhere (\t_,&modifier) {
    # Modify the node
    my \t = modifier(t_);
    # Test the type for Iterable or Associative
    if t ~~ Associative {
        # Build the updated map
        my %t_;
        for t.keys -> \t_k  {
            my \t_v = t{t_k};
            %t_{t_k} = everywhere (t_v,&modifier);
        }
        return %t_; 
    }     
    elsif t ~~ Iterable {
        # Build the updated list
        my @t_=[];
        for |t -> \t_elt  {
            @t_.push( everywhere(t_elt,&modifier) );
        }
        return @t_; 
    }

    else {
        # t is immutable so copyto $t_
        my $t_ = t;
        for t.^attributes -> \attr {            
            if attr ~~ Attribute {
                my \expr = attr.get_value(t);
                if not expr ~~ Any  { # for ContainerDescriptor::Untyped
                    return $t_;
                }
                my \expr_ = everywhere(expr,&modifier);                
                attr.set_value($t_,expr_);
            }
        }
        return $t_;
    }
    return t;
}
```

因此，我们在这里所做的基本上是:

- 对于 `@` 和 `%` 我们迭代值
- 使用 `^attributes` 迭代属性
- 对于每个属性, 使用 `get_value` 获取表达式
- 在那个表达式上调用 `everything`
- 使用 `set_value` 更新属性

这在没有角色的情况下也适用

首先，上面的方法也适用于类，因为 `Metamodel` 方法不是专门针对角色的。此外，由于我们对 `@` 和 `%` 进行了测试，上面的泛型对没有角色的数据结构（由哈希和数组构建）也能正常工作:

```raku
my \lst = [1,[2,3,4,[5,6,7]],[8,9,[10,11,[12]]]];

sub matcher (\expr) {
    given expr {
        when List {
            if expr[0] % 2 == 0 {                
                    return [expr]                
            }            
        }
    }
    return []
}

my \res = everything(lst,[],&append,matcher);
say res;
# ([2 3 4 [5 6 7]] [8 9 [10 11 [12]]] [10 11 [12]] [12])
```

或用于哈希值:

```raku
my %hsh = 
    a => {
        b => {
            c => 1,
            a => {
                b =>1,c=>2
            } 
        },
        c => {
            a =>3
        }
    },
    b => 4,
    c => {d=>5,e=>6}
;

sub hmatcher (\expr) {
    given (expr) {
        when Map {
            my $acc=[];
            for expr.keys -> \k {                
                if k eq 'a' {
                    $acc.push(expr{k})
                }
            }
            return $acc;
        }
    }
    return []
}

my \hres = everything(%hsh,[],&append,&hmatcher);
say hres;
# ({b => {a => {b => 1, c => 2}, c => 1}, c => {a => 3}} {b => 1, c => 2} 3)
```

结论

通用数据结构遍历是减少模板代码和专注于遍历的实际目的的一个好方法。现在你也可以在 Raku 中拥有它们。我已经展示了两个主要方案的实现，即 everything 和 everywhere，并表明它们适用于基于角色的数据结构，以及传统的基于哈希或数组的数据结构。

原文链接: https://wimvanderbauwhede.github.io/articles/generic-traversals-in-raku/