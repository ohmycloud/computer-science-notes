# 使用 Supply 跟踪盒子中物品的数量

这一切都始于一个盒子。每隔一段时间, 盒子里就会放入一定数量的东西。使用 Raku 跟踪盒子中物品数量的最佳方法是什么？

显而易见的答案是使用 `$*SCHEDULER.cue`, 不是吗？但是当我有另一个盒子, 里面装着另一套东西时会发生什么。

另一个选项是 `Supply.interval`, 如果每个时间间隔的项目数为 1, 它会很好用, 但事实并非如此。

## 引入 `Supply.interval-with-value`。

它采用正常的 `.interval`, 并向其添加一个 `value` 参数:

```raku
class IntervalValue does Tappable {
    has $!scheduler;
    has $!interval;
    has $!delay;
    has $!value;

    submethod BUILD(
        :$!scheduler, 
        :$!interval, 
        :$!value,
        :$!delay 
        --> Nil
    ) { }

    method tap(&emit, &, &, &tap) {
        my $i = 0;
        my $lock = Lock::Async.new;
        $lock.protect: {
            my $cancellation = $!scheduler.cue(
                {
                    CATCH { 
                        $cancellation.cancel if $cancellation
                    }

                    $lock.protect: { 
                        emit [ $!value, $i++ ] 
                    };
                }, 
                :every($!interval), 
                :in($!delay)
             );
             my $t = Tap.new({ $cancellation.cancel });
             tap($t);
             $t
        }
    }

    method live(--> False) { }
    method sane(--> True) { }
    method serial(--> True) { }
}

use MONKEY-TYPING;

augment class Supply {
  method interval-with-value(
    Supply:U: 
      $interval, 
      $value, 
      $delay = 0, 
      :$scheduler = $*SCHEDULER
  ) {
    Supply.new(
        IntervalValue.new(
            :$interval, 
            :$delay, 
            :$value, 
            :$scheduler
        )
    );
  }
}
```


不是扔掉数据, 这个供应有两个参数。第一个参数是 `value`, 即进入盒子的物品数量。最后一个参数是 `count`, 和原来的 `Supply.interval` 是一样的。

所以执行以下操作:

```raku
Supply.interval-with-value(2, 30).tap( -> *@a {
    say "Value: { @a.head } / Count { @a.tail.succ }";
});
sleep 10;
```

产生以下结果:

```
Value: 30 / Count: 1
Value: 30 / Count: 2
Value: 30 / Count: 3
Value: 30 / Count: 4
Value: 30 / Count: 5
```

这现在是一种享受！

当然, 当需要改变 `value` 时会发生什么？我们需要重构吗？

好吧, 你是说真的吗?

你看, `value` 是无类型的。

所以它可以是任何东西。

就像闭包那样！

所以像下面这样的代码会工作得很好: 

```raku
my $scalable = sub { 30 * $bonus };

Promise.in(5).then({ 
    $bonus = 2;
    say "Scalable is now { $scalable() }";
});

Supply.interval-with-value(2, $scalable).tap( -> *@a {
    say "Value: { @a.head.() } / Count { @a.tail.succ }";
});
```

运行上面的代码会产生: 

```
Value: 30 / Count: 1
Value: 30 / Count: 2
Scalable is now 60
Value: 60 / Count: 3
Value: 60 / Count: 4
Value: 60 / Count: 5
```

这代码运行得很好。

## 把它们放在一起...

所以我现在拥有处理盒子计数所需的一切。

```raku
class Box {
    has $.count is rw = 0;
}

my $b = Box.new;

my $items = 30;
my $counter = sub { $items };

Supply.interval-with-value(2, $counter).tap( -> *@a {
    my $delta = @a.head.();
    say "Count += { $delta }";
    $b.count += $delta;
});

# Introduce randomness by changing count 4 times
for ^4 {
    Promise.in($_ * 2).then({
        my $delta = (-5..5).grep( *.so ).pick;
        say "Adjusting item count by $delta";
        $items +=  $delta;
    });
}
sleep 15;

say "Final count: { $b.count }";
```

运行这个新代码, 我得到以下信息: 

```
Count += 30
Adjusting item count by 2
Count += 32
Adjusting item count by -3
Count += 29
Adjusting item count by -5
Count += 24
Adjusting item count by -2
Count += 22
Count += 22
Count += 22
Count += 22
Final count: 203
```

这就是:

```raku
raku -e 'say 88 + 24 + 29 + 32 + 30'
203
```

结果是正确的！

所以这是一种在特定时间间隔以任意增量递增盒子中物品数量的方法。希望有一天这能帮助你解决一个神秘的用例。

## 原文链接

https://dev.to/xliff/using-a-supply-to-track-the-number-of-items-in-a-box-3d1b
