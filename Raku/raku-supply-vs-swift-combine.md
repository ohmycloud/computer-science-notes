# Swift Combine

Combine 框架是 Apple 的声明式异步处理框架。

> In Apple’s own words: “The Combine framework provides a declarative approach for
how your app processes events. Rather than potentially implementing multiple delegate
callbacks or completion handler closures, you can create a single processing chain for a
given event source. Each part of the chain is a Combine operator that performs a distinct
action on the elements received from the previous step.”

# Raku Supply

Raku 中内置了异步处理, 即 Supply。

> Asynchronous data stream with multiple subscribers

A supply is a thread-safe, asynchronous data stream like a Channel, but it can have multiple subscribers (taps) that all get the same values flowing through the supply.

It is a thread-safe implementation of the Observer Pattern, and central to supporting reactive programming in Raku.

# Swift Combine vs. Raku Supply

下面的 Swift 代码来自《Combine Asynchronous Programming with Swift》第三版, Combine 框架实现了很多转换操作符(transforming operators), 比 Raku 自带的异步转换函数还要丰富。

我们先看一看响应式流处理在 Swift 和 Raku 中分别是什么样的:

```swift
["A", "B", "C", "D", "E"].publisher
  .sink(receiveCompletion: { print($0) },
        receiveValue: { print($0) })
  .store(in: &subscriptions)
```

上面的代码使用 `publisher` 方法从数组上创建一个 `Publisher`, `sink` 方法用来订阅, 它可以接收两个参数:

`receiveCompletion` 和 `receiveValue`, 这两个参数的数据类型都是闭包。

等价的 Raku 代码如下, `from-list` 从列表 `'A' .. 'E'` 创建一个 **Supply**:

```raku
my Supply $s = Supply.from-list('A' .. 'E');

$s.tap(
    &say,
    done => { say "finished" },
    quit => { say "quit"     }
);
```

`tap` 子例程相当于 Swift Combine 框架中的 `sink` 方法, 它创建了一个订阅(subscription)。第一个位置参数是一块儿代码, 每当发起 `emit` 调用而有一个可用的新值时, 第一个位置参数的代码块儿就会执行。

了解了 Swift Combine 和 Raku Supply 的基本知识之后, 我们下面使用 Raku 来实现 Swift Combine 框架中的部分转换操作符。

- first

Combine 中的 `first` 转换函数接收一个 closure, 即返回第一个满足条件的值:

```swift
let numbers = (1...9).publisher

numbers
  .first(where: { $0 % 2 == 0 })
  .sink(receiveCompletion: { print("Completed with: \($0)") },
        receiveValue: { print($0) })
  .store(in: &subscriptions)
```

Raku Supply 中的 `first` 子例程可以接收一个 WhateverCode:

```raku
my Supply $supply = Supply.from-list(1..9);
my Supply $first = $supply.first(* % 2 == 0);

$first.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);
```

输出:

```
2
finished
```

- collect

Swift Combine 框架中的 `collect` 操作符提供了一种便捷的方式把单独的值转换成单个数组:

```swift
["A", "B", "C", "D", "E"].publisher
.collect(2)
.sink(receiveCompletion: { print($0) },
      receiveValue: { print($0) })
.store(in: &subscriptions)
```

Raku 的 Supply 没有 collect 子例程, 但是有一个 `rotor` 子例程:

```raku
my Supply $supply = Supply.from-list('A' .. 'E').rotor(2 , :partial);

$supply.tap(
    &say,
    done => { say "finished" },
    quit => { say "quit"     }
);
```

输出:

```
[A B]
[C D]
[E]
finished
```

- map

Swift Combine 框架中的 `map` 就像标准库中的 `map` 一样, 只不过 Combine 中的 map 操作的是来自 Publisher 发出的值:

```swift
[1,2,3].publisher
  .map { $0 * 2 }
  .sink(receiveCompletion: { print($0) },
        receiveValue: { print($0) })
  .store(in: &subscriptions)
```

