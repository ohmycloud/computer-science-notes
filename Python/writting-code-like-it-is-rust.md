我几年前开始使用 Rust 进行编程，它逐渐改变了我在其他编程语言中设计程序的方式，尤其是在 Python 中。在开始使用 Rust 之前，我通常以一种非常动态和松散的方式编写 Python 代码，没有类型提示，在各处传递和返回字典，偶尔还会回到“字符串类型”的接口。然而，在经历了 Rust 类型系统的严格性，并注意到它“通过构建”可以防止的所有问题时，每当我回到 Python 时，并没有获得相同的保证时，我突然变得非常焦虑。

要明确一点，“保证”在这里并不是指内存安全（Python 本身在这方面是相对安全的），而是“完整性”——设计 API 时，使其很难或者根本不可能被误用，从而防止未定义的行为和各种错误。在 Rust 中，错误使用的接口通常会导致编译错误。在 Python 中，你仍然可以执行这样的不正确程序，但如果你使用类型检查器（比如 pyright）或带有类型分析器的 IDE（比如 PyCharm），你仍然可以获得类似的快速反馈，指出可能存在的问题。

最终，我开始在我的 Python 程序中采用了一些来自 Rust 的概念。基本上可以归结为两件事——尽量使用类型提示，以及坚持经典的“使非法状态不可表示”的原则。我尝试在需要维护一段时间的程序以及一次性实用脚本中都这样做。主要是因为根据我的经验，后者往往变成前者:) 在我的经验中，这种方法导致了更容易理解和更易于修改的程序。

在本文中，我将展示一些将这些模式应用于 Python 程序的示例。这并不是什么高深的科学，但我仍然觉得记录下来可能会有用。

注意：本文包含许多关于编写 Python 代码的观点。我不想在每个句子后都加上“在我看来”，所以请将本文中的一切都视为我对这个问题的看法，而不是试图宣扬一些普遍真理:) 另外，我并不主张所提出的想法都是在 Rust 中发明的，它们当然也在其他语言中使用。

```python
def find_item(records, check):
````

我对函数签名本身一无所知。records 是一个列表、字典还是数据库连接？check 是一个布尔值，还是一个函数？这个函数返回什么？如果出现错误会发生什么，它会引发异常还是返回 `None`？要找到这些问题的答案，我要么必须去阅读函数体（并经常递归阅读它调用的其他函数的函数体 – 这相当烦人），要么阅读其文档（如果有的话）。尽管文档可能包含有关函数的功能的有用信息，但不应该也需要使用它来记录前面的问题的答案。许多问题可以通过内置机制来回答——类型提示。

```python
def find_item(
  records: List[Item],
  check: Callable[[Item], bool]
) -> Optional[Item]:
```

写出这个签名花费了我更多的时间吗？是的。这是个问题吗？不是，除非我的编码速度受到每分钟写入字符数的限制，而实际上并没有发生这种情况。明确写出类型强迫我思考函数提供的实际接口是什么，以及如何使它尽可能严格，以使调用者难以以错误的方式使用它。通过上面的签名，我可以对如何使用函数，传递什么参数以及可以期望从中返回什么有一个相当好的了解。此外，与文档注释不同，当代码发生变化时，文档注释很容易过时，当我更改类型并没有更新函数的调用者时，类型检查器会提醒我。而且，如果我对 `Item` 是什么感兴趣，我只需使用“转到定义”功能，立即查看该类型的外观。

现在，我在这方面并不是绝对主义者，如果需要五个嵌套的类型提示来描述一个单一的参数，我通常会放弃，使用一个更简单但不太精确的类型。根据我的经验，这种情况并不经常发生。而且，如果确实发生，这实际上可能是代码存在问题的信号 – 如果函数参数可以是一个数字、一个字符串元组或一个将字符串映射到整数的字典，这可能表明你可能想要进行重构并简化它。

## dataclass 替代元组或字典

使用类型提示只是一方面，它仅仅描述了函数的接口是什么。第二步是实际上使这些接口尽可能精确和“锁定”。一个典型的例子是从函数返回多个值（或一个复杂值）。懒惰和快速的方法是返回一个元组：

```python
def find_person(...) -> Tuple[str, str, int]:
````

