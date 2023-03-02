On sigils

# 关于符号

This post was inspired by @codesections recent posts on sigils, particularly the notion of coding as a trialog between the writer, the reader and the machine.

@codesections already did a great job of reflecting the wider societal uptake of eg. #hashtags and @names as examples of sigils in the wild.

I aim to show sigils in action with some simple examples in the raku programming language.

A sigil, for this purpose, is the use of a single non-word character – usually a dollar sign $ – to distinguish a variable name from other words in the code such as operators and functions.

    Disclosure: I learned to program with C and Perl and I use Linux as my OS with the Bash shell and I code in raku practically every day.

On dollar $ – ease of use

![img](https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/United_States_one_dollar_bill%2C_reverse.jpg/800px-United_States_one_dollar_bill%2C_reverse.jpg)

Here’s some Python:

language = "Python"
print("I like coding in " + language + " the most.")

#I like coding in Python the most.

The sentence has been broken into literals with ” quote marks and then concatenated with the variable with the ‘+’ operator.

And here’s some Raku:

my $language = "Raku";
say "I like coding in $language the most."

#I like coding in Raku the most.

Here, the sigil identifies the variable and interpolates it into the output. It eliminates several extra quote marks and concatenation operators. It cuts out unwanted “line noise”.
On dollar $ – linguistics

We are dealing with coding languages. As with natural languages, syntax is a key marker that triggers cognitive mechanisms learned since childhood. While the base cultural setting for most of this is English, most human languages carry the notions of noun, verb, adjective and so on.

Here’s some English:


Jack and Jill went up the hill 
To fetch a pail of water 
Jack fell down and broke his crown 
And Jill came tumbling after

The proper names begin with Capital letters.

And here’s some Raku:

my ($boy, $girl) = <Jack Jill>;

say qq:to/END/;

$boy and $girl went up the hill 
To fetch a pail of water 
$boy fell down and broke his crown 
And $girl came tumbling after

END

See how the $variables catch the eye? Rather like the Capitals we are used to – and proper nouns are similarly interchangeable since it could have been Alice and Bob.
On dollar $ – practicalities

In the first place, sigils emerged from a long line of coding tools as a practical technique. For example, the dollar sign $ shows up as a sigil on Linux shell and environment variables, here in a simple Bash example:

    #!/bin/bash
    for (( n=2; n<=10; n++ ))
    do
    echo "$n seconds"
    done

    https://www.hostinger.co.uk/tutorials/bash-script-example

C pointers (with ‘*’ prefix) and references (with ‘&’ prefix) take a similar looking approach that tells the compiler what we want and the coder what we have:

    int i = 3; 

    // A pointer to variable i or "stores the address of i"
    int *ptr = &i; 

    // A reference (or alias) for i.
    int &ref = i; 

    https://www.geeksforgeeks.org/pointers-vs-references-cpp/

The $ sigil line continues through web-based interpolation in various guises (with eg. PHP and Ruby) and fairly recently in the SCSS variant of CSS:

    $font-stack: Helvetica, sans-serif;
    $primary-color: #333;

    body {
      font: 100% $font-stack;
      color: $primary-color;
    }

    https://sass-lang.com/guide

So, it’s tempting to stop here with the $ dollar sigil – it is easy, natural and practical.

    Author’s note: Not all coders see the benefits. Sometimes IDE tools provide an alternative to sigil characters with colour coding (personally, I don’t find multi-colour text very helpful). Many find noisy sigil symbols a distraction from the code. It boils down to choice.

    Nevertheless, I think it is fair to say that the humble dollar $ sigil has found a solid use case in many situations among a large body of coders with that shared heritage and mindset.

Let’s say you buy the $ dollar sigil as a useful tool? If so, raku has thoughtfully extended the technique for a few more substantial purposes.
On at @ – plurality

Here is my collection of 10 marbles. Is it one thing or 10 things?

In raku you can use either the dollar $ sigil or the at @ sigil to help:

my $marbles = 1..10;       # "one thing"
my @marbles = 1..10;       # "10 things"

The at symbol @ is used to remind us that this is an Array.

We can use dd (data dumper) to show what is going on. The ‘\’ makes the argument ‘x’ sigilless so that our function is studiously neutral:

sub got_what( \x ) { 
    dd x               # data dumper
}

got_what $marbles;     
    #Range $marbles = 1..10