在上面的代码中, `map` 接收一个闭包, 这个闭包进行的操作是把传入的值加倍。

Raku 中的 `map` 接收一个闭包:

```raku
my Supply $supply  = Supply.from-list(1..3);
my Supply $doubled = $supply.map: -> $value { $value * 2 };

$doubled.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);
```

输出:

```
2
4
6
finished
```

此外, 上面的 map 还能写成这样:

```raku
$supply.map(* * 2)
```

- flatMap

在 Swift Combine 中, flatMap 操作符把多个上游的 Publisher 展平成单个下游 Publisher。或者, 说得更具体一点, flatMap 操作符把这些 Publisher 发出的元素展平了:

```swift
func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
  Just(
    codes
      .compactMap { code in
        guard (32...255).contains(code) else { return nil }
        return String(UnicodeScalar(code) ?? " ")
      }.joined()
  ).eraseToAnyPublisher()
}

[72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
.publisher
.collect()
.flatMap(decode)
.sink(receiveValue: { print($0) })
.store(in: &subscriptions)
```

`flatMap` 返回的 Publisher 的类型通常和它接收的上游 Publisher 的类型不同。

Raku 的 Supply 中没有 flatMap 子例程, 下面的代码同时使用了 map 和 reduce 得到和 Swift Combine 的 flatMap 同样的输出结果:

```raku
my Supply $supply = Supply.from-list: [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33];
my $flat-supply = $supply.map(&decode).reduce({$^a ~ $^b });

$flat-supply.tap(
        &say,
        done => { say 'finished' },
        quit => { say 'quit'     }
);

sub decode($x) {
  chr($x)
}
```

输出:

```
Hello, World!
finished
```

- mapping key paths

`map` 运算符还可以使用 key paths 把值映射到属性里面:

```swift
let publisher = PassthroughSubject<Coordinate, Never>()

publisher
  .map(\.x, \.y)
  .sink(receiveCompletion: { print($0) },
        receiveValue: {x, y in
          print("The coordinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y))
        })
  .store(in: &subscriptions)

  publisher.send(Coordinate(x: 10, y: -8))
  publisher.send(Coordinate(x:  0, y:  5))
```

Raku 中是没有 Swift 中的 key path 概念的, 但是我尝试模拟了一下:

```raku
class Coordinate {
    has $.x;
    has $.y;

    # 计算点所在的象限
    method quadrantOf(--> Int) {
        with self {
            when .x > 0 && .y > 0 { 1 }
            when .x < 0 && .y > 0 { 2 }
            when .x < 0 && .y < 0 { 3 }
            when .x > 0 && .y < 0 { 4 }
            -1
        }
    }

    # 重写 gist 方法, 个性化打印
    method gist() {
        return "The coordinate at ({self.x}, {self.y}) is in quadrant " ~ self.quadrantOf()
    }
}

my Supplier $supplier = Supplier.new;
my Supply $supply = $supplier.Supply;

$supply.tap({ say $_ });
$supplier.emit(Coordinate.new(x =>  10, y =>  8));
$supplier.emit(Coordinate.new(x => -10, y =>  8));
$supplier.emit(Coordinate.new(x => -10, y => -8));
$supplier.emit(Coordinate.new(x =>  10, y => -8));
$supplier.emit(Coordinate.new(x =>   0, y =>  5));
$supplier.emit(Coordinate.new(x =>   0, y =>  0));
```

- compactMap

`compactMap` 在进行 map 操作的同时会过滤掉 Nil 值:

```swift
let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher

strings
  .compactMap { Float($0) }
  .sink(receiveValue: {
    print($0)
  })
  .store(in: &subscriptions)
)
```

上面的 Swift 代码使用 `compactMap` 尝试从每个单独的字符串初始化一个 `Float` 值。如果 `Float` 的初始化构造器不知道如何转换所提供的字符串, 就会返回 `nil`。那些 `nil` 值会被 `compactMap` 操作符自动过滤掉。