很好，我们知道我们正在返回三个值。它们是什么？第一个字符串是人的名字吗？第二个字符串是姓氏吗？那个数字是什么？是年龄吗？在某个列表中的位置吗？社会保障号码吗？这种类型是不透明的，除非你查看函数体，否则你不知道这里发生了什么。

下一步“改进”这个问题的方法可能是返回一个字典：

```python
def find_person(...) -> Dict[str, Any]:
    ...
    return {
        "name": ...,
        "city": ...,
        "age": ...
    }
```

现在我们实际上知道了返回的各个属性是什么，但我们再次不得不检查函数体才能找到。从某种意义上说，类型变得更糟，因为现在我们甚至不知道各个属性的数量和类型。此外，当这个函数发生变化并且返回的字典中的键被重命名或删除时，使用类型检查器就没有简单的方法找到，因此通常必须通过一种非常手动和烦人的运行-崩溃-修改代码周期来更改其调用者。

正确的解决方案是返回一个具有附加类型的具有命名参数的强类型对象。在 Python 中，这意味着我们必须创建一个类。我怀疑元组和字典在这些情况下经常被使用，因为这比定义一个类（并为其命名），创建带参数的构造函数，将参数存储到字段等要容易得多。自 Python 3.7 起（并且在之前有一个包 polyfill 的情况下），有一个更快的解决方案——数据类。

```python
@dataclasses.dataclass
class City:
    name: str
    zip_code: int


@dataclasses.dataclass
class Person:
    name: str
    city: City
    age: int


def find_person(...) -> Person:
```

你仍然必须为创建的类想一个名字，但除此之外，这几乎是尽可能简洁的方式，而且你获得了所有属性的类型注释。

有了这个数据类，我对函数返回值有了明确的描述。当我调用这个函数并使用返回值时，IDE 的自动完成将显示出其属性的名称和类型。这可能听起来很琐碎，但对我来说是一项巨大的生产力好处。此外，当代码被重构并且属性发生变化时，我的 IDE 和类型检查器会提醒我并显示所有必须更改的位置，而我根本不必执行程序。对于一些简单的重构（例如属性重命名），IDE 甚至可以为我进行这些更改。此外，通过显式命名的类型，我可以建立一个词汇表（Person、City），然后可以与其他函数和类共享。

还有其他一些对象字段类型的方式，例如 TypedDict 或 NamedTuple。

## 代数数据类型

在 Rust 中，我可能在大多数主流语言中最缺少的一件事是代数数据类型（ADT）。它是一种非常强大的工具，可以明确描述我的代码正在处理的数据形状。例如，当我在 Rust 中处理数据包时，我可以明确列举可以接收的所有各种数据包，并为每个数据包分配不同的数据（字段）：

```rust
enum Packet {
  Header {
    protocol: Protocol,
    size: usize
  },
  Payload {
    data: Vec<u8>
  },
  Trailer {
    data: Vec<u8>,
    checksum: usize
  }
}
```

并且使用模式匹配，我可以对各个变体做出响应，编译器会检查我是否漏掉了任何情况：

```rust
fn handle_packet(packet: Packet) {
  match packet {
    Packet::Header { protocol, size } => ...,
    Packet::Payload { data } |
    Packet::Trailer { data, ...} => println!("{data:?}")
  }
}
```

这对于确保无效状态不可表示，从而避免许多运行时错误非常宝贵。在静态类型语言中，ADT 尤其有用，如果要以统一的方式使用一组类型，就需要一个共享的“名称”来引用它们。没有 ADT，通常使用面向对象的接口和/或继承来实现这一点。当使用的类型集合是开放性的时，接口和虚拟方法有其用武之地，然而当类型集合是封闭的，并且要确保处理所有可能的变体时，ADT 和模式匹配更适合。

在动态类型语言（如 Python）中，实际上没有必要为一组类型设置共享名称，主要是因为在程序中根本不必命名使用的类型。然而，通过创建一个联合类型，仍然可以使用类似于 ADT 的东西：

```python
@dataclass
class Header:
  protocol: Protocol
  size: int

@dataclass
class Payload:
  data: str

@dataclass
class Trailer:
  data: str
  checksum: int

Packet = typing.Union[Header, Payload, Trailer]
# or `Packet = Header | Payload | Trailer` since Python 3.10
```

