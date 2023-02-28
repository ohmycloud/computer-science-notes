# Raku 中的 capure

```raku
my grammar Gram {
    regex TOP { ('XX')+ %% $<delim>=<.same> }
}

my $m = Gram.parse('XXXXXX');
say $m;
```


```raku
my regex dotdot { (.)(.) }

"zzzabcdefzzz" ~~ m/(a.)<.&dotdot>(..)/;
```

我们知道 `<...>` 结构中, 如果 `<` 后面的第一个字符不是字母符号, 就会抑制捕获行为。那么后面的 `&` 符号又是干什么的呢?

`<&named_regex>` 这种写法和 `<.named_regex>` 这种写法的区别在于作用域不同, 前这在 Grammar 级别下。

```raku
> "zzzabcdefzzz" ~~ m/(a.)<.dotdot>(..)/
No such method 'dotdot' for invocant of type 'Match'
  in block <unit> at <unknown file> line 1
```

直接使用 `<&named_regex>` 结构就会抑制捕获, 且作用域有效。

```raku
> "zzzabcdefzzz" ~~ m/(a.)<&dotdot>(..)/
｢abcdef｣
 0 => ｢ab｣
 1 => ｢ef｣
```

`=>` 分隔了数字编号(或命名编号)和捕获, 数字编号对应于位置捕获, 命名编号对应于命名捕获:

```raku
> "zzzabcdefzzz" ~~ m/(a.)<dotdot>(..)/
｢abcdef｣
 0 => ｢ab｣
 dotdot => ｢cd｣
  0 => ｢c｣
  1 => ｢d｣
 1 => ｢ef｣
```

例如上面的数字 最外层的 0, 1, 分别对应于 `(a.)<dotdot>(..)` 中的第一个圆括号和第二个圆括号, dotdot 对应于 `<dotdot>`。
内层的数字编号 0, 1 分别对应于 regex dotdot 中的第一个圆括号和第二个圆括号。

下面的是一个 bug 吗? 只是在 `$0` 周围加上了捕获圆括号而已:

```raku
> my token single { o | k | e };
> say so "bookkeeper" ~~ m/(<.&single>) $0/
True
>
> say so "bookkeeper" ~~ m/(<.&single>) ($0)/
False
```

```raku
grammar English { regex name { john } }
grammar French  { regex name { jean } }
grammar Russian { regex name { ivan } }

"john" ~~ m/<.English::name> | <.French::name> | <.Russian::name>/; # ｢john｣
"john" ~~ m/<English::name> | <.French::name> | <.Russian::name>/;  #  English::name => ｢john｣
```

这里的点再次抑制了捕获, `::` 是命名空间分隔符, 相当于调用了类中的方法。

```raku
regex name { <.English::name> | <.French::name> | <.Russian::name> }

"john" ~~ m/<name>/  # ｢john｣
"jean" ~~ m/<name>/  # ｢jean｣
"ivan" ~~ m/<name>/; # ｢ivan｣
```

```raku
'ab12de' ~~ /(\d+)/;
say $/.list.elems; # 1
say $/.list;       # (｢12｣)
say $/.hash;       # Map.new(())

'ab12de' ~~ /$<number>=(\d+)/
say $/.hash; # Map.new((number => ｢12｣))
say $/.list; # ()
```

匹配右单词边界(零宽匹配):

```raku
'abc def' ~~ />>/; # ｢｣
say $/.from;       # 3
say $/.to;         # 3
say $/.prematch;   # abc
say $/.postmatch;  # def
```

`:$<foo>` 冒号对:

```raku
my $res = do { 'abc' ~~ /a $<foo>=[\w+]/; :$<foo> };
dd $res; # Pair $res = :foo(Match.new(:orig("abc"), :from(1), :pos(3)))

say so $res ~~ Pair;          # True
say $res.key;                 # foo
say so $res.value ~~ Match:D; # True
```
