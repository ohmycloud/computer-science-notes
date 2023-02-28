使用 map + Empty 可以模拟 filter map:

```raku
(1..5).map(-> \x { if x % 2 == 0 {       } else { x } }) # Output: (1 Nil 3 Nil 5)
(1..5).map(-> \x { if x % 2 == 0 { Nil   } else { x } }) # Output: (1 Nil 3 Nil 5)
(1..5).map(-> \x { if x % 2 == 0 { Empty } else { x } }) # Output: (1 3 5)
```

Nil 占用空间, Empty 不占用空间:

```raku
(1, Nil, 3).elems.say;         # 3
(1, Empty, 3).elems.say;       # 2
(for Nil { $_ }).raku.say;     # (Nil,)
(for Empty { $_ }).raku.say;   # ()
(for Empty, Nil {$_}).raku.say # (Nil,)
(for Empty, Empty {$_}).elems  # 0
```

```raku
say Empty.WHAT; # (Slip)
say Nil.WHAT;   # Nil
```

```raku
my %h = 'a'..'b' Z=> 1..*;
dd %h; # Hash %h = {:a(1), :b(2)}

# 清空 Hash
%h = Empty; 
dd %h; # Hash %h = {}
```

现在把 `Nil` 赋值给 Hash:

```raku
%h = Nil;
```

会报错, Hash 初始化构造器说它找到奇数个元素:

```
Odd number of elements found where hash initializer expected:
Only saw 1 element
```

`Empty` is a `Slip` of the empty `List`.

```raku
say "".comb ~~ ();     # True
say "".comb ~~ [];     # True
say "".comb ~~ List(); # True
say "".comb ~~ Empty;  # True
say "".comb ~~ Nil;    # False
```

```raku
(1..5).map(-> \x { if x % 2 == 0 {  () } else { x } })     # (1 () 3 () 5)
(1..5).map(-> \x { if x % 2 == 0 {  [] } else { x } })     # (1 [] 3 [] 5)
(1..5).map(-> \x { if x % 2 == 0 {  {} } else { x } })     # (1 {} 3 {} 5)
(1..5).map(-> \x { if x % 2 == 0 { |() } else { x } })     # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |[] } else { x } })     # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |{} } else { x } })     # (1 3 5)

(1..5).map(-> \x { if x % 2 == 0 {  List() } else { x } }) # (1 (List(Any)) 3 (List(Any)) 5)
(1..5).map(-> \x { if x % 2 == 0 { |List() } else { x } }) # (1 (List(Any)) 3 (List(Any)) 5)
```

所以以下这几种写法是等价的:

```raku
(1..5).map(-> \x { if x % 2 == 0 { Empty } else { x } }) # Output: (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 {   |() } else { x } }) # Output: (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 {   |[] } else { x } }) # Output: (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 {   |{} } else { x } }) # Output: (1 3 5)
```

甚至:

```raku
(1..5).map(-> \x { if x % 2 == 0 { ||Empty } else { x } })   # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |||Empty } else { x } })  # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { ||||Empty } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { ||||||||||||||||||||||||||Empty } else { x } }) # (1 3 5)
```


```raku
(1..5).map(-> \x { if x % 2 == 0 { @ } else { x } }) # (1 [] 3 [] 5)
(1..5).map(-> \x { if x % 2 == 0 { % } else { x } }) # (1 {} 3 {} 5)
(1..5).map(-> \x { if x % 2 == 0 { $ } else { x } }) # (1 (Any) 3 (Any) 5)
(1..5).map(-> \x { if x % 2 == 0 { & } else { x } }) # (1 (Callable) 3 (Callable) 5)

```

```raku
(1..5).map(-> \x { if x % 2 == 0 { |@ } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |% } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |$ } else { x } }) # (1 (Any) 3 (Any) 5)
(1..5).map(-> \x { if x % 2 == 0 { |& } else { x } }) # (1 (Callable) 3 (Callable) 5)
```

使用 `dd` 分别车看 `@`、`%`、`$`、`&` 的结构:

```raku
dd @ # Array @ = []
dd % # Hash % = {}
dd $ # Any $ = Any
dd & # Callable & = Callable
```

初始化一个空数组、空 Hash、空标量、

```raku
my @a = @; dd @a; # Array @a = []
my %a = %; dd %a; # Hash %a = {}
my $a = $; dd $a; # Any $a = Any
my &a = &; dd &a; # Callable &a = Callable
```

