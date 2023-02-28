All the brackes in Raku

Raku 中所有的括号

```
[] # 方括号
{} # 花括号
<> # 尖括号
() # 圆括号
«» # 日文尖括号 
<<>> # double 的尖括号
```

## 变量插值

> my $foo = "quz"
quz
> say <$foo>
$foo
> say <!$foo>
!$foo
> say <<$foo>>
quz

> say «$foo»
quz

> say <<<<$foo>>>>
(<< quz >>)
> say <<<<$foo>>>>.raku
("<<", "quz", ">>")

```raku
sub m { 42 }
say "&m()" # 需要圆括号来调用 m 子例程
```


## 正则表达式/Gramamr中的括号

<rule> <.rule>
<token> <.token>
<regex> <.regex>
<? before identifier>
<? after identifier>

如果尖括号后面的第一个字符不是有效的标识符字符, 例如 `.`、`?`、`!`,`&` 则 <.identifier>、<!identifier> <?identifier> 等会附加特殊意义。

`<.identifier>` 中的点号和 `<&identifier>` 中的 `&` 符号会抑制捕获。

```raku
#| 前置的点号抑制捕获
#| https://stackoverflow.com/questions/58158010/difference-in-capturing-and-non-capturing-regex-scope-in-perl-6-raku
#| 但是在正则表达式中似乎不成功:（因为我用的是点号抑制捕获语法）
#| 改为 <&sep> 成功了:
my regex number { \d+ }
my regex separator {
    | '|'
    | '-'
    | '.'
    | '_'
}

my token sep { '|' | '-' | '.' | '_' | <.alpha> }

for $=finish.lines {
    if m/ (<number>) <&sep> (<number>) / -> ($m, $n) {
        dd $/;
        say "$m, $n";
    }
}

=finish
12|34
56-78
90.91
1000_2047
1001w2049
1003s2051
```

如果你在上面的例子中使用 `<.sep>` 而不是 `<&sep>`, Raku 会告诉你 `No such method 'sep' for invocant of type 'Match'`。而使用 `<&sep>` 也会抑制捕获。[官方文档](https://docs.raku.org/language/regexes#Subrules)中有一句话, 说明了这两种抑制捕获的区别:

> If no capture is desired, a leading dot or ampersand will suppress it: <.named-regex> if it is a method declared in the same class or grammar, <&named-regex> for a regex declared in the same lexical context.

`<.named-regex>` 是一个声明在类或 Gramamr 中的方法, 而 `<&named-regex>` 是声明在同一个词法上下文中的 regex。细心的读者可能会发现, `sep` regex 中使用了 `<.alpha>`, 带点号的命名正则不是声明在类或 Grammar 中的吗? 为什么在 `sep` regex 中也能使用?

因为 `<.alpha>` 是 Raku 预定义的命名正则。

https://stackoverflow.com/questions/50676007/ident-function-capture-in-perl6-grammars