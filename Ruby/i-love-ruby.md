# Getting Started

## 安装 Ruby

安装 Ruby 前, 先安装 rvm:

```bash
curl -sSL https://get.rvm.io | bash -s stable
```

再使用 rvm 安装 Ruby:

```bash
rvm install ruby
```

## 交互式 Ruby

交互式 Ruby 有两种, 一种是在终端中输入 `irb`:

```bash
irb(main):001:0>
irb(main):002:0>
```

另一种是带参数的 irb, 即 `irb --simple-prompt`:

```bash
>>
>>
```

打开 Jupyter Lab:

```bash
gem install iruby
mkdir i-love-ruby && cd i-love-ruby
bundle init
jupyter kernel --kernel=ruby
```

## 字符串

变量插值:

```ruby
time_now = Time.new # Get the current time into a variable

# 变量在单引号字符串中不插值
puts 'Hello world, the time is now #{time_now}'
puts "Hello world, the time is now #{time_now}"
```

获取输入:

```ruby
name = gets()
puts "#{name.chomp}"
```

## pattern match

1) 匹配单个字符串

```ruby
name = "twostraws"

case name
  when "bilbo"
    puts "Hello, Bilbo Baggins!"
  when "twostraws"
    puts "Hello, Paul Hudson!"
  else
    puts "GoodBye"
end
```

2) 匹配一组数字

```ruby
num = 7 # any number between 1 and 10

case num
  when 1, 3, 5, 7, 9
    puts "#{num} is odd"
  when 2, 4, 6, 8, 10
    puts "#{num} is even"
end
```

3) 匹配类型

```ruby
num = 42.8

case num
  when String
    puts "#{num} is a String"
  when Integer
    puts "#{num} is an Integer"
  when Float
    puts "#{num} is a Float"  
  when Fixnum
    puts "#{num} is a fixnum"
end
```

4) 匹配 Ranges

```ruby
num = 5

case num
when 1..4
    puts "#{num} is in [1..4]"
when 5..10
    puts "#{num} is in [5..10]"
end
```

5) 匹配正则表达式

```ruby
string = "I love Raku"

case string
when /Raku$/
    puts "#{string} contains Raku"
when /^I/
    puts "It's me"
else
    puts "string does not contain Raku"    
end
```

6) 匹配 lambda

```ruby
num = 7

case num
  when -> (n) { n % 2 != 0 }
    puts "#{num} is odd"
  else
    puts "#{num} is even"  
end
```

## 表达式

`if else` 和 `condition ? expression1 : expression2` 可以用作表达式:

```ruby
a,b = 3, 5
max = if a > b
  a
else
  b
end

min = a < b ? a : b

puts(max)
puts(min)
```

模式匹配也可以是表达式:

```ruby
num = 7
spell = String.new

spell = case num
  when -> (n) { n % 2 != 0 }
    "#{num} is odd"
  else
    "#{num} is even"  
end

puts "#{spell}"
```

# 循环

countdown:

```ruby
10.downto 1 do |num|
  p num
end  
```

times:

```ruby
3.times {
    puts "I love Raku"
}
```

循环时打印索引:

```ruby
3.times { |idx|
    puts "#{idx} I love Raku"
}
```

upto:

```ruby
17.upto 23 do |i|
  puts "#{i}"
end
```

step 可以向前计数, 也可以向后计数:

```ruby
# 正数
1.step 3 do |i|
  puts "#{i}"
end

1.step 10, 2 do |i| 
  puts "#{i}"
end

# 倒数
3.step 1, -1 do |i|
    puts "#{i}"
end

10.step 1, -2 do |i|
    puts "#{i}"
end
```

flip-flop:

```ruby
# flip-flop
1.upto 10 do |i|
    if (i == 5) .. (i == 8)
      puts i
    end
end

# 等价于
1.upto 10 do |i|
    case i
    when 5..8
      puts i
    end
end 
```

# 数组

```ruby
my_array = []
my_array << "Something"
my_array << 123
my_array << Time.now

my_array.each do |element|
    puts element
end
```

数组字面值:

```ruby
my_array = ["Something", 123, Time.now]
my_array.each do |element|
    puts element
end
```

