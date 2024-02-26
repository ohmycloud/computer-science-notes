= Grokking Machine Learning

#let chapter(title, subtitle, heading) = [
  #grid(
    columns: (auto, auto, auto),
    rows: (auto, auto),
    row-gutter: 10pt,
    column-gutter: (10pt, 25pt),
    text(gray, weight: "bold", size: 24pt)[#title],
    [#line(length: 1.8cm, stroke: 3pt + red, angle: 90deg)],
    text(red, weight: "bold", size: 72pt)[#heading],
    align(right)[#text(red, weight: "bold", baseline: -30pt, size: 24pt,)[#subtitle]],

  )
]


== #chapter("Drawing a line close to our points:", "Linear regression", 3)

#text(maroon, weight: "bold")[features] The features of a data point are those properties that we use to make our prediction. \
#text(maroon, weight: "bold")[labels] This is the target that we try to predict from the features. \
#text(maroon, weight: "bold")[model] A machine learning model is a rule, or a formula, which predicts a label from the features. \
#text(maroon, weight: "bold")[prediction] The prediction is the output of the model. \
#text(maroon, weight: "bold")[weights] In the formula corresponding to the model, each feature is multiplied by a corresponding factor. These factors are the weights.\
#text(maroon, weight: "bold")[bias] The formula corresponding to the model has a constant that is not attached to any of the features. This constant is called the bias.

How o get the computer to draw this line: The linear regression algorithm

Start with a random line, and figure out a way to improve this line a little bit by moving it closer to the points. Repeat this process many times, and voila, we have the desired line. This process is called the linear reression algorithm.

Start with a random line. Pick a random point in the dataset, and move the line slightly closer to that one point. Repeat this process many times, always picking a random point in the dataset.

Pseudocode for the linear regression algorithm

Inputs: A dataset of points \
Outputs: A linear regression model that fits that dataset \
Procedure:
  - Pick a model with random weights and a random bias.
  - Repeat many times:
    - Pick a random data point.
    - Slightly adjust the weights and bias to improve the prediction for that particular data point.

 - *Return* the model you've obtained.

这个过程中, 你可能会提出一些问题:

- 权重的值要调整到多少?
- 这个回归算法我要重复多少次? 换句话说, 我怎么知道我做完了?
- 我怎么知道这个算法是否有效呢?

我们使用下面两种方法回答上面的问题。

误差函数：“绝对误差”和“平方误差”，会帮助我们决定在哪里停止线性回归算法。\
梯度下降：Gradient descent。

斜率告诉我们直线所指的方向, y 轴截距告诉我们直线的位置。注意, 通过指定斜率和 y 轴截距, 直线就完全确定了。