Raku 中没有 compactMap, 但是可以使用 map 和 `Empty` 实现类似的效果:

```raku
my @strings = ["a", "1.24", "3", "def", "45", "0.23"];
my Supply $supply = Supply.from-list(@strings);
my Supply $compact = $supply.map(-> $value {
  try { Num($value) }
  $! ?? Empty !! Num($value)
 }).grep(Num);

$compact.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'done'     }
);
```

但是最后还需要用 `grep` 过滤掉空的列表。Supply 中的 map 和标准库中的 map 表现不一致。

- filter

`filter` 函数接收一个闭包, 这个闭包返回一个 Bool 值。`filter` 只把匹配了所提供的断言的值向下传递:

```swift
let numbers = (1...10).publisher

numbers
  .filter { $0.isMultiple(of: 3) }
  .sink(receiveValue: { n in
    print("\(n) is a multiple of 3!")
  })
  .store(in: &subscriptions)
```

在 Raku 中没有 `filter`, 而是叫 `grep`, 它可以接收一个 WhateverCode:

```raku
my Supplier $supplier = Supplier.new;
my Supply $all = $supplier.Supply;
my Supply $multiple-of-three = $all.grep(* % 3 == 0);

$multiple-of-three.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'done'     }
);

$supplier.emit($_) for 1..10;
$supplier.done;
```

- dropFirst

`dropFirst` 运算符接收一个 `count` 参数, 忽略 Publisher 发出的头几个值:

```swift
let numbers = (1...10).publisher

numbers
  .dropFirst(8)
  .sink(receiveValue: { print($0) })
  .store(in: &subscriptions)
```

Raku 中使用 `skip` 跳过前 N 个值:

```raku
my Supply $supply = Supply.from-list(1..10);
my Supply $drop = $supply.skip(8);

$drop.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);
```

- merge

在 Swift Combine 框架中, `merge` 用于合并两个 Publisher:

```swift
let publisher1 = PassthroughSubject<Int, Never>()
let publisher2 = PassthroughSubject<Int, Never>()

publisher1
  .merge(with: publisher2)
  .sink(
    receiveCompletion: { _ in print("Completed") },
    receiveValue: { print($0) }
  )
  .store(in: &subscriptions)

publisher1.send(1)
publisher1.send(2)
publisher2.send(3)
publisher1.send(4)
publisher2.send(5)

publisher1.send(completion: .finished)
publisher2.send(completion: .finished)
```

Raku 中也有个叫 `merge` 的子例程, 这个子里程接收两个 Supply, 合并完之后返回的也是 Supply:

```raku
my Supplier $supplier1 = Supplier.new;
my Supplier $supplier2 = Supplier.new;

my Supply $publisher1 = $supplier1.Supply;
my Supply $publisher2 = $supplier2.Supply;
my Supply $merged     = $publisher1.merge($publisher2);

$merged.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);

$supplier1.emit(1);
$supplier1.emit(2);
$supplier2.emit(3);
$supplier1.emit(4);
$supplier2.emit(5);

$supplier1.done;
$supplier2.done;
```

- combineLatest

`combineLatest` 运算符可以组合不同的 Publisher。它也可以让你组合不同值类型的 Publisher, 这相当有用。  
每当 Publisher 中的任意一个发出值时, `combineLatest` 就会发出一个元组, 这个元组中的值是所有 Publisher 中发出的最新值:

```swift
let publisher1 = PassthroughSubject<Int, Never>()
let publisher2 = PassthroughSubject<String, Never>()

publisher1
  .combineLatest(publisher2)
  .sink(
    receiveCompletion: { _ in print("Completed") },
    receiveValue: { print("P1: \($0), P2: \($1)") }
  )
  .store(in: &subscriptions)

publisher1.send(1)
publisher1.send(2)
publisher2.send("a")
publisher2.send("b")
publisher1.send(3)
publisher2.send("c")

publisher1.send(completion: .finished)
publisher2.send(completion: .finished)
```

