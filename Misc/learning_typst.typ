= Test1

// each first paragraph needs a label
#lorem(10) <first>

= Test2

// the label doesn't refer to the whole sequence without wrapping it
#[
  Hello World. \
  Hello Again.
] <first>

```raku
.say for 1..5;
```

= Test2.1

// no <first> in this one!

= Test3

#[
  This is test3 \
  This is test3 too
] <first>

dfdfffdffdfdfdfdfdfdfdfdfd \
fdffdfdfdfdf

#locate(loc => {
  // if you prefer first building a dict, look at the commented parts

  // let dict = (:)

  // get all headings
  let hs = query(heading, loc)
  // pair it with the next heading
  let hs = hs.zip(hs.slice(1) + (none,))
  for (this-h, next-h) in hs {
    // get all <first>s between the current and next heading
    let sel = selector(<first>).after(this-h.location())
    if next-h != none {
      sel = sel.before(next-h.location())
    }
    let firsts = query(sel, loc)

    if firsts.len() > 0 {
      let key = this-h.body.text
      // ignore everything but the first <first> found for that heading
      let value = firsts.first()

      // do something with it
      text(weight: "bold", fill: red, key)
      linebreak()
      value
      linebreak()

      // // fill the dictionary
      // dict.insert(key, value)
    }
  }
})


#lorem(30)

#block(inset: (right: 5cm))[
  #lorem(30)
]

#block(inset: (left: 5cm))[
  #lorem(30)
]

#show par: it => block(inset: (right: 5cm), it)

#lorem(30)

#lorem(30)

#set page(height: 200pt)
#block(
  fill: luma(230),
  inset: 8pt,
  radius: 4pt,
  lorem(30)
)

#show heading: it => it.body
= Blockless 无代码块儿的
Scala

#show heading: it => block(it.body)
= 有 Block 的
Rust

#let pat = pattern(size: (50pt, 50pt))[
  #place(line(start: (0%, 0%), end: (100%, 100%)))
  #place(line(start: (0%, 100%), end: (100%, 0%)))
]

#block(
  fill: pat,
  inset: 10pt,
  lorem(10)
)

#set page(height: 80pt)
The following block will
jump to its own page.
#block(
  breakable: false,
  stroke: red,
  lorem(45),
)

#set page(height: auto)
#lorem(100)