got_what @marbles;     
    #Array @marbles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

An iterator, such as the for operator, will take the desired plurality into account:

sub for_what( \x ) {
    for x -> \item { dd item } 
}

for_what $marbles;           #one thing => 
    #Range $marbles = 1..10

for_what @marbles;           #10 things =>
    #Int @marbles = 1
    #Int @marbles = 2
    #Int @marbles = 3
    #Int @marbles = 4
    #Int @marbles = 5
    #Int @marbles = 6
    #Int @marbles = 7
    #Int @marbles = 8
    #Int @marbles = 9
    #Int @marbles = 10

On at @ – ease of use

So, what happens when you go back and forth? Let’s apply a sigil to the parameter declaration $x in the subroutine signature:

sub for_doll( $x ) {
    for $x -> \item { dd item }
}           
for_doll @marbles;          #one thing =>
    # $[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

Or just do an assignment:

my $scalar = @marbles;
dd $scalar;                 #one thing =>
    #Array $scalar = $[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

That’s an Array wrapped up in a Scalar container (thus the leading $). This process is know as itemizing, since it makes many things into a single item.

Or we can go the the other way:

sub for_amper( @x ) {
    for @x -> \item { dd item }
}
for_amper $marbles;         #ten things =>
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10

And with assignment? Well, not quite so easy. The compiler needs to know (i) should I make and Array of Arrays with $marbles as the first element, or (ii) should I assign each individual element one by one. Here, the programmer must use the pipe ‘|’ symbol if she wishes to flatten the right hand side.

my @array = |$marbles;
dd @array;
    #Array @array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

On at @ – the Single Argument Rule

Now, once up a time in raku-land, it became clear that coders could easily mix up their intentions sometimes passing one argument to an iterator, sometimes many. So, to keep things simple and memorable, the community developed the Single Argument Rule.

The documents say this:

    It is the rule by which the set of parameters passed to an iterator such as for is treated as a single argument, instead of several arguments…

Since what for receives is a single argument, it will be treated as a list of elements to iterate over. The rule of thumb is that if there’s a comma, anything preceding it is an element and the list thus created becomes the single element. That happens in the case of the two arrays separated by a comma which is the third element in the Array we are iterating in this example. In general, quoting the article linked above, the single argument rule … makes for behavior as the programmer would expect.

This rule is equivalent to saying that arguments to iterators will not flatten, will not de-containerize, and will behave as if a single argument has been handled to them, whatever the shape that argument has.

my @a = 1,2; .say for @a, |@a;     # OUTPUT: «[1 2]␤1␤2␤» 
my @a = 1,2; .say for $[@a, |@a ]; # OUTPUT: «[[1 2] 1 2]␤» 

In the second case, the single argument is a single element, since we have itemized the array. There’s an exception to the single argument rule mentioned in the Synopsis: list or arrays with a single element will be flattened:

my @a = 1,2; .say for [[@a ]];     # OUTPUT: «1␤2␤» 

    Authors note: raku is often making new containers and populating them behind the scenes with argument passing, assignment and so on. This exception automates the unwrapping of nested single elements to simply “do what I mean”.

The documents also say some other stuff that personally I find a bit confusing.

I will wrap up this section with two bits of friendly raku advice:

    do not use $ with any kind of list unless you want a suprise!
    while raku also gives us Seq and List types, you want to use Array unless you are an expert

And the rest – percent % and ampersand &

Raku coders also get two more variants to play with, here’s how the four fit together.

| Sigil	| Assumptive Role	| Default Type	| Assignment	| Examples                       |
|:------|:------------------|:--------------|:--------------|:-------------------------------|
| $	    | Mu (no type)	    | Any	        | item	        | Int, Str, Array, Hash          |
| @	    | Positional	    | Array []	    | list	        | List, Array, Range, Buf        |
| %	    | Associative	    | Hash {} <>	| list	        | Hash, Map, Pair                |
| &	    | Callable	        | Callable	    | item	        | Sub, Method, Block, Routine    |

This set of four, along with the sigilless option, provides a rich set of tools to communicate the intent of the coder in the trialog.

I hope that you have enjoyed reading this post as much as I enjoyed writing it. To paraphrase Richard Feynman, to understand a topic properly, you need to blog about it.

As usual, comments and feedback welcome!

~p6steve