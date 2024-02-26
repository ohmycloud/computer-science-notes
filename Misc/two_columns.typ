// #set par(first-line-indent: 2em)
#show heading.where(level: 2): it => {
  [#it.body]
}

#let boxed_text(body: none, color: luma(240)) = {
  set text(weight: "regular")
  show: box.with(
    fill: color,
    inset: 0.4em,
    radius: 3pt,
    baseline: 0.4em,
    width: 100%,
  )
  [#body]
}

#show heading.where(level: 1): it => {
    align(left)[#boxed_text(body: text(red)[ *#it*])]
    v(0.75em)
}

#let h = locate(loc => {
  let heading1 = query(
    selector(heading.where(level: 1)).after(loc),
    loc,
    )
  let p = heading1.first().location().position()  
  let pos = (
    x: p.x,
    y: p.y
  )
  pos
})

// 分隔线
#let separator_line() = {
    line(
    start: (0pt, 0pt),
    end: (0pt, 600pt),
    length: 0pt,
    angle: -270deg, 
    stroke: (paint: rgb(167, 178, 189), thickness: 1pt, dash: ("dot", 1pt, 2pt, 2pt))  
  )
}

#let multi_row_items(array) = grid(
  columns: 1fr,
  rows: (1fr,) * (array.len() - 1),
  ..array.map(x => boxed_text(body: x))
)

// 左侧页面
#let left_page(body) = {
  show heading.where(level: 1): it => {
    boxed_text(body: it.body)
  }

  locate(loc => {
    let titles = query(heading.where(level: 1).before(loc), loc)
    let titles = titles.map(x => x.body)
    if (titles.len() > 0) {
      multi_row_items(titles)
    }
    else {
     multi_row_items(("第一", "第二", "谁"))
    }  
  })
}

// 右侧页面
#let right_page(body) = {
  show heading.where(level: 1): it => {
    boxed_text(body: it.body)
  }

  locate(loc => {
    let titles = query(heading.where(level: 1).before(loc), loc)
    let titles = titles.map(x => x.body)
    if (titles.len() > 0) {
      multi_row_items(titles)
    }
    else {
     multi_row_items(("第一", "第二", "谁"))
    } 
  })
}

#let header(title: none) = {
  set text(size: 18pt, fill: red) 
  boxed_text(body: title)
  show label("b"): set text(red)
}


#let make_pages(title: none, body) = {
  header(title: title)
  grid(
    columns: (6fr, -1fr, 4fr),
    column-gutter: (6fr, 1fr),
    left_page(body),
    separator_line(),
    right_page(body)
  )
}
