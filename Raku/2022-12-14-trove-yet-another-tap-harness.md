原文链接: https://raku-advent.blog/2022/12/14/day-14-trove-yet-another-tap-harness/

从早期的 Pheix 版本开始，我就对测试系统给予了很大的关注。最初，它是一套单元测试 - 我试图涵盖大量的单元，如类、方法、子程序和条件。在某些情况下，我在一个 `.t` 文件中结合了单元和功能测试，就像验证 Ethereum 或 API 相关功能一样。

测试变得有点复杂，并且依赖于环境。例如，像琐碎的 `prove6 -Ilib ./t` 这样的链外测试应该跳过任何以太坊测试，包括一些 API 单元，但不包括 API 模板引擎或跨模块 API 通信。所以我不得不创建与环境相关的配置，从那时起我开始了另一个 Pheix 友好的测试系统。

它是用纯 bash 编写的，并在 Pheix 存储库中包含了几年时间。

在 2022 年 6 月中旬，我引入了对 Coveralls 的支持，并收到了一些要求将这个测试工具与 Pheix 分开发布的请求。把那一刻看作是 Trove 模块的诞生。

非常感谢大家的贡献：https://github.com/pheix/raku-trove。

概念

一般来说，Trove 是基于创建另一个 prove6 应用程序的想法：在 `t` 文件夹中的单元测试的包装。但它具有开箱即用的 Github 和 Gitlab CI/CD 集成、扩展的日志和可测试的选项。

Trove 包括 `trove-cli` 脚本，作为批量测试的主要工作者。它在预先配置的阶段上进行迭代，并运行与该阶段相关的特定单元测试。`trove-cli` 是面向控制台的 - 所有输出都打印到 STDOUT 和 STDERR 数据流。输入来自命令行参数和配置文件。

命令行参数

颜色

为了给输出带来颜色，可以使用 `-c` 选项。

```bash
trove-cli -c --f=`pwd`/run-tests.conf.yml --p=yq
```

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/01-args-no-skip.png)

默认情况下，这个功能是关闭的--实际上颜色在手动测试中是很好的。但由于你在 GitLab 上使用运行器，激活颜色可能会破坏覆盖率集合。Gitlab 用预定义的正则表达式解析输出，如果颜色被打开，这个功能就会被破坏：文本的颜色由颜色代码表示，这些代码会在某种程度上影响覆盖率的解析。

阶段管理

要从测试中排除特定阶段，可以使用 `-s` 选项。

```bash
trove-cli -c --s=1,2,4,9,10,11,12,13,14,25,26 --f=`pwd`/run-tests.conf.yml --p=yq
```

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/02-args-skip.png)

文件处理器配置

`trove-cli` 从配置文件中获取测试场景。默认格式是 JSON，但你可以根据需要使用 YAML，目前 `JSON::Fast` 和 `YAMLish` 处理模块（处理器）已经集成。要在处理器之间切换，应使用以下命令行选项。

```bash
    --p=jq or do not use --p (default behavior) – JSON processor;
    --p=yq – YAML processor.
```

版本的一致性

为了验证提交时的版本一致性，应该使用下一个命令行选项。

```bash
    -g – path to git repo with version at latest commit in format %0d.%0d.%0d;
    -v – current version to commit (in format %0d.%0d.%0d as well).
```

```bash
trove-cli -c --g=~/git/raku-foo-bar --v=1.0.0
```

在 Pheix 测试套件中，trove-cli 将由 `-g` 和 `-v` 选项定义的版本推送到 `./t/11-version.t` 测试。下面的标准在这里得到验证：`-g` 路径下的 repo 最新提交的版本比 `-v` 版本低 1（在主要、次要或补丁成员之一），并且 `-v` 版本等于在 Pheix::Model::Version 中定义的版本。

你可以在 v0.13.116 上试试。

```bash
trove-cli -c --f=`pwd`/run-tests.conf.yml --p=yq --g=`pwd` --v=0.13.117
...
# Failed test 'curr git commit ver {0.13.117} and Version.pm {0.13.116} must be equal'
# at ./t/11-version.t line 25
# Failed test 'prev git commit ver {0.13.116} and Version.pm {0.13.116} must differ by 1.0.0 || x.1.0 || x.x.1'
# at ./t/11-version.t line 39
# You failed 2 tests of 6
# Failed test 'Check version'
# at ./t/11-version.t line 21
# You failed 1 test of 1
13. Testing ./t/11-version.t                               [ FAIL ]
[ error at stage 13 ]
```

