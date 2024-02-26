#import "@preview/splash:0.3.0": xcolor

#let make-title(title: none, author: none, date: none, description: none) = [
  #set align(center)
  = #title
  #v(1em)
  #text(style: "italic", description)
  #v(1em)
  / 日期: #date
  #v(3em)
]

#let make-outline(title: none, color: none) = [
    #show outline.entry.where(
        level: 1
    ): it => {
        v(12pt, weak: true)
        text(color)[#it]
    }
    #outline(title: title, depth: 3, indent: 12pt)
]

#let conf(title: none, author: none, date: none, description: none, doc) = {
  set page(
    footer: locate(loc => {
      line(stroke: 1.2pt, length: 100%)
      set align(right)
      set text(font: "Cascadia Code PL", size: 12pt)
      v(-0.6em)
      [
        共#h(1em)
        #counter(page).final(loc).at(0)#h(1em)
        页#h(1em)
        第#h(1em)
        #counter(page).display()
        #h(1em)页
      ]
    })
  )

  set heading(numbering: "1.")

  make-title(title: title, author: author, date: date, description: description)

  let code(body) = {
    set text(weight: "regular")
    show: box.with(
      fill: luma(249),
      inset: 0.4em,
      radius: 3pt,
      baseline: 0.4em,
      width: 100%,
    )
    [#body]
  }

  show heading.where(level: 1): it => {
    align(center)[#code(text(red)[ *#it*])]
    v(0.75em)
  }

  show heading.where(level: 2): it => {
    text(red)[ *#it*]
    v(0.6em)
  }

  show heading.where(level: 3): it => {
    text(red)[ *#it*]
    v(0.6em)
  }

  show raw.where(block: true): block.with(
    fill: luma(240),
    inset: 10pt,
    radius: 4pt,
    width: 100%,
  )

  pagebreak()
  make-outline(title: "目 录", color: xcolor.periwinkle)
  pagebreak()

  doc
}
