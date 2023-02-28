## 解析单行文本

```swift
import _StringProcessing
import RegexBuilder

let word = OneOrMore(.word)
let space = ZeroOrMore(.whitespace)

let wordPattern = Regex {
  space
  Capture { word }
}

let text = "The quick brown fox jumps over the lazy dog"
for match in text.matches(of: wordPattern) {
  let (_, word) = match.output
  print(word)
}
```

输出:

```
The
quick
brown
fox
jumps
over
the
lazy
dog
```

使用 Raku Grammar:

```raku
grammar wordPattern {
    token TOP  { <word>+ % \s+ }
    token word { (\w+) }
}

my $text = "The quick brown fox jumps over the lazy dog";
my $match = wordPattern.parse($text);
.say for $match<word>;
```

## 解析行程数据

有一种行程, 其数据格式如下:

```
Russia
    Vladivostok : 43.131621,131.923828 : 4
    Ulan Ude : 51.841624,107.608101 : 2
    Saint Petersburg : 59.939977,30.315785 : 10
Norway
    Oslo : 59.914289,10.738739 : 2
    Bergen : 60.388533,5.331856 : 4
Ukraine
    Kiev : 50.456001,30.50384 : 3
Switzerland
    Wengen : 46.608265,7.922065 : 3
    Bern : 46.949076,7.448151 : 1
```

例如 Norway 表示国家, Oslo 和 Bergen 是目的地, 59.914289,10.738739 是逗号分割的经纬度, 最后的 2 和 4 是售票数。 

使用 Swift 的 RegexBuilder 写出来大概是下面这样的:

```swift
import _StringProcessing
import RegexBuilder

// \w+
let word = OneOrMore(.word)

// '-'? \d+
// -?\d+
let integer = Regex {
    Optionally { "-" }
    OneOrMore(.digit)
}

// '-'? \d+ [\.\d+]?
// -?\d+(?:\.\d+)?
let num = Regex {
    Optionally { "-" }
    OneOrMore(.digit)
    Optionally {
        Regex {
          "."
          OneOrMore(.digit)
        }
    }
}

// \w+ [ \s \w+ ]*
// \w+(?:\s\w+)*
let name = Regex {
    OneOrMore(.word)
    ZeroOrMore {
        Regex {
            One(.whitespace)
            OneOrMore(.word)
        }
    }
}

let destination = Regex {
    OneOrMore(.whitespace)
    name
    OneOrMore(.whitespace)
    ":"
    OneOrMore(.whitespace)
    num
    ","
    num
    OneOrMore(.whitespace)
    ":"
    OneOrMore(.whitespace)
    integer
    .anchorsMatchLineEndings()
}

let country = Regex {
    name
    .anchorsMatchLineEndings()
    OneOrMore { destination }
}

let tripPattern = Regex {
    Capture {
      OneOrMore { country }
    }
}


let text = """
Russia
    Vladivostok : 43.131621,131.923828 : 4
    Ulan Ude : 51.841624,107.608101 : 2
    Saint Petersburg : 59.939977,30.315785 : 10
Norway
    Oslo : 59.914289,10.738739 : 2
    Bergen : 60.388533,5.331856 : 4
Ukraine
    Kiev : 50.456001,30.50384 : 3
Switzerland
    Wengen : 46.608265,7.922065 : 3
    Bern : 46.949076,7.448151 : 1
"""

// print each trip
for match in text.matches(of: tripPattern) {
  let (_, trip) = match.output
  print(trip)
}
```

几乎等价的 Raku Grammar 写法如下:

```raku
my $text = q:to/END/;
Russia
    Vladivostok : 43.131621,131.923828 : 4
    Ulan Ude : 51.841624,107.608101 : 2
    Saint Petersburg : 59.939977,30.315785 : 10
Norway
    Oslo : 59.914289,10.738739 : 2
    Bergen : 60.388533,5.331856 : 4
Ukraine
    Kiev : 50.456001,30.50384 : 3
Switzerland
    Wengen : 46.608265,7.922065 : 3
    Bern : 46.949076,7.448151 : 1
END

grammar SalesExport {
    token TOP { ^ <country>+ $ }
    token country {
        <name> \n
        <destination>+
    }
    token destination {
        \s+ <name> \s+ ':' \s+
        <lat=.num> ',' <long=.num> \s+ ':' \s+
        <sales=.integer> \n
    }
    token name    { \w+ [ \s \w+ ]*   }
    token num     { '-'? \d+ [\.\d+]? }
    token integer { '-'? \d+          }
}

my $match = SalesExport.parse($text);
.Str.say for $match;
```

## 解析天气预报数据