Raku 中与 combineLatest 类似的子例程是 `zip-latest`:

```raku
my Supplier $supplier1 = Supplier.new;
my Supplier $supplier2 = Supplier.new;

my Supply $publisher1 = $supplier1.Supply;
my Supply $publisher2 = $supplier2.Supply;
my Supply $merged     = $publisher1.zip-latest($publisher2);

$merged.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);

$supplier1.emit(1);
$supplier1.emit(2);
$supplier2.emit("a");
$supplier2.emit("b");
$supplier1.emit(3);
$supplier2.emit("c");

$supplier1.done;
$supplier2.done;
```

- removeDuplicates

在 Swift Combine 中, `removeDuplicates` 用于移除 Publisher 中重复的值:

```swift
let words = "hey hey there! want to listen to mister mister ?"
  .components(separatedBy: " ")
  .publisher

words
  .removeDuplicates()
  .sink(receiveValue: { print($0) })
  .store(in: &subscriptions)
```

Raku 中 `unique` 子例程的作用类似于 Swift Combine 框架中的 `removeDuplicates` 函数:

```raku
my $words = "hey hey there! want to listen to mister mister ?".words;
my Supply $supply = Supply.from-list($words);
my Supply $unique = $supply.unique(:as(&lc));

$unique.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit' }
);
```

其中 unique 接收一个 Colon Pair, `as` 作为键, 子例程 `&lc` 作为值。 

- scan

`scan` 会把上游 Publisher 发出的当前值(`current`)提供给闭包, 与当前值一块儿提供给闭包的还有闭包返回的上一个值(`latest`):

```swift
var dailyGainLoss: Int { .random(in: -10...10) }

let august2019 = (0..<22)
  .map { _ in dailyGainLoss }
  .publisher

august2019.scan(50) { latest, current in
  max(0, latest + current)
}
.sink(receiveValue: { _ in })
.store(in: &subscriptions)
```

Raku 中的 `produce` 子例程相当于 Swift Combine 框架中的 `scan`:

```raku
my @dailyGainLoss = (-10..10).pick(21);
my Supply $supply = Supply.from-list(@dailyGainLoss);
my Supply $produce = $supply.produce({ max(0, $^a + $^b) }).map(-> $value { $value + 50});
$produce.tap(
    &say,
    done => { say 'finished' },
    quit => {say 'quit'      }
);
```

- zip

这个操作符在相同的索引中发出成对的值的元组。它等待每个 Publisher 发出一个条目(item)，然后在所有 Publisher 都在当前索引中发出一个值之后，发出单个条目元组。

```swift
let publisher1 = PassthroughSubject<Int, Never>()
let publisher2 = PassthroughSubject<String, Never>()

publisher1
  .zip(publisher2)
  .sink(
    receiveCompletion: { _ in print("Completed") },
    receiveValue: { print("P1: \($0), P2: \($1)") }
  )
  .store(in: &subscriptions)

publisher1.send(1)
publisher1.send(2)
publisher2.send("a")
publisher2.send("b")
publisher1.send(3)
publisher2.send("c")
publisher2.send("d")

publisher1.send(completion: .finished)
publisher2.send(completion: .finished)
```

Raku 中也有个叫 `zip` 的子例程:

```raku
my Supplier $supplier1 = Supplier.new;
my Supplier $supplier2 = Supplier.new;

my Supply $publisher1 = $supplier1.Supply;
my Supply $publisher2 = $supplier2.Supply;
my Supply $zipped     = $publisher1.zip($publisher2);

$zipped.tap(
    &say,
    done => { say 'finished' },
    quit => { say 'quit'     }
);

$supplier1.emit(1);
$supplier1.emit(2);
$supplier2.emit("a");
$supplier2.emit("b");
$supplier1.emit(3);
$supplier2.emit("c");

$supplier1.done;
$supplier2.done;
```