```raku
(1..5).map(-> \x { if x % 2 == 0 { |@() } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |%() } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |$() } else { x } }) # (1 3 5)
(1..5).map(-> \x { if x % 2 == 0 { |&() } else { x } }) # (1 3 5)
```

```raku
dd %() # Hash % = {}
dd @() # ()
dd $() # $( )
dd &() # $( )
dd %{} # Hash % = {}
```

使用 `WHAT` 查看元素的类型

```raku
%().WHAT # Hash
@().WHAT # List
$().WHAT # List
&().WHAT # List
%{}.WHAT # Hash
```

一些没有意义的代码:

```raku
(1..5).map(-> \x { if x % 2 == 0 {   * } else { x } }) # (1 * 3 * 5)
(1..5).map(-> \x { if x % 2 == 0 {  |* } else { x } }) # (1 WhateverCode.new 3 WhateverCode.new 5)
(1..5).map(-> \x { if x % 2 == 0 {  ** } else { x } }) # (1 ** 3 ** 5)
(1..5).map(-> \x { if x % 2 == 0 { |** } else { x } }) # (1 sub { } 3 sub { } 5)
```

还有一个 `|$_`:

```raku
(1..5).map(-> \x { if x % 2 == 0 {  $_  } else { x } }) # (1 () 3 () 5)
(1..5).map(-> \x { if x % 2 == 0 { |$_  } else { x } }) # (1 3 5)
```

匹配签名中的 Empty:

```
multi sub foo ($_){.say}
multi sub foo (Empty){ say 'Hello, World' }

foo Empty;    # Hello, World
foo (1 if 0); # Hello, World
foo (|());    # Hello, World
foo (|[]);    # Hello, World
foo (|{});    # Hello, World
foo (|%);     # Hello, World
foo (|@);     # Hello, World
foo (Slip.new)# Hello, World

foo (if False {}) # Hello, World
```

因为:

```raku
|() ~~ Empty # True
|[] ~~ Empty # True
|{} ~~ Empty # True
|%  ~~ Empty # True
|@  ~~ Empty # True

Slip.new ~~ Empty      # True
(if False {}) ~~ Empty # True
```

`if False {}` 语句返回的是 `Slip` 类型。

```raku
dd (if False {}).^name # "Slip"
```

## Empty 的应用场景

- https://stackoverflow.com/questions/50571359/perl6-array-get-rid-of-empty-slot-any

```raku
my @a = <AB BC MB NB NL NS ON PE QC SK>; @a.elems; # 10
@a[2]:delete;
@a.elems; # 10
dd @prov_cd
# Array @prov_cd = ["AB", "BC", Any, "NB", "NL", "NS", "ON", "PE", "QC", "SK"]
```

虽然删除了一个元素, 但是这个被删除的元素还占用一共位置(slot), 使用 Empty 模仿 filter_map 可以把空的 slot 过滤掉:

```raku
@prov_cd.map(-> \x { if x.defined { x } else { Empty } })
```

- https://stackoverflow.com/questions/52613981/why-does-command-after-if-false-produce-an-empty-list-in-perl-6-repl

使用 `if False` 返回 `Empty` 的特性, 可以把 map 当作 grep 来使用:

```raku
(1..5).map: { $_ if $_ % 2 != 0 } # (1 3 5)
```

类似的还有 `... with Nil` 和 `Nil andthen ...` 也返回 Empty:

```raku
(1 with Nil)    ~~ Empty # True
(Nil andthen 1) ~~ Empty # True
```

```raku
(1 with Nil).WHAT  # Slip
(1 with Nil).^name # Slip

(Nil andthen 1).WHAT  # Slip
(Nil andthen 1).^name # Slip
```

## 参考链接

- https://docs.raku.org/syntax/Empty
- https://docs.raku.org/type/Nil
- https://stackoverflow.com/questions/49280568/the-use-of-flip-flop-operator-in-perl-6/49281846#49281846
- https://stackoverflow.com/questions/43437664/how-can-i-get-around-a-slurpy-parameter-in-the-perl-6-signature/43438764#43438764
- https://stackoverflow.com/questions/61140503/alternation-in-regexes-seems-to-be-terribly-slow-in-big-files/61146532#61146532
- https://stackoverflow.com/questions/45844816/how-can-i-idiomatically-ignore-undefined-array-elements-or-avoid-assigning-them
- https://stackoverflow.com/questions/52613981/why-does-command-after-if-false-produce-an-empty-list-in-perl-6-repl/52637642#52637642
- https://stackoverflow.com/questions/52613981/why-does-command-after-if-false-produce-an-empty-list-in-perl-6-repl