版本一致性检查在 commit-msg 帮助器中使用，以验证提交者在提交信息中给出的版本。

```
commit 5d867e4e15928ef7a98f07c8753033339aa5cf7f
Author: Konstantin Narkhov 
Date:   Sun Dec 4 17:16:07 2022 +0300

    [ 0.13.116 ] Set Trove as default test suite

    1. Use Trove in commit-msg hook
    2. Set Trove as default test suite
```

目标配置文件

默认情况下，将使用下一个配置目标。

```bash
    JSON – ./x/trove-configs/test.conf.json;
    YAML – ./x/trove-configs/test.conf.yaml.
```

这些路径是用来测试 Trove 本身的。

```bash
cd ~/git/raku-trove && bin/trove-cli -c && bin/trove-cli -c --p=yq
```

你必须通过 `-f` 选项指定另一个配置文件。

```bash
trove-cli --f=/tmp/custom.jq.conf
```

第一阶段的日志策略

trove-cli 显然是用来测试 Pheix 的。第一个 Pheix 测试阶段检查 www/user.rakumod 脚本与。

```bash
raku $WWW/user.raku --mode=test # WWW == './www'
```

这个命令不向标准输出打印任何东西，最终也不需要保存到日志文件。默认情况下，第一阶段的输出被忽略。但如果你使用 Trove 来测试其他模块或应用程序，强制保存第一阶段的输出可能很方便。这可以通过 `-l` 命令行参数完成。

```bash
trove-cli --f=/tmp/custom.jq.conf -l
```

如果有空白输出的阶段没有被跳过，它将被纳入覆盖范围，但在 trove-cli 输出中被标记为 WARN。

```
01. Testing ./www/user.raku                                [ WARN ]
02. Testing ./t/cgi/cgi_post_test.sh                       [ 6% covered ]
...
```

源码库

默认情况下，origin repository 被设置为 git@github.com:pheix/raku-trove.git，你可以通过 `-o` 参数将其改为任何你喜欢的值。

```bash
trove-cli --f=/tmp/custom.jq.conf --o=git@gitlab.com:pheix/net-ethereum-perl6.git
```

它对于在 Coveralls 显示你的项目的 git 相关细节可能很方便。

配置

琐碎的测试配置示例

琐碎的多解释器单行测试配置文件被包含在 Trove 中。

```
target: Trivial one-liner test
stages:
  - test: raku  -eok(1); -MTest
  - test: perl6 -eis($CONSTANT,2); -MTest
    args:
      - CONSTANT
  - test: perl  -eok(3);done_testing; -MTest::More
```

要执行的测试命令。

```bash
CONSTANT=2 && trove-cli --f=/home/pheix/pool/core-perl6/run-tests.conf.yml.oneliner --p=yq -c
```

命令输出信息。

```
01. Testing -eok(1,'true');                                [ 33% covered ]
02. Testing -eis(2,2,'2=2');                               [ 66% covered ]
03. Testing -eok(3,'perl5');done_testing;                  [ 100% covered ]
```

跳过向 coveralls.io 发送报告。错过了 CI/CD 标识符

Pheix 测试套件的配置文件

Pheix 测试套件配置文件具有我们上面谈到的全套功能：阶段、子阶段、环境变量导出、设置和清理。这些文件（JSON，YAML）可以作为基本的例子，为另一个模块或应用程序创建测试配置，不管是 Raku，Perl 还是其他。

run-test.conf.yml 的样本片段。

```yaml
target: Pheix test suite
stages:
  - test: 'raku $WWW/user.raku --mode=test'
    args:
      - WWW
  - test: ./t/cgi/cgi_post_test.sh
    substages:
      - test: raku ./t/00-november.t
  ...
  - test: 'raku ./t/11-version.t $GITVER $CURRVER'
    args:
      - GITVER
      - CURRVER
  ...
  - test: raku ./t/17-headers-proto-sn.t
    environment:
      - export SERVER_NAME=https://foo.bar
    cleanup:
      - unset SERVER_NAME
    substages:
      - test: raku ./t/17-headers-proto-sn.t
        environment:
          - export SERVER_NAME=//foo.bar/
        cleanup:
          - unset SERVER_NAME
  - test: raku ./t/18-headers-proto.t
    substages:
      - test: raku ./t/18-headers-proto.t
        environment:
          - export HTTP_REFERER=https://foo.bar
        cleanup:
          - unset HTTP_REFERER
  ...
  - test: raku ./t/29-deploy-smart-contract.t
```

