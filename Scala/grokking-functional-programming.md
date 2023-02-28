Pure function

- It returns only a single value.
- It calculates the return value based only on its arguments.
- It doesn’t mutate any existing values.

Functional programming is programming using pure functions that manipulate immutable values

# 第五章 Sequential programs

本章会学到的知识:

- 使用 `flatten` 处理列表的列表
- 使用 `flatMap` 代替 `for` 循环来编写顺序程序
- 使用 `for` 列表解析来编写可读性更好的顺序程序
- 在 `for` 列表解析中使用条件
- 了解更多拥有 `flatMap` 的类型

## Writing pipeline-based algorithms

```scala
case class Book(title: String, authors: List[String])

val books = List(
    Book("FP in Scala", List("Chiusano", "Bjarnason")),
    Book("The Hobbit", List("Tolkien")),
    Book("Modern Java in Action", List("Urma", "Fusco", "Mycroft"))
)
```

我们的任务是计算 title 中含有单词 "Scala" 的个数:

```scala
books
  .map(_.title)
  .filter(_.contains("Scala"))
  .size
```

这等价于:

```scala
books
  .map(book => book.title)
  .filter(title => title.contains("Scala"))
  .size
```

## Composing larger programs from smaller pieces

我们拥有一个书籍列表:

```scala
case class Book(title: String, authors: List[String])
val books = List(
  Book("FP in Scala", List("Chiusano", "Bjarnason")),
  Book("The Hobbit", List("Tolkien"))
)
```

编写一个函数, 这个函数返回给定作者的书籍改编(电影)的列表(现在只支持 Tolkien):

```scala
case class Movie(title: String)

def bookAdaptations(author: String): List[Movie] = {
    if (author == "Tolkien")
      List(Movie("An Unexpected Journey"),
           Movie("The Desolation of Smaug"))
    else List.empty
}
```

我们的任务是根据书籍返回电影推荐:

```scala
def recommendationFeed(books: List[Book]) = {

}
```

```scala
def recommendBooks(friend: String): List[Book] = {
  val scala = List(
    Book("FP in Scala", List("Chiusano", "Bjarnason")),
    Book("Get Programming with Scala", List("Sfregola")))
  val fiction = List(
    Book("Harry Potter", List("Rowling")),
    Book("The Lord of the Rings", List("Tolkien")))

  if(friend == "Alice") scala
  else if(friend == "Bob") fiction
  else List.empty
}
```

假设我们有几个朋友, 计算他们推荐的书籍列表:

```scala
val friends = List("Alice", "Bob", "Charlie")
val recommendations = ???
```

# 第七章 Requirements as types

本章会学到的知识:

- 用不可变数据建模以减少错误
- 把需求建模为不可变数据
- 用编译器发现需求中的问题
- 如何确保你的逻辑总是在有效数据上执行

我们将实现一个音乐艺术家目录，它将帮助我们按流派找到艺术家、他们的位置和活动年份。
我们将对艺术家进行建模。每个艺术家将有一个名字、一个主要流派和一个来源。

```scala
case class Artist(name: String, genre: String, origin: String)
```

需求: 音乐艺术家目录

1. The function should be able to search through a list of music artists.
2. Each search should support a different combination of conditions: by genre, by
   origin (location), and by period in which they were active.
3. Each music artist has a name, genre, origin, year their career started, and a year
   they stopped performing (if they are not still active).

```scala
case class Artist(
    name: String,
    genre: String,
    origin: String,
    yearsActiveStart: Int,
    isActive: Boolean,
    yearsActiveEnd: Int
)

def searchArtists(
    artists: List[Artist],
    genres: List[String],
    locations: List[String],
    searchByActiveYears: Boolean,
    activeAfter: Int,
    activeBefore: Int
): List[Artist] = 
  artists.filter(artist =>
    (genres.isEmpty || genres.contains(artist.genre)) &&
    (locations.isEmpty || locations.contains(artist.origin)) &&
    (!searchByActiveYears || (
        (artist.isActive || artist.yearsActiveEnd >= activeAfter) &&
        (artist.yearsActiveStart <= activeBefore)))  
    )

val artists = List(
  Artist("Metallica", "Heavy Metal", "U.S.", 1981, true, 0),
  Artist("Led Zeppelin", "Hard Rock", "England", 1968, false, 1980),
  Artist("Bee Gees", "Pop", "England", 1958, false, 2003)
)
```

What if I told you that the way we modeled the Artist is the reason why
implementing searchArtists was so difficult? Now that you’ve felt the
pain of implementing this function, let’s see how the functional approach
to modeling data could have made the job easier

## Newtypes protect against misplaced parameters

Rust 中也有 newtype 的概念, 在编译时, 编译器会帮我们找出数据建模的错误。

newtype, also known as a zero-cost wrapper. Instead of using primitive
types like String, we wrap it in a named type.

```scala
opaque type Location = String

object Location extends App {
    def apply(value: String): Location = value
    extension(a: Location) def name: String = a

    val us: Location = Location("U.S.")
    val wontCompile: Location = "U.S."
}
```

模式匹配练习:

Your task is to implement a function that gets an artist and the current
year and returns the number of years this artist was active

```scala
object Location {
    opaque type Location = String
    def apply(value: String): Location = value
    extension(a: Location) def name: String = a
}

enum MusicGenre {
    case HeavyMetal
    case Pop
    case HardRock
}

enum YearsActive {
    case StillActive(since: Int)
    case ActiveBetween(start: Int, end: Int)
}

case class Artist(name: String, genre: MusicGenre, origin: Location, yearsActive: YearsActive)

def activeLength(artist: Artist, currentYear: Int): Int = {
    artist.yearsActive match {
        case StillActive(since)        => currentYear - since
        case ActiveBetween(start, end) => end - start
    }
}
```

# 第八章 IO as values

```scala
def castTheDieImpure(): Int = {
    static int castTheDieImpure() {
        System.out.println("The die is cast");
        Random rand = new Random();
        return rand.nextInt(6) + 1;
    }
}
```