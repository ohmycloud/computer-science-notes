原文链接: https://wimvanderbauwhede.github.io/articles/haku-in-raku/

Haku is a natural language functional programming language based on literary Japanese. This article is about the implementation of Haku in Raku. You don't need to know Japanese or have read the Haku documentation. I you are not familiar with Raku, you might want to read my quick introduction.

I do assume familiarity with the concepts of parsing, syntax tree and code generation. I you find you lack background for what follows, I recommend Andrew Shitov's series of posts Creating a Compiler with Raku which takes a step-by-step approach.
Haku

Haku aims to be close to written Japanese, so it is written in a combination of the three Japanese writing systems kanji (Chinese characters), hiragana and katakana, and Japanese punctuation. There are no spaces, and Haku does not use Arabic (or even Roman) digits nor any operators. The design of the language is explained in more detail in the documentation.

Here is an example of a small Haku program (for more examples see the repo):

本とは
「魄から楽まで」を見せる
の事です。

This translates as

    "main is: to show 'From Haku to Raku'"

And the Raku version would be

say 'From Haku to Raku';

The strings "本とは" and "の事です。" indicate the start and end of the main program. "「魄から楽まで」" is a string constant. "見せる" is the print function. The 'を' indicates that anything before it is an argument of the function. The newlines in the example code are optional and purely there for readability. A Haku program is a single string without whitespace or newlines.

The actual generated Raku code for this example is

use v6;
use HakuPrelude;

sub main() {
    show('魄から楽まで')
}

main();

To be even closer to literary Japanese, Haku programs can be written vertically from right to left:

の 忘 本 　 の 条 条 遠 　 の 物 忘
事 れ と 　 こ を で い 　 こ で れ
で か は 　 と 見 　 と 　 と 空 る
す け 記 　 で せ 　 は 　 で 　 と
。 て 憶 　 す る 　 　 　 す 　 は
　 た は 　 。 　 　 　 　 。 　 　g
　 遠 無 　 　 　 　 　 　 　 　 　
　 い 、 　 　 　 　 　 　 　 　 　
　 記 　 　 　 　 　 　 　 　 　 　
　 憶 　 　 　 　 　 　 　 　 　 　

The generated Raku code for this Haku program is again quite simple:

use v6;
use HakuPrelude;

sub wasureru( \mono) {[]}

sub tooi( \jou) {show(jou)}

sub hon() {
    my \kioku = Nil;
    wasureru(tooi(kioku))
}

hon();

Haku is implemented in Raku. The Haku compiler is a source-to-source compiler (sometimes called transpiler) which generates Raku source from the Haku source and executes it. Raku makes writing such a compiler easy in many ways:
Parsing using Grammars

I decided to implement Haku in Raku mostly because I wanted to use Raku's Grammars feature, and it did not disappoint. A grammar is like a class, but instead of methods it has rules or tokens, which are the building blocks of the parser. Any token can be used in the definition of another token by enclosing it in <...>, for example:

token adjective {
    <i-adjective> | <na-adjective>
}

The tokens i-adjective and na-adjective have been defined separately and adjective matches one or the other.

I have always liked parser combinators (like Parsec in Haskell) and from a certain angle, Raku's Grammar's are quite similar. They are both scannerless, i.e. there is no separate tokenisation step, and highly composable. Many of the features offered by Parsec (e.g. many, oneOf, sepBy) are available courtesy of Raku's regexes.

There are several features of Raku's Grammars that helped to make the parser for Haku easy to implement.
Excellent Unicode support

I think Raku's Unicode support is really excellent. For example, thanks to the support for Unicode blocks, I can simply write

token kanji {  
    <:Block('CJK Unified Ideographs')>
}  

rather than having to enumerate them all (there are 92,865 kanji in that block!). In fact, the <:...> syntax works for any Unicode property, not just for Blocks.

Even better: I have some kanji that are reserved as keywords:

token reserved-kanji { '本' | '事' | ... }

To make sure these are excluded from the valid kanji for Haku, I can simply use a set difference:

token kanji {  
    <:Block('CJK Unified Ideographs') - reserved-kanji >
}  

(One detail that bit me is that the equivalent syntax for a user-defined character class requires an explicit '+' : token set-difference { < +set1 -set2> } )
Tokens and rules