测试覆盖率管理

Gitlab

Gitlab 中的覆盖率是从作业的标准输出中获取的：当你的测试正在运行时，你必须将实际的测试进度以百分比的形式打印到控制台（STDOUT）。输出日志由运行器在作业结束时解析，匹配模式应在 `.gitlab-ci.yml` - CI/CD 配置文件中设置。

考虑上面一节中琐碎的测试配置例子，标准输出是。

```
01. Running -eok(1,'true');                              [ 33% covered ]
02. Running -eis(2,2,'2=2');                             [ 66% covered ]
03. Running -eok(3,'perl5');done_testing;                [ 100% covered ]
```

`.gitlab-ci.yml` 中的匹配模式已经设置好。

```
...
trivial-test:
  stage: trivial-test-stable
  coverage: '/(\d+)% covered/'
  ...
```

要用 Perl one-liner 测试你的匹配模式，把你的运行器的标准输出保存到文件中，例如 `/tmp/coverage.txt`，然后运行一个命令。

```bash
perl -lne 'print $1 if $_ =~ /(\d+)% covered/' <<< cat /tmp/coverage.txt
```

你会得到:

```
33
66
100
```

最高（最后）值将被 Gitlab 用作测试覆盖率的百分比。以 Pheix 的 100% 覆盖率结果为例。

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022//coverage-100-percents.png)

工作服

基础知识

Coveralls 是一种网络服务，它允许用户在一段时间内跟踪其应用程序的代码覆盖率，以优化其单元测试的有效性。Trove 包括通过 API 集成 Coveralls。

API 参考很清楚--通用对象是 job 和 source_file。源文件的数组应该被包含在作业中。

```json
{
  "service_job_id": "1234567890",
  "service_name: "Trove::Coveralls",
  "source_files": [
    {
      "name": "foo.raku",
      "source_digest": "3d2252fe32ac75568ea9fcc5b982f4a574d1ceee75f7ac0dfc3435afb3cfdd14",
      "coverage": [null, 1, null]
    },
    {
      "name": "bar.raku",
      "source_digest": "b2a00a5bf5afba881bf98cc992065e70810fb7856ee19f0cfb4109ae7b109f3f",
      "coverage": [null, 1, 4, null]
    }
  ]
}
```

工作服

基础知识

Coveralls 是一种网络服务，它允许用户在一段时间内跟踪其应用程序的代码覆盖率，以优化其单元测试的有效性。Trove 包括通过 API 集成 Coveralls。

API 参考很清楚--通用对象是 job 和 source_file。源文件的数组应该被包含在作业中。

```
...
"source_files": [
    {
      "name": "./t/01.t",
      "source_digest": "be4b2d7decf802cbd3c1bd399c03982dcca074104197426c34181266fde7d942",
      "coverage": [ 1 ]
    },
    {
      "name": "./t/02.t",
      "source_digest": "2d8cecc2fc198220e985eed304962961b28a1ac2b83640e09c280eaac801b4cd",
      "coverage": [ 1 ]
    }
  ]
...
```

我们认为没有行是被覆盖的，所以只需在 coverage 成员中设置[ 1 ]。

除了 source_files 成员，我们还需要设置一个 git 成员。它是可有可无的，但是如果没有 git 的细节（提交，分支，消息等），Coveralls 那边的构建报告会显得很无名。

你可以在 Trove::Coveralls 模块中查看 Coveralls 是如何整合的：https://github.com/pheix/raku-trove/blob/main/lib/Trove/Coveralls.rakumod。

在 Coveralls 端看起来如何

项目概述

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/coveralls/01.png)

单元测试总结

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/coveralls/02.png)

最近的构建

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/coveralls/03.png)

记录测试会话

在测试过程中，trove-cli 不打印任何 TAP 信息到标准输出。再次考虑微不足道的多解释器单行测试。

```
01. Running -eok(1,'true');                              [ 33% covered ]
02. Running -eis(2,2,'2=2');                             [ 66% covered ]
03. Running -eok(3,'perl5');done_testing;                [ 100% covered ]
```

在后台，trove-cli 会保存带有扩展测试细节的完整日志。日志文件保存在当前（工作）目录下，文件名格式为：`testreport.*.log`，其中 `*` 为测试运行日期，例如：testreport.2022-10-18_23-21-12.log。

要执行的测试命令。

