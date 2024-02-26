#import "two_columns.typ": make_pages

#show: make_pages.with(
  title: "析锂检测"
)

#let person_info = (
  name: "小猪妖",
  address: "浪浪山",
  home_page: "https://rakulang.github.io",
  phone_number: "123456"
)

= 周一

#lorem(10)

= 周二

#lorem(10)

- 颠三倒四多大点事
- 实得分数但是算法
- 等梦醒来啊醒来呀

= 今天周三

- 测试
- 测试
- 测试

#colbreak()

= test1

#lorem(10)

= test2

#lorem(10)

= test3

#lorem(3)