在这里，`Packet` 定义了一个新类型，它可以是标头（header）、有效载荷（payload）或尾部（trailer）数据包。现在，当我想确保只有这三个类是有效时，我可以在程序的其余部分中使用这个类型（名称）。请注意，这些类没有显式的“标签”，因此当我们想要区分它们时，我们必须使用例如 `instanceof` 或模式匹配：

```python
def handle_is_instance(packet: Packet):
    if isinstance(packet, Header):
        print("header {packet.protocol} {packet.size}")
    elif isinstance(packet, Payload):
        print("payload {packet.data}")
    elif isinstance(packet, Trailer):
        print("trailer {packet.checksum} {packet.data}")
    else:
        assert False

def handle_pattern_matching(packet: Packet):
    match packet:
        case Header(protocol, size): print(f"header {protocol} {size}")
        case Payload(data): print("payload {data}")
        case Trailer(data, checksum): print(f"trailer {checksum} {data}")
        case _: assert False
```

不幸的是，在这里我们必须（或者说应该）包含烦人的 `assert False` 分支，以便在接收到意外数据时使函数崩溃。在 Rust 中，这将是一个编译时错误。

注：Reddit 上的一些人提醒我，`assert False` 实际上在优化的构建中被完全优化掉了（`python -O ...`）。因此，直接引发异常可能更安全。还有来自 Python 3.11 的 `typing.assert_never`，它明确告诉类型检查器，陷入到这个分支应该是一个“编译时”错误。

联合类型的一个好处是它是在组成联合的类之外定义的。因此，类并不知道它被包含在联合中，这减少了代码中的耦合。而且，甚至可以使用相同的类型创建多个不同的 Union 类型：

```python
Packet = Header | Payload | Trailer
PacketWithData = Payload | Trailer
```

Union 类型在自动（反）序列化方面也非常有用。最近我发现了一个很棒的序列化库，叫做 pyserde，它基于备受尊敬的 Rust serde 序列化框架。在许多其他很酷的功能中，它能够利用类型提示来序列化和反序列化联合类型，而无需额外的代码：

```python
import serde

...
Packet = Header | Payload | Trailer

@dataclass
class Data:
    packet: Packet

serialized = serde.to_dict(Data(packet=Trailer(data="foo", checksum=42)))
# {'packet': {'Trailer': {'data': 'foo', 'checksum': 42}}}

deserialized = serde.from_dict(Data, serialized)
# Data(packet=Trailer(data='foo', checksum=42))
```

你甚至可以选择如何序列化联合标签，就像 serde 一样。我长时间以来一直在寻找类似的功能，因为对于（反）序列化联合类型来说，这是非常有用的。然而，在我尝试的大多数其他序列化库中（例如 dataclasses_json 或 dacite）实现它是相当烦人的。

例如，在处理机器学习模型时，我使用联合类型在单个配置文件格式中存储各种类型的神经网络（例如分类或分割 CNN 模型）。我还发现将不同格式的数据（在我这种情况下是配置文件）进行版本化也很有用，像这样：

```python
Config = ConfigV1 | ConfigV2 | ConfigV3
```

通过反序列化 `Config`，我能够读取配置格式的所有先前版本，从而保持向后兼容性。

## 使用 newtypes

在 Rust 中，定义数据类型通常是很常见的，这些数据类型不添加任何新行为，而只是用来指定某些其他通用数据类型的领域和预期使用方式 – 例如整数。这种模式称为 “newtype”，它也可以在 Python 中使用。这里有一个激励性的例子：

```python
class Database:
  def get_car_id(self, brand: str) -> int:
  def get_driver_id(self, name: str) -> int:
  def get_ride_info(self, car_id: int, driver_id: int) -> RideInfo:

db = Database()
car_id = db.get_car_id("Mazda")
driver_id = db.get_driver_id("Stig")
info = db.get_ride_info(driver_id, car_id)
```

发现错误了吗？

`get_ride_info` 的参数被交换了。没有类型错误，因为车辆 ID 和驾驶员 ID 都只是整数，因此类型是正确的，尽管语义上函数调用是错误的。