```bash
cd ~/git/raku-trove && CONSTANT=2 bin/trove-cli --f=`pwd`/x/trove-configs/tests.conf.yml.oneliner --p=yq -c -l
```

日志文件 testreport.*.log 内容为。

```
----------- STAGE no.1 -----------
ok 1 - true

----------- STAGE no.2 -----------
ok 1 - 2=2

----------- STAGE no.3 -----------
ok 1 - perl5
1..1
```

对任何模块或应用程序的使用

老实说，我们可以使用 trove-cli 来测试任何软件，但显然它更适合于 Raku 或 Perl 模块和应用程序。

让我们用 Trove 试试。

    Acme::Insult::Lala: Raku module by @jonathanstowe
    Acme: Perl module by @INGY

Acme::Insult::Lala

trove-cli 可以作为独立模块使用，第一步是安装它。

```bash
zef install Trove
```

下一步是克隆 Acme::Insult::Lala 到 /tmp。

```bash
cd /tmp && git clone https://github.com/jonathanstowe/Acme-Insult-Lala.git
```

现在我们要为 Acme::Insult::Lala 模块创建 Trove 配置文件。让我们看看这个模块有多少个单元测试。

```bash
ls -la /tmp/Acme-Insult-Lala/t

# drwxr-xr-x 2 kostas kostas 4096 Oct 23 14:56 .
# drwxr-xr-x 7 kostas kostas 4096 Oct 23 15:19 ..
# -rw-r--r-- 1 kostas kostas  517 Oct 23 14:56 001-meta.t
# -rw-r--r-- 1 kostas kostas  394 Oct 23 14:56 010-basic.t
```

只有 001-meta.t 和 010-basic.t，所以配置文件应该包含。

```
target: Acme::Insult::Lala
stages:
  - test: raku /tmp/Acme-Insult-Lala/t/001-meta.t
  - test: raku /tmp/Acme-Insult-Lala/t/010-basic.t
```

把它保存到 /tmp/Acme-Insult-Lala/.run-tests.conf.yml，然后运行测试。

```
RAKULIB=lib trove-cli --f=/tmp/Acme-Insult-Lala/.run-tests.conf.yml --p=yq -l -c
```

命令输出信息:

```
01. Testing /tmp/Acme-Insult-Lala/t/001-meta.t             [ 50% covered ]
02. Testing /tmp/Acme-Insult-Lala/t/010-basic.t            [ 100% covered ]
```

跳过向 coveralls.io 发送报告。错过了 CI/CD 标识符

日志文件内容。

```
----------- STAGE no.1 -----------
1..1
# Subtest: Project META file is good
    ok 1 - have a META file
    ok 2 - META parses okay
    ok 3 - have all required entries
    ok 4 - 'provides' looks sane
    ok 5 - Optional 'authors' and not 'author'
    ok 6 - License is correct
    ok 7 - name has a '::' rather than a hyphen (if this is intentional please pass :relaxed-name to meta-ok)
    ok 8 - no 'v' in version strings (meta-version greater than 0)
    ok 9 - version is present and doesn't have an asterisk
    ok 10 - have usable source
    1..10
ok 1 - Project META file is good

----------- STAGE no.2 -----------
ok 1 - create an instance
ok 2 - generate insult
ok 3 - and its defined
ok 4 - and 'rank beef-witted hempseed' has at least five characters
ok 5 - generate insult
ok 6 - and its defined
ok 7 - and 'churlish rough-hewn flap-dragon' has at least five characters
ok 8 - generate insult
ok 9 - and its defined
ok 10 - and 'sottish common-kissing pignut' has at least five characters
ok 11 - generate insult
ok 12 - and its defined
ok 13 - and 'peevish dismal-dreaming vassal' has at least five characters
ok 14 - generate insult
ok 15 - and its defined
ok 16 - and 'brazen bunched-backed harpy' has at least five characters
ok 17 - generate insult
ok 18 - and its defined
ok 19 - and 'jaded crook-pated gudgeon' has at least five characters
ok 20 - generate insult
ok 21 - and its defined
ok 22 - and 'waggish shrill-gorged manikin' has at least five characters
ok 23 - generate insult
ok 24 - and its defined
ok 25 - and 'goatish weather-bitten horn-beast' has at least five characters
ok 26 - generate insult
ok 27 - and its defined
ok 28 - and 'hideous beef-witted maggot-pie' has at least five characters
ok 29 - generate insult
ok 30 - and its defined
ok 31 - and 'bootless earth-vexing giglet' has at least five characters
1..31
```

