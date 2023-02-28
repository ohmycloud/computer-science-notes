Swift dot syntax

// https://www.swiftbysundell.com/tips/using-dot-syntax-for-static-properties-and-initializers/
Dot syntax is one of my favorite features of Swift. What's really cool is that it's not only for enums, any static method or property can be used with dot syntax - even initializers! Perfect for convenience APIs and default parameters.

```swift
public enum RepeatMode {
    case times(Int)
    case forever
}

public extension RepeatMode {
    static var never: RepeatMode {
        return .times(0)
    }

    static var once: RepeatMode {
        return .times(1)
    }
}

view.perform(animation, repeated: .once)

// To make default parameters more compact, you can even use init with dot syntax

class ImageLoader {
    init(cache: Cache = .init(), decoder: ImageDecoder = .init()) {
        ...
    }
}
```

// https://www.infoq.com/news/2021/05/swift-5-4-released/

[Swift 5.4 also extends so-called "leading dot syntax"](https://github.com/apple/swift-evolution/blob/main/proposals/0287-implicit-member-chains.md) to chains of member references. Leading dot syntax allows to omit type information that can be inferred by the context, as in the following snippet:

```swift
view.backgroundColor = .systemBackground
//-- same as view.backgroundColor = UIColor.systemBackground
```

Until now, this syntax was only allowed to access static members. Now, you can chain multiple member accesses, including non-static members:

```swift
let milky: UIColor = .white.withAlphaComponent(0.5)
let milky2: UIColor = .init(named: "white")!.withAlphaComponent(0.5)
let milkyChance: UIColor? = .init(named: "white")?.withAlphaComponent(0.5)
```

// https://github.com/apple/swift-evolution/blob/main/proposals/0287-implicit-member-chains.md

```swift
class C {
    static let zero = C(0)
    var x: Int

    init(_ x: Int) {
        self.x = x
    }
}

func f(_ c: C) {
    print(c.x)
}

f(.zero) // prints '0'
```

```swift
extension C {
    var incremented: C {
        return C(self.x + 1)
    }
}

f(.zero.incremented)
```

This allows for the omission of repetitive type information in contexts where the type information is already obvious to the reader:

```swift
view.backgroundColor = .systemBackground
```

# backslash dot \.

// https://stackoverflow.com/questions/52543502/swift-what-does-backslash-dot-mean

// https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#grammar_key-path-expression

`\.property` 和 `\SomeType.property` 写法上是一样的, Swift 通常推断出你在使用的 root type。

```swift
struct SomeStructure {
    var someValue: Int
}

let s = SomeStructure(someValue: 12)
let pathToProperty = \SomeStructure.someValue

// to access a value using a key path, pass the key path to the `subscript(keyPath:)` subscript, which is available on all types.
let value = s[keyPath: pathToProperty]
print(value)
```

在类型推断可以决定隐式类型的语境中, 类型名可以省略。下面的代码使用 `\.someProperty` 代替 `\SomeClass.someProperty`:

```swift
class SomeClass: NSObject {
    @objc dynamic var someProperty: Int
    init(someProperty: Int) {
        self.someProperty = someProperty
    }
}

let c = SomeClass(someProperty: 10)
c.observe(\.someProperty) { object, change in
     // ...
}
```

path 可以引用 `self` 创建 identity key path(`\.self`)。identity key path 引用整个实例, 所以你可以用它来访问和修改存储在变量中的所有数据, 只用一步:

```swift
var compoundValue = (a: 1, b: 2)

// 等价于 compoundValue = (a: 10, b: 20)
compoundValue[keyPath: \.self] = (a: 10, b: 20)
```

path 可以包含多个由点号分隔的属性名, 以引用属性的属性值。下面的代码使用 key path 表达式 `\OuterStructure.outer.someValue` 来访问 `OuterStructure` 类型的 `outer` 属性:

```swift
struct OuterStructure {
    var outer: SomeStructure
    init(someValue: Int) {
        self.outer = SomeStructure(someValue: someValue)
    }
}

let nested = OuterStructure(someValue: 24)
let nestedKeyPath = \OuterStructure.outer.someValue

let nestedValue = nested[keyPath: nestedKeyPath]
print(nestedValue)
```

path 可以包含使用方括号的 subscripts, 只要 subscripts 的参数类型符合(conform to) `Hashable` 协议。下面的代码在 key path 中使用了 subscripts 来访问数组的第二个元素:

```swift
let greetings = ["hello", "hola", "bonjour", "你好"]
let myGreeting = greetings[keyPath: \[String].[1]]
// let myGreeting = greetings[keyPath: \.[1]]
```

```swift
var index = 2
let path = \[String].[index]
let fn: ([String]) -> String = { strings in strings[index] }

print(greetings[keyPath: path]) // bonjour
print(fn(greetings))            // bonjour

// 把 `index` 设置为一个新值不影响 `path`
index += 1
print(greetings[keyPath: path]) // bonjour

// 因为 `fn` closes over `index`, 它会使用新值
print(fn(greetings))            // 你好
```

path 可以使用 optional chaining 和 forced unwrapping。下面的代码在 key path 中使用 optional chaining 来访问 optional 字符串中的属性:

```swift
let firstGreeting: String? = greetings.first
print(firstGreeting?.count as Any) // Optional(5)

// Do the same thing using a key path
let count = greetings[keyPath: \[String].first?.count]
print(count as Any)                // Optional(5)
```

你可以混合和匹配 key path 的 components 来访问某个类型中深度嵌套的值。下面的代码使用 key path 表达式访问一组字典中的不同值和属性:

```swift
let nums = ["prime": [2, 3, 5, 7, 11, 13, 17],
            "triangular": [1, 3, 6, 10, 15, 21, 28],
            "hexagonal": [1, 6, 15, 28, 45, 66, 91]
           ]

let optionalInts = nums[keyPath: \[String: [Int]].["prime"]] as Any
let two          = nums[keyPath: \[String: [Int]].["prime"]![0]]
let seven        = nums[keyPath: \[String: [Int]].["triangular"]!.count]
let sixtyfour    = nums[keyPath: \[String: [Int]].["hexagonal"]!.count.bitWidth]
```

You can use a key path expression in contexts where you would normally provide a function or closure.

特别地, 你可以这样使用 key path, 它的根类型是 `SomeType`, 它的 path 生成一个 `Value` 类型的值, 来代替 `(SomeType) -> Value` 类型的函数或闭包:

```swift
struct Task {
    var description: String
    var completed: Bool
}

var toDoList = [
    Task(description: "练习乒乓球", completed: false),
    Task(description: "买一套海盗装", completed: true),
    Task(description: "秋天去波士顿旅行", completed: false),
]

// 下面这两种写法是等价的
let descriptions  = toDoList.filter(\.completed).map(\.description)
let descriptions2 = toDoList.filter { $0.completed }.map { $0.description }
```

Any side effects of a key path expression are evaluated only at the point where the expression is evaluated. For example, if you make a function call inside a subscript in a key path expression, the function is called only once as part of evaluating the expression, not every time the key path is used.

```swift
func makeIndex() -> Int {
    print("Made an index")
    return 0
}

// The line below calls makeIndex()
let taskKeyPath = \[Task][makeIndex()]

// Using taskKeyPath doesn't call makeIndex() again
let someTask = toDoList[keyPath: taskKeyPath]
```