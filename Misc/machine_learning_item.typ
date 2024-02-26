= 术语

交叉验证折叠: cross-validation folds

自己实现交叉验证:

```python
from sklearn.model_selection import StratifiedKFold
from sklearn.base import clone

skfolds = StratifiedKFold(n_splits=3) # add shuffle=True if the dataset is
                                      # not already shuffled

for train_index, test_index in skfolds.split(X_train, y_train_5):
    clone_clf = clone(sgd_clf)
    X_train_folds = X_train[train_index]
    y_train_folds = y_train_5[train_index]
    X_test_fold = X_train[test_index]
    y_test_fold = y_train_5[test_index]

    clone_clf.fit(X_train_folds, y_train_folds)
    y_pred = clone_clf.predict(X_test_fold)
    n_correct = sum(y_pred == y_test_fold)
    print(n_correct / len(y_pred))
```

StratifiedFold 类执行分层抽样。每次迭代都创建一个分类器的克隆, 在训练折叠上训练克隆, 在测试折叠上做预测。
然后它计算正确预测的数量并输出正确预测的比率。

二元分类器: binary classifier
只能区分两个类别, 要么是某个类别，要么不是。

随机梯度下降: stochastic gradient descent(SGD 或 stochastic GD)

训练集:  training set
测试集:  test set

倾斜数据集: skewed datasets
比如, 某些类型的图片比其它类型的图片出现得频率更高。

混淆矩阵:  confusion matrix(CM)
用于评估分类器性能的一种更好的方式。
混淆矩阵的一般思想是对于所有 A/B 对儿，计算 A 类实例被分类为 B 类的次数。
例如，要知道分类器混淆图像 8 和 图像 0 的次数，你可以查看混淆矩阵的第8行第0列。

要计算混淆矩阵，你首先要有一组预测值，这组预测值会和实际目标进行比较。

你可以对测试集进行预测，但是现在最好不要碰测试集(在训练集上训练完分类器之后, 再使用测试集检测训练的效果)。
相反，你可以使用 *cross_val_predict()* 函数：

```python
from sklearn.model_selection import cross_val_predict

y_train_pred = cross_val_predict(sgd_clf, X_train, y_train_5, cv=3)
```

现在可以使用confusion_matrix()函数获得混淆矩阵了。只需将目标类(y_train_5)和预测类传递给它
(y_train_pred):

就像 *cross_val_score()* 函数一样，*cross_val_predict()* 执行 _k_-fold 交叉验证，但它不是返回评估分数，而是返回对每个测试折叠(test fold)所做的预测。
这意味着对于训练集(training set)中的每个实例, 你得到一个“干净的”预测(这里的“干净”是指“样本外”：模型对训练期间从未见过的数据进行预测)。

现在可以使用 *confusion_matrix()* 函数获得混淆矩阵了。只需要把目标类(y_train_5) 和预测类(y_train_pred)传递给它：

```python
from sklearn.metrics import confusion_matrix

cm = confusion_matrix(y_train_5, y_train_pred)

# array([[53892, 687],
#  [ 1891, 3530]])
```

混淆矩阵中的每一行代表一个实际的类，而每一列代表一个预测的类。该矩阵的第一行考虑非5的图像(阴性类)，其中53892个图像被正确分类为非5(称为真阴性)，而其余687个图像被错误分类为5(假阳性，也称为I类错误)。第二行考虑5s的图像(正类):
1891例被错误地归类为非5(假阴性，也称为II型错误)，而其余3530例被正确归类为5(真阳性)。

一个完美的分类器只会有真正和真负，所以它的混淆矩阵只会在主对角线上(从左上到右下)有非零值：

```python
y_train_perfect_predictions = y_train_5 # pretend we reached perfection
confusion_matrix(y_train_5, y_train_perfect_predictions)
```

分类器的精确度:(the accuracy of the positive predictions)

$"precision" = "TP" /("TP" + "FP")$

TP 为真阳性数，FP 为假阳性数。

要想获得完美的精度，一个简单的方法就是创建一个分类器，除了对它最有信心的实例进行一次正向预测外，它总是进行负向预测。如果这一个预测是正确的，那么分类器的精度就是 100%（精度 = 1/1 = 100%）。显然，这样的分类器用处不大，因为它会忽略除了一个正向实例之外的所有实例。因此，精度通常与另一个名为召回率(recall)的指标一起使用，召回率也称为灵敏度或真阳性率（TPR）：这是分类器正确检测到的阳性实例的比率：

$ "recall" = "TP" / ("TP" + "FN")$

当然，FN 是假阴性的数量。

精度和召回率

```python
from sklearn.metrics import precision_score, recall_score
precision_score(y_train_5, y_train_pred)
recall_score(y_train_5, y_train_pred)
```

$F_1$ score

$ F_1 = 2 / (1/"precision" + 1/"recall" ) 
      = 2 × ("precision" × "recall") / ("precision" + "recall") 
      = "TP" / ("TP" + ("FN" + "FP") / 2 )
$

要计算 $F_1$ 的值，只需要调用 *f1_score()* 函数：

```python
from sklearn.metrics import f1_score
f1_score(y_train_5, y_train_pred)
```