所有的更新都在我的 forked repo 中：https://github.com/pheix/Acme-Insult-Lala。

Acme

考虑到 Trove 已经成功安装。现在你必须下载并解压 Acme 到 /tmp/Acme-perl5。

接下来的步骤与我们为 Acme::Insult::Lala 所做的相同。

    用 ls -la /tmp/Acme-perl5/t 检查 Acme 模块的单元测试。
    将 Trove 配置文件 .run-tests.conf.yml 添加到 /tmp/Acme-perl5。

Acme 模块的 `.run-tests.conf.yml` 配置文件的内容。

```
target: Perl5 Acme v1.11111111111
stages:
  - test: perl /tmp/Acme-perl5/t/acme.t
  - test: perl /tmp/Acme-perl5/t/release-pod-syntax.t
```

用以下方式运行测试:

```bash
PERL5LIB=lib trove-cli --f=/tmp/Acme-perl5/.run-tests.conf.yml --p=yq -l -c
```

命令输出信息:

```
01. Testing /tmp/Acme-perl5/t/acme.t                       [ 50% covered ]
02. Testing /tmp/Acme-perl5/t/release-pod-syntax.t         [ SKIP ]
Skip send report to coveralls.io: CI/CD identifier is missed

Log file content:

----------- STAGE no.1 -----------
ok 1
ok 2
ok 3
1..3

----------- STAGE no.2 -----------
1..0 # SKIP these tests are for release candidate testing
```

用我的 forked repo 试试这些更新：https://gitlab.com/pheix-research/perl-acme/。
与 CI/CD 环境的集成

Github

考虑到模块 Acme::Insult::Lala，为了将 Trove 集成到 Github 行动的 CI/CD 环境中，我们必须用下面的说明创建 `.github/workflows/pheix-test-suite.yml`。

```yaml
name: CI

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest

    container:
      image: rakudo-star:latest

    steps:
      - uses: actions/checkout@v2
      - name: Perform test with Pheix test suite
        run: |
          wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod a+x /usr/local/bin/yq
          zef install Trove
          ln -s `pwd` /tmp/Acme-Insult-Lala
          cd /tmp/Acme-Insult-Lala && RAKULIB=lib trove-cli --f=/tmp/Acme-Insult-Lala/.run-tests.conf.yml --p=yq -l -c
          cat `ls | grep "testreport"`
```

CI/CD 的魔力发生在运行指令中，让我们逐行解释。

    wget ... - 手动安装 yq 二进制。
    zef install Trove - 安装 Trove 测试工具。
    ln -s ... - 创建与 .run-test.conf.yml 一致的模块路径。
    cd /tmp/Acme-Insult-Lala && ... - 运行测试。
    cat ... - 打印测试日志。

检查工作：https://github.com/pheix/Acme-Insult-Lala/actions/runs/3621090976/jobs/6104091041


![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/ci-cd/github.png)

让我们把 Perl5 模块 Acme 与 Trove 模块集成到 Gitlab CI/CD 环境中--我们必须用下面的说明创建 `.gitlab-ci.yml`。

```yaml
image: rakudo-star:latest

before_script:
  - apt update && apt -y install libspiffy-perl
  - wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod a+x /usr/local/bin/yq
  - zef install Trove
  - ln -s `pwd` /tmp/Acme-perl5
test:
  script:
    - cd /tmp/Acme-perl5 && PERL5LIB=lib trove-cli --f=/tmp/Acme-perl5/.run-tests.conf.yml --p=yq -l -c:
    - cat `ls | grep "testreport"`:
  only:
    - main
```

在 Gitlab 上，CI/CD 魔法发生在 before_script 和 test/script 指令中。行为与 Github 动作的运行指令完全相同。

检查工作: https://gitlab.com/pheix-research/perl-acme/-/jobs/3424335705


![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/ci-cd/gitlab.png)

视野：将分项测试结果整合到覆盖范围内

现在是如何工作的

如上所述，我们不覆盖源文件的行数。我们假设单元测试覆盖了所有的目标功能--如果单元测试运行成功，我们将其标记为 100% 覆盖，否则--失败：0%。粗略的说，从 Coveralls 源码覆盖的角度来看--每个需要覆盖的源码文件被最小化为巨大的单行字。

```json
{
  "name": "module.rakumod",
  "source_digest": "8d266061dcae5751eda97450679d6c69ce3dd5aa0a2936e954af552670853aa9",
  "coverage": [ 1 ]
}
```

