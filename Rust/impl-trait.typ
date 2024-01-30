== `impl Trait` in type aliases

```rs
type Odd = impl Iterator<Item = u32>;
fn odd(start: u32, stop: u32) -> Odd {
    (start..=stop).filter(|i| i % 2 == 0)
}
```

== `impl Trait` in return types

```rs
fn odd(start: u32, stop: u32) -> impl Iterator<Item = u32> {
    (start ..= stop).filter(|i| i % 2 != 0)
}
```

== `impl Trait` in argument types

When you use an `impl Trait` in the type of a function argument, that is generally equivalent to adding a generic parameter to
the function. So this function:

```rs
fn sum(nums: impl Iterator<Item = u32>) -> u32 {
    nums.sum()
}
```

is roughly equivalent to the following generic function:

```rs
fn sum<T>(nums: T) -> u32
where
    T: Iterator<Item = u32>,
{
    nums.sum()
}
```

Intuitively, a function that has an argument of type `impl Iterator` is saying "you can give me any sort of iterator that you like".

== Return types in trait definitions and impls

When you use `impl Trait` as the return type for a function *within a trait* or *trait impl*, 
the intent is the same: impls that implement this trait return "some type that implements `Trait`", and 
users of the trait can only rely on that. However, the desugaring to achieve that effect looks somewhat different than other cases
of impl trait in return position. This is because we cannot desugar to a type alias in the surrounding module;
We need to desugar to an associated type(effectively, a type alias *in the trait*).

Consider the following trait:

```rs
trait IntoIntIterator {
    fn into_int_iter(self) -> impl Iterator<Item = u32>;
}
```

The semantics of this are analogous to introducing a new *associated type* within the surrounding trait;

```rs
trait IntoIntIterator { // desugared
    type IntoIntIter: Iterator<Item = u32>;
    fn into_int_iter(self) -> Self::IntoIntIter;
}
```

This associated type is introduced by the compiler and cannot be named by users.

The impl for a trait like `IntoIntIterator` must also use `impl Trait` in return position:

```rs
impl IntoIntIterator for Vec<u32> {
    fn into_int_iter(self) -> impl Iterator<Item = u32> {
        self.into_iter()
    }
}
```

This is equivalent to specify the value of the associated type as an `impl Trait`:

```rs
#![feature(impl_trait_in_assoc_type)]

impl IntoIntIterator for Vec<u32> {
    type IntoIntIter = impl Iterator<Item = u32>;
    fn into_int_iter(self) -> Self::IntoIntIter {
        self.into_iter()
    }
}
```
