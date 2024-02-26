#let cover = (
    "课题名称": "Raku 中关于 Grammar 的研究",
    "副标题": "Rakulang Rocks",
    "学院": "霍格沃兹浪浪山学院",
    "专业": "魔法与炼丹",
    "学生姓名": "小猪妖",
    "学号": "20080214107",
    "指导老师": "邓布利多",
    "日期": datetime.today().display(),
    "我还没说的": "我的脑子乱哄哄的"
)

#let max_title_len = calc.max(..cover.keys().map(x => x.clusters().len()))

#grid(
  columns: (9em, auto),
  gutter: 16pt,
  row-gutter: 23pt,
  ..(cover.keys().zip(cover.values())).flatten().enumerate().map(((idx, value)) => {
      set text(size: 18pt)
      if calc.even(idx) {
        let arr = value.clusters()
        let padding = (max_title_len - arr.len()) / (arr.len() - 1)
        arr.join([#h(1em * padding)])
      } else {
        v(-0.6em)
        block(
          width: 100%,
          inset: 4pt,
          stroke: (bottom: 1pt + black),
          align(center, value),
        )
      }
  }),
)