```swift
import _StringProcessing
import RegexBuilder

let keyval = Regex {
  OneOrMore(.any, .reluctant)
  "="
  OneOrMore(.whitespace)
  OneOrMore(.any)
  ZeroOrMore(.whitespace)
}

let keyvalPattern = Regex {
    OneOrMore { keyval }
    ZeroOrMore(.whitespace)
}

let temp = Regex {
    Optionally { "-" }
    OneOrMore(.digit)
    "."
    OneOrMore(.digit)
}

let observation = Regex {
  OneOrMore(.digit)
  OneOrMore {
    Regex {
      OneOrMore(.whitespace)
      temp
    }
  }
  ZeroOrMore(.whitespace)
}

let observations = Regex {
  keyvalPattern  
  OneOrMore {
    "Obs:"
    ZeroOrMore(.whitespace)
    Capture { OneOrMore { observation } }
  }
}

let input = """
Name= Jan Mayen
Country= NORWAY
Lat=   70.9
Long=    8.7
Height= 10
Start year= 1921
End year= 2009
Obs:
1921 -4.4 -7.1 -6.8 -4.3 -0.8  2.2  4.7  5.8  2.7 -2.0 -2.1 -4.0
1922 -0.9 -1.7 -6.2 -3.7 -1.6  2.9  4.8  6.3  2.7 -0.2 -3.8 -2.6
2008 -2.8 -2.7 -4.6 -1.8  1.1  3.3  6.1  6.9  5.8  1.2 -3.5 -0.8
2009 -2.3 -5.3 -3.2 -1.6  2.0  2.9  6.7  7.2  3.8  0.6 -0.3 -1.3
"""

for match in input.matches(of: observations) {
  let (_, weather) = match.output
  print(weather)
}
```

几乎等价的 Raku Grammar 写法如下:

```raku
#!/usr/bin/env raku
use v6.d;

my $text = q:to/END/;
Name= Jan Mayen
Country= NORWAY
Lat=   70.9
Long=    8.7
Height= 10
Start year= 1921
End year= 2009
Obs:
1921 -4.4 -7.1 -6.8 -4.3 -0.8  2.2  4.7  5.8  2.7 -2.0 -2.1 -4.0
1922 -0.9 -1.7 -6.2 -3.7 -1.6  2.9  4.8  6.3  2.7 -0.2 -3.8 -2.6
2008 -2.8 -2.7 -4.6 -1.8  1.1  3.3  6.1  6.9  5.8  1.2 -3.5 -0.8
2009 -2.3 -5.3 -3.2 -1.6  2.0  2.9  6.7  7.2  3.8  0.6 -0.3 -1.3
END

grammar StationDataParser {
    token TOP          { ^ <keyval>+ <observations> $             }
    rule  keyval       { $<key>=[<-[=]>+] '=' $<val>=[\N+]        }
    token observations { 'Obs:' \h* \n <observation>+             }
    token observation  { $<year>=[\d+] \h* <temp>+ %% [\h*] \n    }
    token temp         { '-'? \d+ \. \d+                          }
}

my $match = StationDataParser.parse($text);
dd $match;
```

## 解析交易数据

```raku
my $text = q:to/END/;
CREDIT  03/02/2022  Payroll from employer       $200.23
CREDIT  03/03/2022  Suspect A                   $2,000,000.00
DEBIT   03/03/2022  Ted's Pet Rock Sanctuary    $2,000,000.00
DEBIT   03/05/2022  Doug's Dugout Dogs          $33.27
END

grammar TransactionGrammar {
    token TOP              { <transaction>+ %% \n*                             }
    rule  transaction      { <payment> <date> <description> <cost>             }
    token payment          { 'CREDIT' | 'DEBIT'                                }
    token date             { <digit-sequence>+ % '/'                           }
    token description      { [<-[\s]>+]+ % \s                                  }
    token cost             { <currency-sign> <currency-number>                 }
    token digit-sequence   { \d+                                               }
    token currency-sign    { '$'                                               }
    token currency-number  { <digit-sequence>+ % <[.,]>                        }
}

my $match = TransactionGrammar.parse($text);
.say for $match;
```

## 解析欧元

```swift
import _StringProcessing
import RegexBuilder

let statementPattern = Regex {
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
  OneOrMore(.whitespace)
  Capture {
    Regex {
      Repeat(count: 2) {
        One(.digit)
      }
      Repeat(count: 2) {
        One(.digit)
      }
      Repeat(count: 4) {
        One(.digit)
      }
    }
  }
  OneOrMore(.whitespace)
  Capture {
    Regex {
      OneOrMore {
        CharacterClass(
          .word,
          .whitespace
        )
      }
      One(.word)
    }
  }
  OneOrMore(.whitespace)
  Capture {
    Regex {
      ChoiceOf {
        "$"
        "£"
      }
      OneOrMore(.digit)
      "."
      Repeat(count: 2) {
        One(.digit)
      }
    }
  }
}

let statement = """
  CREDIT    04062020    PayPal transfer    $4.99
  CREDIT    04032020    Payroll            $69.73
  DEBIT     04022020    ACH transfer       $38.25
  DEBIT     03242020    IRS tax payment    £52249.98
"""

for match in statement.matches(of: statementPattern) {
  let (_, kind, date, description, amount) = match.output
  print(kind, date, description, amount)
}
```

## 总结

对于简单的

Swift 支持 Linux/Mac/iOS/iPadOS, RegexBuilder 是 Swfit 5.7 引进的新特性, 上面的 Swift 代码是跑在 Docker 中的, 使用了 nightly 版本的 Swift 构建:

```bash
docker pull swiftlang/swift:nightly-main-centos7
docker run -d swiftlang/swift:nightly-main-centos7

swift --version
Swift version 5.8-dev (LLVM b2416e1165ab97c, Swift 965a54f037cfa76)
Target: x86_64-unknown-linux-gnu
```