大多数单元测试都有子测试。观点是使用子测试结果作为额外的覆盖"行"。考虑一个有几个子测试的单元测试。

```raku
use v6.d;
use Test;

plan 3;

subtest {ok(1,'true');}, 'subtest no.1';
subtest {ok(2,'true');}, 'subtest no.2';
subtest {ok(3,'true');}, 'subtest no.3';

done-testing;
```

工作服的覆盖面将是:

```json
{
  "name": "trivial.t",
  "source_digest": "d77f2fa9b43f7229baa326cc6fa99ed0ef6e1ddd56410d1539b6ade5d41cb09f",
  "coverage": [1, 1, 1]
}
```

如果其中一个子测试失败，我们将得到 66%的覆盖率，而不是目前的 0%。

后记

Bash vs Raku

实际上 Trove 的化身--Pheix 测试工具 run-tests.bash 的 bash 脚本仍然可用，可以使用与 Trove 完全相同的功能。显然 run-tests.bash 有一些与 bash 相关的优势。

    跨平台：bash 在 Linux 世界中无处不在。
    维护：bash 是通用的，bash 中的脚本被认为是自动化和测试的逻辑平台，我可以想象--从 Python 开发者的角度来看，使用 bash 编写的测试工具是可以的，但在 Raku 中使用同样的系统是可疑的，因为语言的特殊性。

run-test.bash 与外部处理器一起工作，用于解析配置文件--JSON 处理器 jq（广泛出现在不同的 Linux 发行版中）和 YAML 处理器 yq（可能是黑客/geek 的工具）。

我有一个 C 语言的项目，使用 run-test.bash 作为默认的测试工具。这个项目由 GitLab 托管，并有琐碎的 CI/CD 配置。

```yaml
test-io-database:
  coverage: '/(\d+)% covered/'
  before_script:
    ...
    - wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod a+x /usr/local/bin/yq
    - git clone https://gitlab.com/pheix-pool/core-perl6.git /pheix
    - ln -sf /pheix/run-tests.bash run-tests.bash
  script:
    ...
    - bash run-tests.bash -f .run-tests.conf.yml -p yq -l -c
  after_script:
    - cat `ls | grep "testreport"`
  artifacts:
    paths:
      - $CI_PROJECT_DIR/testreport.*
    when: always
    expire_in: 1 year
  only:
    - master
    - devel
    - merge_requests
```

我通过...跳过了项目的具体操作，但你可以在这里查看完整的 `.gitlab-ci.yml`。该管道的输出是。

```
...
$ bash run-tests.bash -f .run-tests.conf.yml -p yq -l -c
Colors in output are switch on!
Config processor yq is used
Skip delete of ./lib/.precomp folder: not existed
01. Running ./debug/test-tags                            [ 25% covered ]
02. Running ./debug/test-statuses                        [ 50% covered ]
03. Running ./debug/test-events                          [ 75% covered ]
04. Running ./debug/test-bldtab                          [ 100% covered ]
Skip send report to coveralls.io: repository token is missed
...
```

工作的输出被记录在 testreport.2022-12-07_16-36-16.log 文件中，并且可以在工作的工件中找到。覆盖率被收集并用于项目的徽章上。

![img](https://gitlab.com/pheix-research/talks/-/raw/main/advent/assets/2022/ci-cd/io-database.png)

性能

我想提到的最后一件事是性能。实际上，Trove 比 Pheix 测试套件中的 bash avatar 快 5%，几乎与 prove6 相同。

```bash
rm -rf .precomp lib/.precomp/ && time bash -c "bash run-tests.bash -c"
...

# real	1m15.644s
# user	1m44.014s
# sys	0m7.885s

rm -rf .precomp lib/.precomp/ && time trove-cli -c --f=`pwd`/run-tests.conf.yml --p=yq
...

# real	1m11.679s
# user	1m39.849s
# sys	0m8.060s

rm -rf .precomp lib/.precomp/ && time prove6 t
...

# real	1m10.110s
# user	1m38.654s
# sys	0m7.643s
```

最后，我对 Perl 证明工具感到非常惊讶--一个古老的、真正的 🇨🇭 电锯。

```bash
rm -rf .precomp lib/.precomp/ && time prove -e 'raku -Ilib'
...

# real	0m57.986s
# user	1m19.779s
# sys	0m6.465s
```


这就是全部了!

圣诞前夕是在 bash 中使用 Trove 或其头像的好时机--享受它们吧!