我们可以通过使用 “NewType” 为不同类型的 ID 定义单独的类型来解决这个问题：

```python
from typing import NewType

# Define a new type called "CarId", which is internally an `int`
CarId = NewType("CarId", int)
# Ditto for "DriverId"
DriverId = NewType("DriverId", int)

class Database:
  def get_car_id(self, brand: str) -> CarId:
  def get_driver_id(self, name: str) -> DriverId:
  def get_ride_info(self, car_id: CarId, driver_id: DriverId) -> RideInfo:


db = Database()
car_id = db.get_car_id("Mazda")
driver_id = db.get_driver_id("Stig")
# Type error here -> DriverId used instead of CarId and vice-versa
info = db.get_ride_info(<error>driver_id</error>, <error>car_id</error>)
```

这是一种非常简单的模式，可以帮助捕捉那些否则很难发现的错误。如果你正在处理许多不同类型的 ID（CarId vs DriverId）或某些度量值（Speed vs Length vs Temperature 等），而这些度量值不应该混在一起，这种模式特别有用。

## 使用构造函数

我非常喜欢 Rust 的一点是它本质上没有构造函数。相反，人们倾向于使用普通函数来创建（理想情况下是正确初始化的）结构的实例。在 Python 中，没有构造函数重载，因此如果需要以多种方式构造对象，有时会导致一个 `__init__` 方法，该方法有很多参数，以不同的方式进行初始化，并且实际上不能在一起使用。

相反，我喜欢创建带有明确名称的“构造”函数，使得如何构造对象以及从哪个数据构造对象变得很明显：

```python
class Rectangle:
    @staticmethod
    def from_x1x2y1y2(x1: float, ...) -> "Rectangle":
    
    @staticmethod
    def from_tl_and_size(top: float, left: float, width: float, height: float) -> "Rectangle":
```

这使得构造对象变得更加清晰，并且不允许在构造对象时用户传递无效的数据（例如通过组合 y1 和 width）。

使用类型系统本身来编码通常只能在运行时跟踪的不变量是一个非常通用和强大的概念。在 Python（以及其他主流语言）中，我经常看到的是包含大量可变状态的复杂类。这种混乱的其中一个来源是尝试在运行时跟踪对象不变性的代码。它必须考虑在理论上可能发生的许多情况，因为类型系统没有将它们变得不可能（“如果客户端被要求断开连接，现在有人试图向其发送消息，但套接字仍然连接着”等等）。

## 客户端

这里是一个典型的例子：

```python
class Client:
  """
  Rules:
  - Do not call `send_message` before calling `connect` and then `authenticate`.
  - Do not call `connect` or `authenticate` multiple times.
  - Do not call `close` without calling `connect`.
  - Do not call any method after calling `close`.
  """
  def __init__(self, address: str):

  def connect(self):
  def authenticate(self, password: str):
  def send_message(self, msg: str):
  def close(self):
```

…很简单，对吧？您只需仔细阅读文档，并确保永远不会违反提到的规则（以免引发未定义的行为或崩溃）。另一种方法是使用各种断言填充类，以在运行时检查所有提到的规则，这会导致混乱的代码、遗漏的边缘情况以及当出现问题时较慢的反馈（编译时 vs 运行时）。问题的核心是客户端可以存在于各种（互斥的）状态中，但是与其将这些状态分开建模，它们全部合并在一个单一的类型中。

让我们看看是否可以通过将各种状态拆分为单独的类型来改进这一点。

首先，有一个未连接到任何内容的 Client 是否有意义？似乎并不是。在调用 connect 之前，这样一个未连接的客户端什么也做不了。那么为什么要允许这种状态存在呢？我们可以创建一个名为 `connect` 的构造函数，它将返回一个已连接的客户端：    

```python
def connect(address: str) -> Optional[ConnectedClient]:
  pass

class ConnectedClient:
  def authenticate(...):
  def send_message(...):
  def close(...):
```

如果函数成功，它将返回一个保持“已连接”不变性的客户端，并且您不能再次调用 `connect` 来弄乱事情。如果连接失败，该函数可以引发异常或返回 `None`` 或一些明确的错误。

对于已验证的状态，可以采用类似的方法。我们可以引入另一种类型，该类型保持客户端既已连接又已验证的不变性：

```python
class ConnectedClient:
  def authenticate(...) -> Optional["AuthenticatedClient"]:

class AuthenticatedClient:
  def send_message(...):
  def close(...):
```

只有当我们实际拥有 `AuthenticatedClient` 实例时，我们才能真正开始发送消息。

最后一个问题是 `close` 方法。在 Rust 中（由于破坏性的移动语义），我们能够表达这样一个事实，即当调用 `close` 方法时，不能再使用客户端。在 Python 中实现这一点不是很容易，因此我们必须使用一些变通方法。一种解决方案可能是回退到运行时跟踪，引入客户端中的一个布尔属性，并在 `close` 和 `send_message` 中断言它还没有被关闭。另一种方法可能是完全删除 `close` 方法，只需将客户端用作上下文管理器：

```python
with connect(...) as client:
    client.send_message("foo")
# Here the client is closed
```

如果没有 `close` 方法，就不能意外地两次关闭客户端。

## 强类型的边界框

对象检测是我有时会涉及的计算机视觉任务，其中程序必须在图像中检测一组边界框。边界框基本上是一些带有附加数据的炫目的矩形，在实现对象检测时，它们随处可见。关于它们的一个让人讨厌的事情是，有时它们是归一化的（矩形的坐标和大小在区间 [0.0, 1.0] 中），但有时它们是非归一化的（坐标和大小受到它们附加到的图像的尺寸的限制）。当你将一个边界框通过许多处理数据预处理或后处理的函数时，很容易搞砸这个过程，例如两次规范化一个边界框，这会导致非常让人烦恼的调试错误。

这种情况发生过几次，所以有一次我决定通过将这两种类型的边界框拆分成两种不同的类型来永久解决这个问题：

```python
@dataclass
class NormalizedBBox:
  left: float
  top: float
  width: float
  height: float


@dataclass
class DenormalizedBBox:
  left: float
  top: float
  width: float
  height: float
```

通过这种分离，归一化和非归一化的边界框就不能轻松混在一起了，这在很大程度上解决了问题。然而，我们可以进行一些改进，使代码更加符合人体工程学：

通过组合或继承减少重复：

```python
@dataclass
class BBoxBase:
  left: float
  top: float
  width: float
  height: float

# 组合(Composition)
class NormalizedBBox:
  bbox: BBoxBase

class DenormalizedBBox:
  bbox: BBoxBase

Bbox = Union[NormalizedBBox, DenormalizedBBox]

# 继承(Inheritance)
class NormalizedBBox(BBoxBase):
class DenormalizedBBox(BBoxBase):
```

添加一个运行时检查，确保归一化的边界框实际上是归一化的：

```python
class NormalizedBBox(BboxBase):
  def __post_init__(self):
    assert 0.0 <= self.left <= 1.0
    ...
```

添加一种在两种表示之间进行转换的方式。在某些地方，我们可能想知道明确的表示，但在其他地方，我们希望使用一个通用接口（“任何类型的 BBox”）。在这种情况下，我们应该能够将 “任何 BBox” 转换为两种表示之一：

```python
class BBoxBase:
  def as_normalized(self, size: Size) -> "NormalizeBBox":
  def as_denormalized(self, size: Size) -> "DenormalizedBBox":

class NormalizedBBox(BBoxBase):
  def as_normalized(self, size: Size) -> "NormalizedBBox":
    return self
  def as_denormalized(self, size: Size) -> "DenormalizedBBox":
    return self.denormalize(size)

class DenormalizedBBox(BBoxBase):
  def as_normalized(self, size: Size) -> "NormalizedBBox":
    return self.normalize(size)
  def as_denormalized(self, size: Size) -> "DenormalizedBBox":
    return self
```

使用这个接口，我可以兼顾两全 – 为了正确性而分离类型，以及为了人体工程学而统一接口。

注意：如果你想要向父类/基类添加一些返回相应类的实例的共享方法，可以在 Python 3.11 中使用 `typing.Self`：

```python
class BBoxBase:
  def move(self, x: float, y: float) -> typing.Self: ...

class NormalizedBBox(BBoxBase):
  ...

