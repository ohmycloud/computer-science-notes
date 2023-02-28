# Rust Pest Vs Raku Grammar

## pest grammar 的语法

`pest` grammar 是一系列的 rule。

```
//! Grammar doc
my_rule = { ... }

/// Rule doc
another_rule = {        // comments are preceded by two slashes
    ...                 // whitespace goes anywhere
}
```

左侧的花括号 `{` 之前可以添加[修饰符](https://pest.rs/book/grammars/syntax.html#silent-and-atomic-rules), 改变 rule 的行为:

```
silent_rule = _{ ... }
atomic_rule = @{ ... }
```

Raku Grammar:

```raku
my regex my_regex { ... }

my regex another_regex { # comments are preceded by a hashtag
    ...                  # whitespace goes anywhere 
}
```

在不加修饰符的时候, pest Grammar 中的 rule 和 Raku Grammar 中的 regex 的行为是一样的。 

## 断言

Preceding an expression with an ampersand & or exclamation mark ! turns it into a predicate that never consumes any input. You might know these operators as "lookahead" or "non-progressing".

The positive predicate, written as an ampersand &, attempts to match its inner expression. If the inner expression succeeds, parsing continues, but at the same position as the predicate — &foo ~ bar is thus a kind of "AND" statement: "the input string must match foo AND bar". If the inner expression fails, the whole expression fails too.

The negative predicate, written as an exclamation mark !, attempts to match its inner expression. If the inner expression fails, the predicate succeeds and parsing continues at the same position as the predicate. If the inner expression succeeds, the predicate fails — !foo ~ bar is thus a kind of "NOT" statement: "the input string must match bar but NOT foo".

This leads to the common idiom meaning "any character but":

not_space_or_tab = {
    !(                // if the following text is not
        " "           //     a space
        | "\t"        //     or a tab
    )
    ~ ANY             // then consume one character
}

triple_quoted_string = {
    "'''"
    ~ triple_quoted_character*
    ~ "'''"
}
triple_quoted_character = {
    !"'''"        // if the following text is not three apostrophes
    ~ ANY         // then consume one character


## Implicit whitespace

The optional rules WHITESPACE and COMMENT implement this behaviour. If either (or both) are defined, they will be implicitly inserted at every sequence and between every repetition (except in atomic rules).

expression = { "4" ~ "+" ~ "5" }
WHITESPACE = _{ " " }
COMMENT = _{ "/*" ~ (!"*/" ~ ANY)* ~ "*/" }

"4+5"
"4 + 5"
"4  +     5"
"4 /* comment */ + 5"

As you can see, WHITESPACE and COMMENT are run repeatedly, so they need only match a single whitespace character or a single comment. The grammar above is equivalent to:

expression = {
    "4"   ~ (ws | com)*
    ~ "+" ~ (ws | com)*
    ~ "5"
}
ws = _{ " " }
com = _{ "/*" ~ (!"*/" ~ ANY)* ~ "*/" }


Note that Implicit whitespace is not inserted at the beginning or end of rules — for instance, expression does not match " 4+5 ". If you want to include Implicit whitespace at the beginning and end of a rule, you will need to sandwich it between two empty rules (often SOI and EOI as above):

WHITESPACE = _{ " " }
expression = { "4" ~ "+" ~ "5" }
main = { SOI ~ expression ~ EOI }

"4+5"
"  4 + 5   "

(Be sure to mark the WHITESPACE and COMMENT rules as silent unless you want to see them included inside other rules!)

SOI 的后面和 EOI 的前面被插入了空白和注释。

相当于 Raku Grammar 中的 rule。

等价的 Raku Grammar 是这样的:

```raku
my rule expression { 4 '+' 5 }

say so "4+5" ~~ /<expression>/;
say so "4 + 5" ~~ /<expression>/;
say so "4  +     5" ~~ /<expression>/;
say so "4 /* comment */ + 5" ~~ /<expression>/; 
```

Raku 中的 rule 隐式地插入了空白，写成 token 可以看到空白被插入到了哪些地方:

```raku
my token expression { 4 <.ws> '+' <.ws> 5 };

say so " 4+5 "      ~~ /<expression>/;
say so "4+5 "       ~~ /<expression>/;
say so "4+5"        ~~ /<expression>/;
say so "4 + 5"      ~~ /<expression>/;
say so "4  +     5" ~~ /<expression>/;
say so "4 #`() + 5" ~~ /<expression>/; 
```

token 的开始和结束默认被插入空白, 上面的 token 写成这样也没有问题:

```raku
my token expression { <.ws> 4 <.ws> '+' <.ws> 5 <.ws> };
```

## Silent and atomic rules

Silent

Silent rules are just like normal rules — when run, they function the same way — except they do not produce pairs or tokens. If a rule is silent, it will never appear in a parse result.

To make a silent rule, precede the left curly bracket { with a low line (underscore) _.

silent = _{ ... }

Rules called from a silent rule are not treated as silent unless they are declared to be silent. These rules may produce pairs or tokens and can appear in a parse result.

Raku Grammar 中和 Slient 对应是非捕获 token(non-captured token)，例如 `<.ws>` 抑制了捕获, 最终的抽象语法树中就不会包含 ws token。 

# 使用 pest 解析结构化文本

[https://pest.rs](pest) 的语法类似于 Raku 中的 [Grammar](https://docs.raku.org/language/grammars), 只是 pest 使用后缀名为 `.pest` 的文件组织 Gramamr，而 Raku 使用 Grammar 类来指定。

## rule

rule 可以包含其它 rule。

## 特殊的 rule

SOI: start of input
EOI: end of input

每次解析都需要 SOI 和 EOI, 定义文本的开始和结束。

`~` 波浪号用于连接两个相邻的项:

"abc" ~ "def" 用于匹配 "abcdef", Raku 中的等价写法如下:

```raku
"abcdef" ~~ /abc def/;
```

## Grammar in PEST

`.pest` 文件用于编写 rules, 使用等号分隔标识符和 rule 的定义。rule 和 rule 之间使用 `~` 连接, 可以写成多行: 

```pest
prefix = {
    | "Perl6"
    | "Raku"
    | "Pugs"
    | "Parrot"
}
```

默认 pest 中的空白是无意义的。

## 对空白的处理

```
"4+5"
"4 + 5"
"4  +     5"
"4 /* comment */ + 5"
```

pest 文件如下:

```pest
expression = {"4" ~ "+" ~ "5"}
WHITESPACE = _{ " " }
COMMENT = _{ "/*" ~ (!"*/" ~ ANY)* ~ "*/" }
```

上面的 Grammar 等价于:

```
expression = {
    "4"   ~ (ws | com)*
    ~ "+" ~ (ws | com)*
    ~ "5"
}
ws = _{ " " }
com = _{ "/*" ~ (!"*/" ~ ANY)* ~ "*/" }
```

如果 pest 文件中不包含 `WHITESPACE` 这个 rule, 则需要显式地使用 `~` 拼接 `" "` 空格。可以覆盖换行符:

```
newline = @{ ("\n" | "\r\n" | " ")* }
```

转换为 Raku 的 Grammar 如下:

```raku
4 <.ws> + <.ws> 5
```

## 内置 rule

PEST 有很多内置 rule, 例如 COMMENT, NEWLINE

```
COMMENT = _{ " " | "\t" }
NEWLINE = _{ ("\n" | "\r\n")* }
```

内置的 rule 可以被覆盖。如上所示, 我们覆盖了默认的注释和换行语法。`_` 是修饰符, 阻止了语法树中出现这个 rule。类似于 Raku 中的 `<.ws>` 语法。

## 结束语

PEST 中的 Gramamr 写法和 Raku 中 Gramamr 的写法非常相似, PEST 可能借鉴了 Raku Grammar 的设计思想。与 Raku 不同的是, PEST 中相邻两个 rule 之间需要使用 `~` 符号连接, 以组合成一个完整的 rule。而在 Raku 中, 只需要按顺序写上 `<rule>` 名即可, Raku 默认会忽略相邻两个 rule 之间的空白, 然后组合成一个完整的 rule。 

Raku 中一个比较好用的是 `%` 和 `%%` 修饰符, PEST 中目前还没有这样的语法。

## 参考链接

- https://crates.io/crates/pest
- https://crates.io/crates/pest_consume