Luckily, Raku does not assume by default that you want to parse something where whitespace can be ignored, or that you want to tokenise on whitespace. If you want to ignore whitespace, you can use a rule. But in Haku, extraneous whitespace is not allowed (except for newlines at certain locations). So I use token everywhere. (There is also regex, which backtracks. In Haku's grammar I have not needed it.)
Very powerful regexes

As a lambdacamel, I've always been fond of Perl's regexes, the now ubiquitous PCREs. Yet, Raku's regexes go way beyond that in power, expressiveness and readability.

For one thing, they are composable: you can defined a named regex with the regex type and use it in subsequent regexes with the <...> syntax. Also, the care with which they have been designed makes them very easy to use. For example, a negative look-ahead assertion is simply <no> <!before <koto> >; and the availability of both a try-in-order alternation (||) and longest-token match alternation (|) is a huge boon. Another thing I like very much is the ability to make a character class non-capturing:

    token lambda-expression { 
        <.aru> <variable-list> <.de> <expression> 
    }

Only <variable-list> and <expression> will be captured, so a lot of the concrete syntax can be removed at parse time.
Grammar composition via roles

Roles ('mixins' in Ruby, 'traits' in Rust) define interfaces and/or implementation of those interfaces.
I found this a better fit for my purpose than the also-supported class inheritance. For example:

role Nouns does Characters {
    token sa { 'さ' }
    token ki { 'き' }
    # 一線 is OK,  一 is not OK, 線 is OK
    token noun { 
        <number-kanji>? <non-number-kanji> <kanji>* 
        [<sa>|<ki>]?
    }
}

role Identifiers 
does Verbs 
does Nouns 
does Adjectives 
does Variables 
{
    token nominaliser {
        | <no> <!before <koto> > 
        | <koto> <!before <desu> > 
    }
    # Identifiers are variables,
    # noun-style, verb-style
    # and adjective-style function names
    token identifier { 
        | <variable> 
        | <verb> <nominaliser>? 
        | <noun> <.sura>? 
        | <adjective> }
}

(Although I would like a list syntax for this, something like role Identifiers does Verbs, Nouns, Adjectives, Variables {...}.)

There is a lot more to grammars and regexes. The nice Raku folks on Twitter recommended me the book "Parsing with Perl 6 Regexes and Grammars" by Moritz Lenz and it was very useful in particular for debugging of the grammar and handling of error messages.
Abstract syntax tree using roles

I like to implement the abstract syntax tree (AST) as an algebraic data type, the way it is usually done in Haskell. In Raku, one way to do this is to use parametrised Roles as I explained in an earlier post. Most of the AST maps directly to the toplevel parser for each role in my grammar, for example the lambda expression:

role LambdaExpr[ @lambda-args, $expr] does HakuExpr {
    has Variable @.args = @lambda-args;
    has HakuExpr $.expr = $expr;
} 

From parse tree to abstract syntax tree

Raku's grammars provide a very convenient mechanism for turning the parse tree into an AST, called Actions. Essentially, you create a class with a method with the same name as the token or rule in the Grammar. Each method gets the Match object ($/) created by the token as a positional argument.

For example, to populate the AST node for a lambda expression from the parse tree:

method lambda-expression($/) {
        my @args = $<variable-list>.made;
        my $expr = $<expression>.made;
        make LambdaExpr[@args,$expr].new;
}

The capturing tokens used in the lambda-expression token are accessible via the notation $<...> which is shorthand for $/<...>, i.e. they are named attributes of the current match object.

In the Haku grammar, there are several tokens where the match is one from a list of alternatives, for example the expression token, which enumerates anything that is an expression in Haku. For such tokens I use the following code to "inherit" from the constituent tokens:

method expression($/) { 
        make $/.values[0].made;
}

Because every match is a map with as keys the names of the capturing tokens, and because we know that in this case there will be only one token selected, we know the first element in the corresponding values list will be the match for that particular token.
Code generation

The haku.raku main program essentially does this:

my $hon_parse = 
    Haku.parse($program_str, :actions(HakuActions));
my $hon_raku_code =  
    ppHakuProgram($hon_parse.made);

The Haku program string is parsed using the Haku grammar and the methods defined in the corresponding HakuActions class are used to populate the AST. The toplevel parse tree node must be $<haku-program>, and the made method of this node returns the AST node HakuProgram. The routine ppHakuProgram is the toplevel routine in the module Raku, which is the Raku emitter for Haku. (There is also a Scheme emitter, in the module Scheme.)

So ppHakuProgram($hon_parse.made) pretty-prints the HakuProgram AST node and thus the entire Haku program as Raku code.

What I like about the role-based AST is that you can pattern match against the variants of a type using given/when:

sub ppHakuExpr(\h) {            
    given h {
        when BindExpr { ... }
        when FunctionApplyExpr { ... }
        when ListExpr { ... }
        when MapExpr { ... }        
        when  IfExpr { ... }   
        when LetExpr { ... }
        when LambdaExpr { ... }        
        ...
        default {
            die "TODO:" ~ h.raku;
        }        
    }
} 

The Raku code corresponding to the Haku AST is quite straightforward, but there are a few things worth noting:

    Because Haku's variables are immutable, I use the \ notation which means I don't have to build a variable table with the sigils.
    Because Haku is functional, let and if are expressions, so in Raku I wrap them in a do {} block.
    For partial application I use .assuming().
    In Haku, strings are lists. In Raku they aren't. I created a small Prelude of functions, and the list manipulation functions in that Prelude use pattern matching on the type with given/when to see if the argument is a string or a list.

Running the generated Raku code

Running the generated Raku code is simple: I write the generated Raku code to a module and require it. The generated code ends with a call to hon(), the main function in a Haku program, so this automatically executes the program.

# Write the parsed program to a module 
my $fh = 'Hon.rakumod'.IO.open: :w;
$fh.put: $hon_raku_code;
$fh.close;

# Require the module. This will execute the program
require Hon;

Other things Haku makes really easy is to create command-line flags and document their usage:

sub USAGE() {
    print Q:to/EOH/;
    Usage: haku <Haku program, written horizontally or vertically, utf-8 text file>
        [--tategaki, -t] : do not run the program but print it vertically.
        [--miseru, -m] : just print the Raku source code, don't execute.
        ...
    EOH
}

unit sub MAIN(
          Str $src_file,
          Bool :t($tategaki) = False,   
          Bool :m($miseru) = False,
          ...
        );  

USAGE is called when MAIN is called with the wrong (or no) arguments. Arguments of MAIN prefixed with : are flags. unit sub means that anything after this declaration is part of the MAIN program, so no need for {...}.
To conclude

This article shows the lazy programmer's way to creating your own programming language: let Raku do all the hard work.

Or to express it with a Haku program:

　本真とは
　コンパイラを書いて、
　プログラムを書いて、
　プログラムを走らす
　と言う事です。

    the truth:
    write the compiler,
    write the program,
    run the program.
