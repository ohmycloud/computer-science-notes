# Raku 中作为代数数据类型的角色

我一直是一个 [lambdacamel](https://andrewshitov.com/2015/05/05/interview-with-audrey-tang/)，很长时间以来, 我都喜欢 [Perl](https://www.perl.org/) 和函数式编程，特别是 [Haskell](https://www.haskell.org/)。我仍然用这两种语言中的任何一种写我的大部分代码。

早在 [Raku](https://raku.org/) 被称为 Raku 之前，我就已经是它的粉丝了，但我在现实生活中从未使用过它。最近，我越来越倾向于使用 Raku 来编写我不需要与其他人分享的代码。它是一种可爱的语言，而且它的功能遗产非常强大。因此，对我来说，探索 Raku 类型系统的极限是很自然的。

## 这篇文章适合你吗？

在这篇文章中，我将介绍[代数数据类型](https://www.cs.kent.ac.uk/people/staff/dat/miranda/nancypaper.pdf)，这是一种在 Haskell 等函数式语言中使用的静态类型系统，也是一种创建复杂数据结构的强大机制。我将展示一种使用角色(role)在 Raku 中实现代数数据类型的方法。你根本不需要知道 Haskell，我只假设你知道一点 Raku（我已经添加了[一个快速介绍](https://wimvanderbauwhede.github.io/articles/roles-as-adts-in-raku/#raku-intro)），但我确实假设你有一些编程基础。如果你对函数式静态类型感到好奇，或者你希望有一种替代面向对象编程的方法，你可能会发现这篇文章很有趣。

## 代数数据类型

数据类型（简称类型）只是程序中数值的标签或容器。代数数据类型是复合类型，它们是由其他类型组合而成的。它们被称为代数型，因为它们由类型的替代物(alternatives)（sums，也称为不相交的集合）和记录（积）组成。更多细节见 [[1]](https://codewords.recurse.com/issues/three/algebra-and-calculus-of-algebraic-data-types) 或 [[2]](https://gist.github.com/gregberns/5e9da0c95a9a8d2b6338afe69310b945)。

为了给"和类型"(sum type)和"积类型"(product type)这两个术语提供一个粗略的直觉：在 Raku 中，对于布尔值 `$a`、`$b` 和 `$c`，你可以写出 `$a or $b or $c`，但你也可以写出 `$a+$b+$c` 并将其评估为 `True` 或 `False`。同样，`$a and $b and $c` 也可以写成 `$a * $b * $c`。换句话说，`and` 和 `or` 的行为与 `+` 和 `*` 是一样的。在一般情况下，代数数据类型系统中的类型可以用类似的规则组成。

### 几个例子

首先让我们举几个代数数据类型的例子。在本节中，我没有使用特定的编程语言语法。相反，我使用一个极简的标记法来说明这些概念。我使用 `datatype` 关键字来表示下面是代数数据类型的声明；对于和类型(sum type)，我会用 `|` 来分隔可供选择的值；对于积类型(product type)，我会用空格来分隔各部分。为了声明一个变量属于某种类型，我将在它前面写上类型名称。

我们可以将一个布尔值纯粹定义为一个类型:

    datatype Bool =  True | False

而我们可以将此用作:

    Bool ok = True

这意味着 `ok` 是一个 `Bool` 类型的变量，其值为 `True`。在代数数据类型中，标签被称为"构造函数"。所以 `True` 是一个不接收参数的构造函数。

对于积类型(product type)，例如，我们可以为 RGB 颜色三联体创建一个类型:

    datatype RGBColour = RGB Int Int Int

右侧的 `RGB` 标签是该类型的构造函数。它接收三个 `Int` 类型的参数:

    RGBColour aquamarine = RGB 127 255 212

所以 `aquamarine` 是一个 `RGBColour` 类型的变量，值为 `RGB 127 255 212`。

构造函数鉴定(identifies)该类型。假设我们也有一个 HSL 颜色类型:

    datatype HSLColour = HSL Int Int Int

和该类型的变量 `chocolate`:

    HSLColour chocolate = HSL 25 75 47

那么 `RGB` 和 `HSL` 都是 `Int` 的三联体，但由于类型构造函数不同，所以它们不是同一类型。

比方说，我们创建一个 RGBPixel 类型:

    datatype XYCoord = XY Int Int
    datatype RGBPixel  = Pixel RGBColour XYCoord

那么:

    RGBPixel p = Pixel aquamarine (XY 42 24)

没有问题, 但是:

    RGBPixel p = Pixel chocolate (XY 42 24)

将是一个类型错误，因为 `chocolate` 的类型是 `HSLColour`，而不是 `RGBColour`。

我们可以使用和类型(sum type)同时支持 RGB 和 HSL:

    datatype Colour = HSL HSLColour | RGB RGBColour

然后修改 Pixel 类型的定义:

    datatype Pixel = Pixel Colour XYCoord

而现在我们可以说:

    Pixel p_rgb = Pixel (RGB aquamarine) (XY 42 24)
    Pixel p_hsl = Pixel (HSL chocolate) (XY 42 24)

### 整数和字符串、递归和多态

我可以听你说：但是 `Int` 呢，它没有构造函数吗？那么字符串呢，它怎么可能是一个代数数据类型呢？这些问题很有意思，因为它们让我又引入了两个概念：递归和多态类型。

#### 整数类型和递归类型

从类型的角度来看，你可以从两个方面来看待一个整数：如果它是一个固定大小的整数，那么 `Int` 类型可以被看作是一个和类型(sum type)。例如，一个 8 位无符号整数的类型可以这样标识:

    datatype UInt8 = 0 | 1 | 2 | ... | 255

换句话说，每个数字实际上都是一个类型构造函数的名称，作为 `Bool` 类型的泛化。

然而，在数学意义上，整数不是有限的。如果我们考虑自然数的情况，我们可以为它们构造一个如下所示的类型：

    datatype Nat = Z | S Nat

`Z` 代表"零"，`S` 代表"后继者"。这是一个递归类型，因为 `S` 构造函数接收一个 `Nat` 作为参数。有了这个类型，我们现在可以创建任何自然数:

    Nat 0 = Z
    Nat 1 = S Z
    Nat 2 = S (S Z)
    Nat 3 = S (S (S Z))
    ...

这种构建自然数的方式被称为 [Peano 数](https://www.britannica.com/science/Peano-axioms)。

#### 字符串的类型和多态类型

现在，字符串怎么办？枚举所有可能的任何长度的字符串是不现实的。但是从类型的角度来看，字符串是一个字符列表。那么问题来了：列表的类型是什么？首先，列表必须能够包含任意类型的值。(在代数数据类型的背景下，所有的值都必须是相同的，所以我们的列表更像是 Raku 中的类型数组。) 但这意味着我们需要可以被其他类型参数化的类型。这就是所谓的参数化多态性。所以列表类型必须看起来像这样:

    datatype List a = ...

其中 `a` 是一个类型变量，也就是说，它可以被一个任意的类型所取代。例如，假设我们简单地通过枚举字母表中的所有字符来定义 `Char` 类型（当然，因为在机器层面，每个字符都由一个整数表示）。

    datatype Char = 'a' | 'b' | 'c' | ... | 'z'

然后我们可以将我们的字符串输入为:

    List Char str = ...

但是 `List` 呢？我们使用与上面 `Nat` 类似的方法，使用一个递归和类型(recursive sum type):

    datatype List a = EmptyList | Cons a (List a)

现在我们可以创建一个任意长度的列表:

    List Char str = 
         Cons 'h' 
        (Cons 'e' 
        (Cons 'l' 
        (Cons 'l' 
        (Cons 'o' 
        EmptyList))))

使用标准的列表语法糖，我们可以将其写成:

    List Char str = [ 'h', 'e', 'l', 'l', 'o' ]

如果我现在为 `List Char` 发明了一个别名 `Str`，并使用双引号而不是列表标记法，我就可以写成这样:

    Str str = "hello"

因此，整数和字符串可以被表达为代数数据类型，现在我们已经引入了递归和参数化类型。

### 代数数据类型有什么用？

这些例子可能看起来比较生硬，毕竟像 Raku 这样的语言已经有 `Int` 和 `Str` 类型了，工作起来非常好。那么这些代数数据类型的用途是什么呢？当然，静态类型的目的是为了提供类型安全，使调试更容易。但是使用代数数据类型也使得不同的、更具函数式的编程风格成为可能。

一个常见的用例是列表，你想存储不同类型的值：你可以创建一个和类型(sum type)，每种类型都有一个可供选择的值。另一个常见的情况是递归类型，如树。最后，多态性提供了一种创建自定义容器的方便方法。我将在下一节中分别举出这些例子。是时候进入 Raku 了!

## Raku 中的代数数据类型

由于 Raku 不是一种非常知名的语言（迄今为止），这里快速介绍一下你需要了解的功能，以便你能跟得上下面的讨论。

### 对 Raku 的快速介绍

在 Raku 走自己的路之前，它的目的是成为 Perl 的下一个迭代版本（因此最初的名字是 Perl 6）。因此，它与 Perl 的相似度要高于其他任何语言。

Raku 在语法上类似于 C/C++、Java 和 JavaScript：以块儿为基础，语句由分号分隔，块儿由大括号划分，参数列表放在小括号里，参数由逗号分隔。它与 Perl 共享的主要特征是使用符号（"有趣的字符"）来识别变量的类型：`$` 代表标量，`@` 代表数组，`%` 代表散列（map），`&` 代表子程序。变量也有关键词来标识其作用域，我会只用 `my` 来标记变量的词法作用域。子程序是用 `sub` 关键字声明的，子程序可以是具名的或匿名的:

```raku
sub square ($x) {
    $x*$x;
}

# anonymous subroutine 
my $anon_square = sub ($x) {
    $x*$x;
}
```

Raku 也有 [twigils](https://docs.raku.org/language/variables#index-entry-Twigil)，即影响变量作用域的第二级符号。在这篇文章中，代码中使用的唯一符号是 `.`，它用于声明一个角色(role)或类的属性，并自动生成访问器（比如下面例子中的 `$.notes`）。

Raku 支持无符号变量，并使用 `\` 语法来声明这些变量。更多关于普通变量和无符号变量的区别，请参见 [Raku 文档](https://docs.raku.org/language/variables#Sigilless_variables)。例如（`say` 打印其参数，后面跟着换行符）:

```raku
my \x = 42;
my $y = 43;
say x + $y; 
```

Raku 拥有[渐进式类型](https://raku.guide/)：它既允许静态类型又允许动态类型。这是一个好的开始，因为我们需要静态类型化来支持代数数据类型。它也有[不可变变量](https://docs.raku.org/language/variables)和[匿名函数](https://raku.guide/#_anonymous_functions)，甚至还支持（[有限的](https://docs.raku.org/language/list#index-entry-laziness_in_Iterable_objects)）[惰性](https://docs.raku.org/language/list#index-entry-laziness_in_Iterable_objects)。当然，[函数也是一等公民](https://raku.guide/#_functional_programming)，所以我们拥有纯静态类型的函数式编程所需要的一切。但是 Raku 有代数数据类型吗？

在 Raku 中, `enum` 是和类型(sum type):

```raku
enum Bool <False True>
```

然而，它们仅限于不接收任何参数的类型构造函数。

类可以被看作是积类型(product type):

```raku
class BoolAndInt {
    has Bool $.bool;
    has Int $.int;
}
```

然而，类并不支持参数化多态。

这就是角色(role)出现的地方。根据 [Raku 的文档](https://docs.raku.org/language/objects#Roles):

    角色是属性和方法的集合；然而，与类不同，角色只是为了描述一个对象的部分行为；这就是为什么，一般来说，角色是为了混合在类和对象中。一般来说，类是用来管理对象的，而角色是用来管理对象中的行为和代码重用的。

角色在被声明的角色名称前使用关键字 `role`。角色的混合使用 `does` 关键字，在被混合的角色名称前面。角色在 Python 和 Ruby 中被称为 mixins。

所以角色基本上是你可以用来给其他类添加行为的类，而无需使用继承。下面是一个来自 Raku 文档精简后的例子（`has` 声明一个属性，`method` 声明一个方法）。

```raku
role Notable {
    has $.notes is rw;

    method notes() { ... }; 
}

class Journey does Notable {
    has $.origin;
    has $.destination;
    has @.travelers;

    method { ... <implemented using notes()> ... };
}
```

特别地，角色可以混入其他角色，这是我要利用的关键特性之一。此外，角色构造函数可以接收参数，而且是参数化的。所以我们拥有创建真正的代数数据类型所需的一切。让我们来看看几个例子。

### 几个简单的例子

#### An opinionated Boolean

这是上面的 Boolean 和类型(sum type)的例子，但用角色实现。第一行声明该类型是一个空的角色，这与左边的数据类型名称相对应。接下来的几行定义了可供选择的值，每个可供选择的值都使用了 `does OpinionatedBool`，将其与 `OpinionatedBool` 角色联系起来，该角色的功能纯粹是作为类型名称。

```raku
role OpinionatedBool {}
role AbsolutelyTrue does OpinionatedBool {}
role TotallyFalse does OpinionatedBool {}
```

在 Raku 中，类型就是值；对于一个具有空主体的角色，你不需要调用 `.new` 构造函数。在一个和类型(sum type)中，可供选择的值通常是标记为值的容器，但它们也可以是空容器。在这种情况下，没有必要为它们创建单独的实例，因为只有一种方法可以拥有一个空容器。

```raku
my OpinionatedBool \bt = AbsolutelyTrue;
```

和类型(sum type)可以与 Raku 的 `multi sub` 结合使用。Raku 允许你为一个函数提供多个定义，名称相同但签名不同。有了 `multi sub`，我们可以在类型上做所谓的模式匹配:

```raku
multi sub p(AbsolutelyTrue $b) {
    say 'True';
}

multi sub p(TotallyFalse $b) {
    say 'False';
}

p(bt); # prints True
```

因为我们使用一个类型作为值，要测试一个值是 `AbsolutelyTrue` 还是 `TotallyFalse`，我们可以使用智能匹配 `~~`，容器（类型）标识 `=:=` 或者值（实例）标识 `===` 来测试（如果右边是一个类型，智能匹配操作符的行为就像 `=:=`，如果右边是一个对象实例，则像 `===`）。如果我们要创建一个像 `AbsolutelyTrue.new` 这样的实例，就不会出现这种情况。更多细节请参见[代码示例](https://github.com/wimvanderbauwhede/raku-examples/blob/master/roles_types_and_instances.raku)。

#### Colour、XYCoord 和 Pixel 类型

下面是上面的 `Colour`、`XYCoord` 和 `Pixel` 类型的实现。`RGBColour` 类型是一个积类型(product type)的例子。与我上面的标记法有两处不同。

```
datatype RGBColour = RGB Int Int Int
```

    1. 因为这个角色既是类型(`RGBColour`)又是实例构造函数(`RGB`)，它们必须有相同的名字。我只是以不同的方式命名它们，使它们更容易区分，所以这不是一个问题。
    2. 组成每个字段的类型必须在角色的参数列表中用唯一的名字命名，并且需要声明相应的属性。这也不是一个真正的限制，因为记录类型字段的访问器是很方便的。所以它看起来像:

```raku
role RGBColour[Int \r, Int \g, Int \b] {
    has Int $.r = r;
    has Int $.g = g;
    has Int $.b = b; 
}
```

(角色的参数在方括号内)

然后我们像这样创建 `aquamarine`:

```raku
my RGBColour \aquamarine = RGBColour[ 127, 255, 212].new;
```

`HSLColour` 和 `XYCoord` 的定义是类似的，你可以在[代码示例](https://github.com/wimvanderbauwhede/raku-examples/blob/master/role_as_adt_colour_example.raku)中找到它们。让我们来看看结合了 RGB 和 HSL 颜色类型的和类型(sum type)。

```raku
role Colour {}
role HSL[ HSLColour \hsl] does Colour {
    has HSLColour $.hsl = hsl;
}

role RGB[ RGBColour \rgb] does Colour {
    has RGBColour $.rgb = rgb;
}
```

这与 opinionated Boolean 方法基本相同，但我们没有空角色：`HSL` 可供选择的值需要一个 `HSLColour` 类型的参数，而 `RGB` 可供选择的值需要一个 `RGBColour` 类型的参数。就像在积类型(product type)中一样，我们使用角色作为容器来保存数值。上面的 `Pixel` 类型看起来像这样:

```raku
role Pixel[ Colour \c, XYCoord \xy ] {
    has Colour $.c = c;
    has XYCoord $.xy = xy;
}
```

而现在我们可以用 RGB 和 HSL 颜色创建 **Pixel**:

```raku
my Pixel \p_rgb = Pixel[ RGB[ aquamarine].new , XYCoord[ 42, 24].new ].new;
my Pixel \p_hsl = Pixel[ HSL[ chocolate ].new , XYCoord[ 42, 24].new ].new;
```

#### 递归和多态

上面，我展示了 Peano 数字类型来说明类型级(type-level)的递归。这在 Raku 的角色中也能正常工作:

```raku
role Nat{}
role Z does Nat {}
role S[Nat $n] does Nat {}
```

而我们可以像在列表的例子中那样，将其与类型参数结合起来:

```raku
role List[::a] {}
role EmptyList[::a] does List[a] {}
role Cons[ ::a \elt, List \lst ] does List[a] {
    has $.elt = elt;
    has $.lst = lst;
}
```

(前缀 `::` 是 Raku 的语法，用于声明类型变量)

**当前 raku 的问题**

这里有一些问题。

- `EmptyList` 可供选择的值必须像上面那样，用一个类型参数来声明，或者写成这样:

```raku
role EmptyList does List {}
```

其中的类型也不接收类型变量。我们不能这样写:

```raku
role EmptyList does List[::a] {}
```

当然这只是一个小问题，只是导致了一些冗余。

    - 一个更严重的问题是，`lst` 的类型必须是 `List`(或 `List[]`)，而不是 `List[a]`。这确实是个问题，因为它削弱了类型检查的力度。所以这一定是当前版本的 `raku`（2020.01）的一个错误。当我提供 `List[a]` 时，我得到以下错误:

    Could not instantiate role 'Cons':
    Internal error: inconsistent bind result
    in any protect at gen/moar/stage2/NQPCORE.setting line 1216
    in block <unit> at list-adt.raku line 12

### 几个比较有用的例子

#### 一个 multi-type 数组

对于第一个例子，我想在一个类型化的数组中存储不同类型的值。它们的元素可以是字符串，标记的字符串列表，或未定义。我把这个类型称为 `Matches`。使用上面的标记法，它会是这样的:

```
datatype Matches = 
      Match Str 
    | TaggedMatches Str (List Matches) 
    | UndefinedMatch
```

在 Raku 中，它的定义如下:

```raku
role Matches {}
role UndefinedMatch does Matches {}
role Match[Str $str] does Matches {
    has Str $.match=$str;
}
role TaggedMatches[Str $tag, Matches @ms] does Matches {
    has Str $.tag = $tag;
    has Matches @.matches = @ms;
}
```

这个类型使用的类型构造函数有 0(`UndefinedMatch`)、1(`Match`) 和 2(`TaggedMatches`)参数，后者是一个递归类型：第二个参数是一个 `Matches` 的列表。有了这个定义，我们可以像这样创建一个匹配数组:

```raku
 my Matches @ms = Array[Matches].new(
     Match["hello"].new,
     TaggedMatches[
         "Adjectives",
         Array[Matches].new(
             Match["brave"].new,
             Match["new"].new) 
             ].new,
     Match["world"].new
     );
```

正如你所看到的，类型化的值实际上是通过调用 `.new` 来构建的。创建构造函数是比较好的，一旦 Raku 有一个更发达的宏系统，我们也许可以自动生成这些函数。

```raku
my Matches @ms = mkMatches(
    mkMatch "hello",
    mkTaggedMatches(
        "Adjectives",
        mkMatches(
            mkMatch "brave",
            mkMatch "new" 
            )
    ),
    mkMatch "world)
    );
```

[这里是这个例子的代码](https://github.com/wimvanderbauwhede/raku-examples/blob/master/roles_as_types.raku)

#### 一个通用元组

对于下一个例子，我想定义一个叫做 `Either` 的类型。这是一个拥有两个参数的参数化和类型(sum type)，所以是一种通用元组:

```
datatype Either a b = Left a | Right b
```

在 Raku 中，这可以通过使用类型变量作为角色的参数来实现:

```raku
role Either[::a, ::b] { }
role Left[::a \l, ::b] does Either[a, b] { 
    has a $.left = l;
}
role Right[::a, ::b \r] does Either[a, b] { 
    has b $.right = r;
}
```

因为 Raku 希望两个类型的变量都在每个构造函数中被声明，所以它比我的更抽象的标记法要差一点。我们可以用一个 `multi sub` 对这个类型进行模式匹配:

```raku
multi sub test (Left[Int, Str] $v) { say 'Left: '~$v.left }
multi sub test (Right[Int, Str] $v) {say 'Right: '~$v.right }
```

所以我们可以写成:

```raku
my Either[Int, Str] \iv = Left[42, Str].new;
my Either[Int, Str] \sv = Right[Int, 'forty-two'].new;

test(iv); # prints 'Left: 42'
test(sv); # prints 'Right: forty-two'
```

[这里是这个例子的代码](https://github.com/wimvanderbauwhede/raku-examples/blob/master/either.raku)

#### 一个参数化的二叉树

作为最后一个例子，这里有一个简单的二叉树。首先，让我们看看一个使用 [Raku 文档](https://docs.raku.org/language/objects#index-entry-Parameterized_Roles)中的角色实现的例子。

```raku
role BinaryTree[::Type] {
    has BinaryTree[Type] $.left;
    has BinaryTree[Type] $.right;
    has Type $.node;

    method visit-preorder(&cb) {
        cb $.node;
        for $.left, $.right -> $branch {
            $branch.visit-preorder(&cb) if defined $branch;
        }
    }
    method visit-postorder(&cb) {
        for $.left, $.right -> $branch {
            $branch.visit-postorder(&cb) if defined $branch;
        }
        cb $.node;
    }
    method new-from-list(::?CLASS:U: *@el) {
        my $middle-index = @el.elems div 2;
        my @left         = @el[0 .. $middle-index - 1];
        my $middle       = @el[$middle-index];
        my @right        = @el[$middle-index + 1 .. *];
        self.new(
            node    => $middle,
            left    => @left  ?? self.new-from-list(@left)  !! self,
            right   => @right ?? self.new-from-list(@right) !! self,
        );
}

my $t = BinaryTree[Int].new-from-list(4, 5, 6);
$t.visit-preorder(&say);    # OUTPUT: «5␤4␤6␤» 
$t.visit-postorder(&say);   # OUTPUT: «4␤6␤5␤» 
```

这个例子包含了相当多的 Raku 语法。

    - Raku 允许在名字中使用破折号。
    - `->` 语法是一个 foreach 循环，在前面的列表中迭代所有元素。
    - `..` 是数组切片。
    - `::?CLASS` 是一个编译时类型变量，填充了你所在的类，而 `:U` 是一个类型约束，指定它应该被解释为一个类型对象。最后，`:` 标记其左边的参数为调用者。换句话说，它允许我们写出 `BinaryTree[Int].new-from-list(4, 5, 6)`，其中 `BinaryTree[Int]` 是 `:?CLASS` 的值。这就是创建自定义构造函数的 Raku 方式。
    - `new-from-list` 方法中的 `@el` 参数前面的 `*` 使其成为一个可变参数函数(variadic function)，其中 `@el` 包含了所有的参数。
    - `=>` 语法允许按名称而不是按位置分配参数。
    - `?? ... !! ...` 是 Raku 对应 C 语言的三元组 `? ... : ...` 的语法。

这个例子是用 Raku 的面向对象风格编写的，方法作用于角色的属性。让我们看看如何用函数式编写这个例子。

这个二叉树的代数数据类型是这样的:

```
datatype BinaryTree a = 
      Node (BinaryTree a) (BinaryTree a) a 
    | Tip
```

`Tip` 可供选择的值是针对树的空叶子节点，在上面的例子中，这些叶子节点没有被定义。在 Raku 中，我们可以把这种类型实现为:

```raku
role BinaryTree[::Type] { }
role Node[::Type,  \l,  \r, \n] does BinaryTree[Type] { 
    has BinaryTree[Type] $.left = l;
    has BinaryTree[Type] $.right = r;
    has Type $.node = n;
}
role Tip[::Type] does BinaryTree[Type] { }
```

我们使用函数来代替方法，以 `multi sub` 的形式实现。大部分的代码当然是相同的，但是不需要条件式来检查是否已经到达了一个叶子节点。我还使用了无符号的不可变变量。

```raku
multi sub visit-preorder(Node \n, &cb) {
    cb n.node;
    for n.left, n.right -> \branch {
        visit-preorder(branch, &cb)
    }
}
multi sub visit-preorder(Tip, &cb) { }

multi sub visit-postorder(Node \n, &cb) {    
    for n.left, n.right -> \branch {
        visit-postorder(branch, &cb)
    }
    cb n.node;
}
multi sub visit-postorder(Tip, &cb) { }

multi sub new-from-list(::T, []) {
    Tip[Int].new    
}
multi sub new-from-list(::T, \el) {
    my \middle-index = el.elems div 2;
    my \left         = el[0 .. middle-index - 1];
    my \middle       = el[middle-index];
    my \right        = el[middle-index + 1 .. *];    
    Node[T,
        new-from-list(T, left),
        new-from-list(T, right),
        middle
    ].new;
}

my BinaryTree[Int] \t = new-from-list(Int, [4, 5, 6]);
visit-preorder(t, &say);    # OUTPUT: «5␤4␤6␤» 
visit-postorder(t, &say);   # OUTPUT: «4␤6␤5␤» 
```

有一点需要注意的是，在 `multi sub` 系统中，我们不必与完整的类型相匹配，例如在 `visit-preorder` 中，我们与 `Tip` 和 `Node` 相匹配，而不是与完整的 `Tip[a]` 和 `Node[:a, BinaryTree[a], BinaryTree[a], a]` 匹配。

[这个例子的代码](https://github.com/wimvanderbauwhede/raku-examples/blob/master/binary_tree_2.p6)

## 总结

用 Raku 的角色创建代数数据类型是非常直接的。任何积类型(product type)都只是一个带有一些类型属性的角色。和类型(sum type)的关键思想是创建一个空的角色，并将其与其他角色混合在一起，成为你可供选择的值(alternatives)的类型构造函数。因为角色接收类型参数，我们可以有参数化的多态性。因为角色可以有它自己类型的属性，所以我们也拥有递归类型。结合 Raku 的其他函数式编程特性，这使得在 Raku 中编写纯粹的、静态类型的函数式代码非常有趣。

## 参考文献

[1] ["代数数据类型中的代数(和微积分!)"，作者 Joel Burget](https://codewords.recurse.com/issues/three/algebra-and-calculus-of-algebraic-data-types)  
[2] ["代数数据类型中的代数，第一部分"，作者：Chris Taylor](https://gist.github.com/gregberns/5e9da0c95a9a8d2b6338afe69310b945)

## 原文链接

https://wimvanderbauwhede.github.io/articles/roles-as-adts-in-raku/
