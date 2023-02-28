# Role

## 使用 does

> Roles are a collection of attributes and methods; however, unlike classes, roles are meant for describing only parts of an object's behavior; this is why, in general, roles are intended to be mixed in classes and objects. In general, classes are meant for managing objects and roles are meant for managing behavior and code reuse within objects.

Rust 中的 Trait 和 Raku 中的 Role 有类似之处, 但是有很大区别。

Raku 要求类 `does` 某个 role 的类必须实现 role 中的所有方法。 

```rust
role Canine {
    has $.color;
    method bark { ... } # the ... indicates a stub 
    method run { ... }
}

class Dog does Canine {
    method bark {say "woof" } # *MUST* be implemented by class 
}

my $dog = Dog.new();
$dog.bark;
```

上面的类只实现了 role 中的其中一个方法, 所以 Raku 报错了, 因为 Dog 类没有实现 Canine role 中的 `run` 方法。

```
===SORRY!=== Error while compiling D:\scripts\Raku/roles-in-raku.raku
Method 'run' must be implemented by Dog because it is required by roles: Canine.
at D:\scripts\Raku/roles-in-raku.raku:7
```

role 中的方法可以有默认实现, does 这个 role 的类默认可以调用这个方法了:

```raku
method run { say "Running" }
```

我们注意到上面的 `Canine` 中还有一个名为 `color` 的属性。`Dog does Canine` 会自动获取这个属性:

```raku
my $dog = Dog.new(color => "black");
```

但是, 如果你在 Dog 类中又写了一次 color 属性：

```raku
role Canine {
    has $.color;
}

class Dog does Canine {
    has $.color;
}
```

Raku 编译器会抱怨说 Dog 类中已经存在属性 `$!color` 了, 但是有个 role 也想组合(compose)它:

```
===SORRY!=== Error while compiling D:\scripts\Raku/roles-in-raku.raku
Attribute '$!color' already exists in the class 'Dog', but a role also wishes to compose it
```

Raku 还可以从 class 中使用 role 中的方法:

```raku
role Canine {
    method run { "In Canine" }
}

class Dog does Canine {
    method run { self.Canine::run }
}

my $dog = Dog.new();
$dog.run;
```

## 使用 is

> Roles can also be mixed into a class using is. However, the semantics of is with a role are quite different from those offered by does. With is, a class is punned from the role, and then inherited from. Thus, there is no flattening composition, and none of the safeties which does provides.

`is` role 更类似于 Rust 中的 trait。

```raku
role Canine {
    has $.color;
    #method bark { ... } # the ... indicates a stub 
    #method run { say self.title }
}

class Dog does Canine {
    has $.color;
    method bark {say "woof" } # *MUST* be implemented by class 
}

my $dog = Dog.new(color => "1we");
$dog.bark;
$dog.run;
```

Raku 中的 role 可以实例化, 实例化 role 或把 role 用作类型对象(type object)的时候，会自动创建一个和该 role 同名的类(class):

```raku
role Point {
    has $.x;
    has $.y;
    method abs { sqrt($.x * $.x + $.y * $.y) }
    method dimensions { 2 }
}
say Point.new(x => 6, y => 8).abs; # OUTPUT: «10␤» 
say Point.dimensions;              # OUTPUT: «2␤» 
```

Rust 中, 不能对 trait 进行实例化。

## 参数化 role

role 可以带参数。

```raku
role R[$d] {
    has $.a = $d
}

class C does R["default"] { };

my $c = C.new;
dd $c;
```