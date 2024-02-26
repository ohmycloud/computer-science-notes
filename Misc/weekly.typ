#import "@preview/cetz:0.1.1"
#import "@preview/splash:0.3.0": *

#let code(body, color, orientation: bool) = {
  set text(size: 18pt, weight: "regular")
  show: box.with(
    fill: color,
    inset: 0.4em,
    radius: 3pt,
    baseline: 0.4em,
    width: if orientation == true { 100% } else { 50% },
    height: if orientation == true { 30% } else { 10% },
  )
  align(center)[#body]
}

#show "你": it => {
    text(red)[#it]
}

#show heading.where(level: 1): it => {
    align(left)[#code(text(tol-light.light-blue)[ *#it*], rgb(23,45,56))]
    v(0.25em)
}

#let weeks = ("周一", "周二", "周三", "周四")
#let indices = range(weeks.len())
#let data(orientation) = weeks.zip(indices).map(
  ((v, k)) => 
    if calc.even(k) { code(v, rgb(12,165,160), orientation: orientation) }
    else { code(v, rgb(165,250,178), orientation: orientation) }
)

#let weekly_cols(title) = [
  #grid(
    columns: (auto,) * data(true).len(),
    rows: (auto),
    row-gutter: 10pt,
    column-gutter: (10pt, 25pt),
    ..data(true)
  )
]

// 一列多行
#let weekly_rows(title) = [
    #grid(
    columns: (auto),
    rows: (auto,) * data(false).len(),
    row-gutter: (10pt, ) * (data(false).len() - 1),
    column-gutter: 10pt,
    ..data(false)
  )
]

#weekly_cols("test")

// #pagebreak()

// #weekly_rows("title")