for ... in 遍历:

```ruby
my_array = Array.new
my_array.push("Something")
my_array.push 123
my_array << Time.now

for element in my_array
    puts element
end
```

访问数组元素:

```ruby
countries = ["India", "Brazil", "Somalia", "Japan", "China", "Niger", "Uganda", "Ireland"]
puts countries[4..9].join(", ")
```

有一个不太符合直觉的地方是 `[]` 用在 if 语句中时, 其求值结果是 true:

```ruby
puts "A" if []
```

`nil` 的求值结果才是 false:

```ruby
puts "A" if nil
puts "A" if [].first
```

- collect

类似于 Swift 中的 compactMap, compact 会移除数组中的 nil 值:

```ruby
a = [1, nil, 2, nil, 3, nil]
a.compact # [1, 2, 3]
```

要就地修改数组 a 的值, 在函数后面添加一个感叹号:

```ruby
a.compact!
```

对数组的转换:

```ruby
a.collect {|element| element * element}
```

collect 类似于其它语言中的 map:

```ruby
a.map {|element| element * element}
```

要就地对数组进行转换, 在函数名后面添加一个感叹号:

```ruby
a.collect! {|element| element * element}
```

- keep_if

```ruby
array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
array.keep_if{ |element| element % 2 == 0}
```

keep_if 会就地修改数组。

- delete_if

```ruby
array.delete_if{ |element| element % 2 == 0}
```

# Hash

- 使用符号作为键

在 Hash 中我们经常使用符号而不是字符串作为键, 因为相比于字符串, 符号占用的空间更少, Ruby 中的符号类似于 Elixir 中的 `:`。

创建符号:

```ruby
:x
:y
:name
:age
```

符号可以保存在变量中:

```ruby
os = :iPhone12
os.class # Symbol
```

符号和字符串可以互相转换:

```ruby
:iPhone12.to_s    # "iPhone12"
"iPhone12".to_sym # :iPhone12
```

- 使用 Hash.new 创建 Hash

创建一个 Hash 并使用下标访问 Hash 中的元素:

```ruby
mark = Hash.new

mark['English'] = 50
mark['Math'] = 70
mark['Science'] = 75

sub = gets.chop

puts "Mark in #{sub} is #{mark[sub]}" if mark[sub]
```

创建 Hash 的时候, 可以指定键的默认值:

```ruby
mark = Hash.new 0
```

- 使用 Hash 字面值创建 Hash

```ruby
marks = { 'English' => 50, 'Math' => 70, 'Science' => 75 }
```

- 使用符号创建 Hash

```ruby
mark = Hash.new 0
mark[:English] = 50
mark[:Math] = 70
mark[:Science] = 75
```

或在字面量 Hash 中使用符号作为键:

```ruby
marks = { :English => 50, :Math => 70, :Science => 75 }
```

在 Ruby 1.9 之后, 还可以这样写:

```ruby
marks = { English: 50, Math: 70, Science: 75 }
```

Elixir 中符号的用法和 Ruby 一样。

- 遍历 Hash:

```ruby
mark.each { |key,value| 
    puts "#{key} = #{value}"
}
```

为什么使用符号作为键而不使用字符串作为 Hash 的键, 因为同一个符号指向相同的位置, 多次声明也不会占用额外的空间:

```ruby
# Ordinary strings are bad for memory.
c = "able was i ere i saw elba"
d = "able was i ere i saw elba"
c.object_id # 49380
d.object_id # 49400

# Frozen strings and symbols are good for memory. 
a = "able was i ere i saw elba".freeze
b = "able was i ere i saw elba".freeze
a.object_id # 49420
b.object_id # 49420


e = :some_symbol
f = :some_symbol
e.object_id # 3565148
f.object_id # 3565148
```

- compact

```ruby
hash = {a: 1, b: nil, c: 2, d: nil, e: 3, f:nil}
hash.compact  # 移除值为 nil 的键
hash.compact! # 就地修改 hash
```

- 转换 hash 的值

```ruby
hash = {a: 1, b: 2, c: 3}
hash.transform_values {|value| value * value }
```

