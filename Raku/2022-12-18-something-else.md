原文链接: https://raku-advent.blog/2022/12/18/day-18-something-else/

在听说了 Rakudo 编译器新的 [2022.12 版本](https://rakudo.org/post/announce-rakudo-release-2022.12)之后，圣诞老人心不在焉地查看了过去几周的 Rakudo 提交。他注意到，在那个版本之后，已经没有任何提交了。他想知道，是不是所有的精灵在节假日都去忙其他事情了。但是，在其他年份，Raku 核心的精灵们在12月总是非常忙碌。他回忆起2015年12月，脸上露出了一丝微笑：唷，唷，那时候的精灵们都很忙！他说。

圣诞老人有点担心，所以他又把莉兹贝尔叫进来了。"所以，为什么 2022.12 发布之后再没人给 Raku 贡献代码了"，他问。"啊，那个！"，莉兹贝尔说。"不用担心，我们把 Rakudo 的默认分支改为 'main' 了"，她说。"你为什么要这么做？"，圣诞老人问道，表现得有点暴躁。"以前的默认分支不够好吗？"。莉兹贝尔担心讨论时间过长(再次)，并说"这是 Github 上的新默认分支，所以我们 Raku 核心精灵们认为遵循这一点是个好主意，因为现在许多工具都把 'main' 当作默认分支了"。

"嗯哼"，圣诞老人说，同时他切换到了 'main' 分支'。"哇！，自 2022.12 发布以来，有 780 多个提交，这怎么可能呢？"，他感叹道。"难道精灵们在每年的这个时候都没有更好的事情可做吗？"他说，同时提高了一点声音。莉兹贝尔注意到他的脸颊变得比平时更红了一些。

"啊，那个！"，丽兹贝尔又说道。

# RakuAST

她继续说话了。还记得大约两年半前由 MoarVM 精灵主发起的 RakuAST 项目吗？从那时起它就一直在断断续续地开发着，现在核心精灵们认为它已经准备好了，可以在这个新的 'main' 分支中提供这些工作。这样，其他核心和非核心的精灵们可以很容易地尝试它所提供的一些新功能。"那么，这个 RakuAST 项目现在已经完成了吗？"，圣诞老人说，他的眼睛里闪过一丝希望。"啊，不，你可以说，这个项目现在已经完成了一半多了"，莉兹贝尔说，希望这对圣诞老人来说已经足够了。"又让我想起来了, 那个项目到底是怎么回事？"，圣诞老人说，莉兹贝尔想默默溜走的希望破灭了。

在坐下来的时候，莉兹贝尔说: "[AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) 可以被认为是编程语言的[文档对象模型](https://en.wikipedia.org/wiki/Document_Object_Model)。RakuAST 的目标是提供一个 AST，它是 Raku 语言规范的一部分，因此可以被语言使用者所依赖。这样一个 AST 是对实际解决实际问题的宏的有用实现的前提，但也为模块开发者提供了进一步强大的机会。RakuAST 也将成为 Rakudo 本身使用的 Raku 程序的初始内部表示。这反过来又给了一个改进编译器的机会。" "我打赌你是让 ChatGPT 打出来给你背的"，圣诞老人眼珠子一转说。

"诶，不，实际上，这是来自[2020年MoarVM的精灵拨款提案](https://news.perlfoundation.org/post/gp_rakuast)，莉兹贝尔坦白说。"好吧，那么告诉我那个项目的交付成果是什么？我没有一整天的时间去看拨款提案，你知道吗？"，圣诞老人说。

莉兹贝尔偷看了一下她的精灵板，深吸了一口气，说: "嗯，首先：类和角色的实现，为 Raku 语言及其子语言定义了一个文档对象模型，可在 Raku 语言中构建和内省。第二，从 RakuAST 节点生成 QAST，即独立于后端的中间表示，这样就可以执行 AST。第三，涵盖 RakuAST 节点运行的测试。最后，将 RakuAST 整合到编译过程中"。"有趣"，圣诞老人说，"那已经完成多少了？" "如果你使用 RakuAST 来编译你的 Raku 代码, 它足以使 60% 以上的 Rakudo 测试文件完全通过，40% 以上的 Raku 测试文件完全通过"， 莉兹贝尔说。

# 现在就使用它

圣诞老人继续着现在感觉像审讯的对话。"那么 RakuAST 现在有什么用？" "嗯，它允许模块开发人员开始试玩 RakuAST 的功能"，莉兹贝尔说。"但是你确定 RakuAST 足够稳定，可以让模块开发者依赖了吗？"，圣诞老人皱着眉头说。"不，核心精灵们对它还没有足够的把握，所以这就是为什么模块开发者需要在他们的代码中添加 `use experimental :rakuast` 的原因。"有关于这些 RakuAST 类的任何文件吗？" "不，没有，但在 [t/12-rakuast](https://github.com/rakudo/rakudo/tree/main/t/12-rakuast) 子目录下有测试文件。而且在新的 [Formatter](https://github.com/rakudo/rakudo/blob/main/src/core.e/Formatter.pm6) 类中有一个模块的概念验证，该模块可以将 [sprintf 格式字符串](https://docs.raku.org/routine/sprintf#Directives)转换为可执行代码，其速度会快30倍"，莉兹贝尔突然说。

"好吧，这是一个开始"，圣诞老人说，他脸颊上的红色更淡了。

然后，圣诞老人又被外面的雪吸引了注意力，喃喃自语道: "驯鹿现在准备好了吗？"