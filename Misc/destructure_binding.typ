#import "@preview/splash:0.3.0": *

#let make-title(title: none, author: none, date: none, description: none) = [
  #set align(center)
  = #title
  #v(1em)
  #text(style: "italic", description)
  #v(1em)
  / 设计者: #author
  / 日期: #date
  #v(3em)
]

#make-title(
    title: "绑定时解构",
    author: "ohmycloud",
    date: "2024-01-25",
    description: "参数解构"
)

#outline(
    title: "目录",
    target: heading.where(level: 1)
)

#pagebreak()

#show heading.where(level: 1): it => {
    align(center)[#text(xcolor.cyan)[ *#it*]]
    v(0.75em)
}

#show heading.where(level: 2): it => {
    text(red)[ *#it*]
    v(0.6em)
}

#show heading.where(level: 3): it => {
    text(red)[ *#it*]
    v(0.6em)
}

#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)

= 定义主体

```rs
struct Book {
    title: String,
    author: String,
    count: u32,
    tags: Vec<String>,
}

fn main() {
    let book_list = vec![
        Book {
            title: "A Christmas Carol".into(),
            author: "Charles Dickens".into(),
            count: 1_200_000,
            tags: vec!["ghost".into(), "christmas".into()],
        },
        Book {
            title: "A Visit from St. Nicholas".into(),
            author: "Clement Clarke Moore".into(),
            count: 50_000_000,
            tags: vec!["santa".into(), "christmas".into()],
        },
    ];
}
```

= 绑定时解构

```rs
for Book {
    title,
    author,
    count,
    ..
} in book_list
{
    if count >= 1_000_000 {
        println!(
            "Congratulations, {}, you are the best sellers with {} ",
            author, count
        );
    }
}
```