# Ranges

```ruby
(1..5).each {|n| puts "#{n}"}
(1..5).class # Range

# Range works on stirng too.
("bad".."bag").each {|a| print "#{a}, " }
```

```ruby
r = -5..10
r.max
r.min
r.to_a # convert Ranger to Array
```

模式匹配范围:

```ruby
print "Enter student mark: "
mark = gets.chop.to_i

grade = case mark
    when 80..100 
        'A'
    when 60..79 
        'B'
    when 40..59 
        'C'
    when 0..39 
        'D'
    else "Unable to determine grade. Try again."
end

puts "The grade is #{grade}."
```

- 测试某个值是否落在某个 Range 中

```ruby
('a' .. 'z') === 'b' # true
('A' .. 'Z') === 'V' # true
```

这样的语法有点奇怪, 不如 Raku 的直观:

```raku
'A' ∈ ('A' .. 'Z')
```

还有个奇怪的地方是, 三个点会忽略 Range 中的最后一个值:

```ruby
(1...5).to_a # [1, 2, 3, 4]
```

Raku 中三个点代表 Sequence:

```raku
1...5
```

Begin and Endless Ranges:

```ruby
..34
28..
```

# 函数

```ruby
def print_line
  puts '_' * 20
end
```

- 位置参数

函数传参:

```ruby
def print_line length
  puts '_' * length
end

10.step(50, 10) do |x|
  print_line x
end
```

默认值:

```ruby
def print_line length = 20
  puts '_' * length
end
```

数组作为函数的参数:

```ruby
def array_changer array
  array << 6
end    

some_array = [1,2,3,4,5]
array_changer some_array
p some_array # [1,2,3,4,5,6]
```

这直接修改了传递的数组。

如果不想修改传递的数组, 可以拷贝数组:

```ruby
array_changer Marshal.load(Marshal.dump(some_array))
```

函数返回值:

```ruby
def addition x, y
  sum = x + y
  return sum
end

a,b = 3,5
puts addition a, b
```

函数中最后一个表达式的值就是函数的返回值:

```ruby
def addition x, y
  x + y
end

puts addition 3,5
```

- 关键字参数

```ruby
def say_hello name: "Martin", age: 33
    puts "Hello, #{name} your age is #{age}"
end

say_hello name: "Larry Wall", age: 67
say_hello age: 19, name: "Camalia"
say_hello
```

递归函数

```ruby
def factorial num
    return 1 if num == 1
    return num * factorial(num - 1)
end

puts factorial 5
```

变长参数 Variable number of arguments

```ruby
def some_function a, *others
  puts a
  puts others.class
  puts "Others are:"
  for x in others
    puts x
  end
end

some_function 1,2,3,4,5
```

Hash 作为函数参数:

```ruby
def some_function first_arg, others_as_hash
  puts "Your first argument is: #{first_arg}"
  print "Other arguments are: "
  p others_as_hash
end

some_function "Yoda", {jedi: 100, sword: 100, seeing_future: 100}
some_function "Yoda", jedi: 100, sword: 100, seeing_future: 100 # 花括号可以省略
```

参数转发(Argument Forwarding)

```ruby
def print_something(string)
  puts string
end

# ... 表示获取任何想要的参数
# 所有传递给 decorate 的参数被转发给 print_something
def decorate(...)
  puts '#' * 50
  print_something(...)
  puts '#' * 50
end

decorate("Hello World!")
```

print the first and forward others:

```ruby
def rest_of_arguments *args
    puts "In rest_of_arguments"
    puts args
end

def first_argument_and_forward_others(a, ...)
    puts "In first_argument_and_forward_others"
    puts a
    rest_of_arguments(...)
end

first_argument_and_forward_others(1, 2, 3, 4, 5)
```

简单的函数可以不带 end:

```ruby
def double(num) = num * 2
puts double(5)
```

# 变量作用域

```ruby
x = 5
def print_x
    x = 10
  puts x
end

print_x
```

函数默认无法访问定义在它外面的变量。

全局变量

```ruby
$x = 5

def print_x
  $x = 10
  puts $x - 6
end

print_x
puts($x)
```