bbox = NormalizedBBox(...)
# The type of `bbox2` is `NormalizedBBox`, not just `BBoxBase`
bbox2 = bbox.move(1, 2)
```

## 更安全的互斥锁

在 Rust 中，互斥锁和锁通常通过一个非常好的接口提供，有两个好处：

当你锁定互斥锁时，会得到一个 guard 对象，当它被销毁时会自动解锁互斥锁，利用了备受尊敬的 RAII 机制：

```rust
{
  let guard = mutex.lock(); // locked here
  ...
} // automatically unlocked here
```

这意味着你不能意外地忘记解锁互斥锁。类似的机制在 C++ 中也经常使用，尽管 std::mutex 仍然提供了没有 guard 对象的显式 lock/unlock 接口，这意味着它们仍然可能被错误地使用。

由互斥锁保护的数据直接存储在互斥锁（结构）中。使用这种设计，无法在没有实际锁定互斥锁的情况下访问受保护的数据。你必须首先锁定互斥锁以获取 guard，然后使用 guard 本身访问数据：

```rust
let lock = Mutex::new(41); // Create a mutex that stores the data inside
let guard = lock.lock().unwrap(); // Acquire guard
*guard += 1; // Modify the data using the guard
```

这与主流语言（包括 Python）中通常找到的互斥锁 API 形成鲜明对比，其中互斥锁和它保护的数据是分开的，因此在访问数据之前很容易忘记实际上锁定互斥锁：

```python
mutex = Lock()

def thread_fn(data):
    # Acquire mutex. There is no link to the protected variable.
    mutex.acquire()
    data.append(1)
    mutex.release()

data = []
t = Thread(target=thread_fn, args=(data,))
t.start()

# Here we can access the data without locking the mutex.
data.append(2)  # Oops
```

虽然在 Python 中我们无法像在 Rust 中一样获得完全相同的好处，但并非一无所获。Python 锁实现了上下文管理器接口，这意味着您可以在 `with` 块中使用它们，以确保它们在作用域结束时自动解锁。并且通过一点点的努力，我们甚至可以更进一步：

```python
import contextlib
from threading import Lock
from typing import ContextManager, Generic, TypeVar

T = TypeVar("T")

# Make the Mutex generic over the value it stores.
# In this way we can get proper typing from the `lock` method.
class Mutex(Generic[T]):
  # Store the protected value inside the mutex 
  def __init__(self, value: T):
    # Name it with two underscores to make it a bit harder to accidentally
    # access the value from the outside.
    self.__value = value
    self.__lock = Lock()

  # Provide a context manager `lock` method, which locks the mutex,
  # provides the protected value, and then unlocks the mutex when the
  # context manager ends.
  @contextlib.contextmanager
  def lock(self) -> ContextManager[T]:
    self.__lock.acquire()
    try:
        yield self.__value
    finally:
        self.__lock.release()

# Create a mutex wrapping the data
mutex = Mutex([])

# Lock the mutex for the scope of the `with` block
with mutex.lock() as value:
  # value is typed as `list` here
  value.append(1)
```

有了这个设计，只有在实际锁定互斥锁后，你才能访问受保护的数据。显然，这依然是 Python，因此你仍然可以破坏不变性 - 例如，通过在互斥锁之外存储对受保护数据的另一个指针。但除非你有敌意行为，这使得在 Python 中使用互斥锁接口更安全。

无论如何，我相信我在我的 Python 代码中还有更多的 “soundness patterns”，但这是我目前能想到的所有内容。如果你有类似的想法或任何其他评论，请在 Reddit 上告诉我。

    公平地说，如果你在 doc 注释中使用了一些结构化格式（如 reStructuredText），这对参数类型的描述也可能是正确的。在这种情况下，类型检查器可能能够使用它并在类型不匹配时发出警告。但如果你无论如何都使用类型检查器，我觉得更好的是利用“本地”机制来指定类型 – 类型提示。 ↩
    也称为区分/标记联合，Sum 类型，密封类等。 ↩
    是的，newtypes 还有其他用例，不仅限于此处描述的用例，请不要对我大喊大叫。 ↩
    这被称为类型状态模式。 ↩
    除非你很努力，例如手动调用魔法的 __exit__ 方法。 ↩

https://kobzol.github.io/rust/python/2023/05/20/writing-python-like-its-rust.html    
