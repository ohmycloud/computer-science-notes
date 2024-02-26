#import "@preview/cetz:0.1.1"
#import "@preview/splash:0.3.0": *

#outline(title: "目录")

听说, 

把一首歌反复听到上千遍,

与这首歌有关的场景或人就再也忘不掉了。

#pagebreak()

#set page(columns: 2, margin: .5cm)
#let code(body) = {
  set text(weight: "regular")
  show: box.with(
    fill: luma(249),
    inset: 0.4em,
    radius: 3pt,
    baseline: 0.4em,
    width: 60%,
  )
  [#body]
}

#show "你": it => {
    text(red)[#it]
}

#show heading.where(level: 1): it => {
    align(left)[#code(text(tol-light.light-blue)[ *#it*])]
    v(0.25em)
}

= 谁（live 版）

在你眼中我是谁

你想我代替谁

彼此交换悲喜

爱的多的人总先掉眼泪

= 彗星

就像日落燃烧最后的执着

再微弱的爱也感到炽热

我就像彗星千里外划破夜空

你却爱着升空的烟火

= 海堤上

不温暖的心有两颗

它们都曾遇到太多

风浪挨不过

不如握紧我 虽然我的手和你一样 冰凉

可两个灵魂紧紧相握终会 温热

= 在日月的璀璨间闪耀

残存的热血挣扎于

疲惫却不肯睡去的夜

头也不回的世界啊

我们要拥有这一切呀

= 不寻常夏日

我想再看一眼盛夏烟火

看回忆从晚空浪漫坠落

蝉鸣声的时间都被定格

剩鼓噪的心跳还在唱着

夏天是道苦茶格外青涩

树叶渗透小雨解暑消渴

也行初恋适合暮色

也许离别映衬不舍

你的夏天还好吗

天边橙色 深不可测

#colbreak(weak: true)
= 你

我知道

只有不断出发

才能够紧随

你纵情的步伐

= 你在终点等我

只想你找回让你像你的热情

然后就拖着自己到山城隐居

你却在终点等我住进你心里

没有你的地方都是他乡

没有你的旅行都是流浪


= 晴空日记

莫不是你忽然回了头

我怎么会心里乱了踪

莫不是那春风入了梦

风吹过起花红

人群中你回眸

在盛开的时候

年少的人啊

眼里是晴空

= 天使亲吻过的声音

呼唤着 你姓名 我就有远方

只要能 凝望着

你笑容 就拥有向往

只要我 失去梦 失去自我

流浪无尽黑夜

被天使 亲吻过的声音 引领我飞翔

只要你 呼喊着 我姓名 我就有力量

= 是你

海平面的烟火不断闪烁

照亮你的每一个角落

向山矗立远方 我越是前往

#place(top+left, [
#cetz.canvas(length: 2.5cm, {
  import cetz.draw: *
  set-style(
    line: (
      fill: red,
      stroke: (dash: "dashed")), 
    )
  line((0, 0), (0, 5.2), close: false, stroke: (paint: red))
  line((0, 0), (0, -5.8), close: false, stroke: (paint: blue))
})], dx: -45pt, dy: -8pt)
