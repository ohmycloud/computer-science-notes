# 第二章 An overview of Rust

- Each value in Rust has a variable that’s called its owner
- There can only be one owner at a time
- When the owner goes out of scope, the value will be dropped

The stack is used for storing local variables created inside of the currently running function, and
the functions that led to the current function being called. It has a small limit on its maximum
size, often eight megabytes. It always grows like a stack of papers, meaning whenever values are
added to or removed from it, they are added to or removed from the top. Because of this
property, the stack does not have gaps in it.

The heap on the other hand, is only limited by the size of the memory of the computer that the
program is running on, which may be in the gigabytes, or terabytes. Because of this, the heap is
used to store much larger data, or data where the exact size is not known before the program
runs. Things like arrays and strings are more often than not stored on the heap. Memory
associated with the heap is also referred to as dynamic memory, because the size of the values on
the heap will not be known until the program is running.

The lifetime of a value describes the period of time when that value is valid. If
it’s a local variable in a function, its lifetime might be the time that the function is being called.
If it’s a global variable, it might live for the entire runtime of the program. A value is valid in the
time after its memory is allocated and before it is dropped. Trying to use a value at any time
outside of this range is invalid.

In Rust, values are dropped when they go out of scope. For
local variables in a function, this happens just before the function ends

References and Borrowing

Borrowing a value in Rust
always results in having a reference to the thing you are borrowing, references can be thought of
as values that tell Rust how to find other values.

If you imagine your computer memory as an
enormous array of values, references are like indices in that array that allow you to find values
within it.

Borrowing a value in Rust is much like borrowing a physical object in real life. Since we don’t
own the value that we’re using, we don’t get to destroy it when we’re finished with it. We may
use it temporarily, but we always need to return it to the owner before the owner is destroyed

1. Each value may have either exactly one mutable reference, or any number of immutable
   references at any time.
2. References must always be valid.

