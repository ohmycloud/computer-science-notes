# 第五章 Working with Memory

What is stack frame?

1. https://stackoverflow.com/questions/10057443/explain-the-concept-of-a-stack-frame-in-a-nutshell
2. https://www.geeksforgeeks.org/stack-frame-in-computer-organization/

The only types which can be allocated on the stack are primitive types, compound types (such as
tuples and structs), str, and the container types themselves (but not necessarily their contents).

The compiler’s borrow checker is responsible for enforcing a small set of
ownership rules: every value has an owner, there can only be one owner at a time, and when the
owner goes out of scope the value is dropped.

When you assign the value of one variable to another
(i.e., let a = b;) it’s called a move, which is a transfer of ownership (and a value can only
have one owner). A move doesn’t create a copy unless you’re assigning a base type (i.e.,
assigning an integer to another value creates a copy).

Rather than using pointers, in Rust we often pass data around using references. In Rust, a
reference is created by borrowing. Data can be passed into functions by value (which is a move)
or by reference. While Rust does have C-like pointers, they aren’t something you’ll see very
often in Rust, except perhaps when interacting with C code.

Borrowed data (i.e., a reference) can either by immutable or mutable. By default, when you
borrow data you do so immutably (i.e., you can’t modify the data pointed to by the reference). If
you borrow with the mut keyword, you can obtain a mutable reference which allows you to
modify data. You can borrow data immutably simultaneously (i.e., have multiple references to
the same data), but you cannot borrow data mutably more than once at a time.

Borrowing is typically done using the & operator (or &mut to borrow mutably), however you’ll
sometimes see as_ref() or as_mut() methods being used instead, which are from the AsRef
and AsMut traits respectively. as_ref() and as_mut() are often used by container types to 
provide access to internal data, rather than obtaining a reference to the container itself.

Copies of data structures can either be shallow (copying a pointer or creating a reference) or deep
(copying or cloning all the values within a structure, recursively).

In Rust, the term cloning (rather than "copying") is used to describe the process of creating a new
data structure and copying (or more correctly, cloning) all the data from the old structure into the
new one. The operation is typically handled through the clone() method, which comes from the
Clone trait, and can be automatically derived using the #[derive(Clone)] attribute.

The Clone trait, when derived, operates recursively. Thus, calling clone() on any top-level data
structure, such as a Vec, is sufficient to create a deep copy of the contents of the Vec provided
they all implement Clone. Deeply nested structures can be easily cloned without needing to do
anything beyond ensuring they implement the Clone trait.

