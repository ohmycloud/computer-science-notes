原文链接: https://raku-advent.blog/2022/12/19/day-19-a-few-modules-to-ease-working-with-databases-in-raku-applications/

第19天：在 Raku 应用程序中简化数据库工作的几个模块

目前，我没有一个大型的 Raku 应用程序，但有很多小型的应用程序，我需要不时地做一些工作。几乎所有的应用都涉及到使用数据库的持久性；我倾向于使用 Postgres。今年，我把一些 Raku 模块放在一起，以减轻我在这些项目中使用数据库的工作。所有这些模块都可以通过 zef 安装；也许有些模块会成为送给其他使用 Raku 和数据库的人的漂亮圣诞礼物。

就让我在本地开发这个东西吧!

当我在本地机器上开发的应用程序使用数据库时，我应该如何运行它？我可以使用系统 Postgres，创建一个数据库，用户，等等。当然，这不是我每天都做的任务，甚至不是每个月都做，所以我每次都要去查一下语法。那么，如果部署环境中的 Postgres 版本与我的系统中的版本不同呢？在这样一个成熟的产品中，这不可能是一个经常出现的问题，但也许有一天它会成为一个绊脚石的危险。

值得庆幸的是，容器技术已经使大多数东西都能在自己选择的版本中旋转起来，这一点非常容易。Postgres 容器是现成的。这仍然需要一些脚本和管道来启动容器，创建所需的数据库和用户，并在运行应用程序之前注入环境变量。我已经做了很多次，用了很多方法。这很容易，但很无聊。

什么不那么无聊？当然是写一个 Raku 模块，把重复的工作拿掉。因此，`Dev::ContainerizedService`。现在我只需要写一个 devenv.raku，像这样。

```raku
#!/usr/bin/env raku
use Dev::ContainerizedService;
 
service 'postgres', :tag<13.0>, -> (:$conninfo, *%) {
    env 'DB_CONN_INFO', $conninfo;
}
```

这足以让 Postgres 13.0 docker 容器被拉出（如果需要的话），然后启动，并创建一个数据库和用户。然后，这些被注入到应用程序的环境中；在这种情况下，我的应用程序被期望在 `%*ENV<DB_CONN_INFO>` 中有一个 Postgres 连接字符串。

然后我可以通过这个脚本运行我的应用程序:

```bash
./devenv.raku run raku -I. service.raku
```

Postgres 实例在主机网络上运行，并选择了一个空闲的端口，这对于我同时有几个不同的项目的时候是非常好的。如果我使用 `cro` 和开发运行程序，在变化时重新启动服务，那就是。

```bash
./devenv.raku run cro run
```

默认情况下，每次我运行它时，它都会创建一个废弃的数据库。如果我想让数据库在两次运行之间持续存在，我需要添加一个项目名称，并指定它应该持久地存储数据。

```raku
#!/usr/bin/env raku
use Dev::ContainerizedService;

project 'my-app';
store;
 
service 'postgres', :tag<13.0>, -> (:$conninfo, *%) {
    env 'DB_CONN_INFO', $conninfo;
}
```

有时，出于调试的原因，我想用 `psql shell` 来探查数据库。这可以用:

```bash
./devenv.raku tool postgres client
```

请看文档，了解一些更高级的功能，以及如何增加对更多服务的支持（我已经做了 Postgres 和 Redis，因为这些是我的直接用途）。

我希望集成测试能触及到数据库!

使用 `Test::Mock` 之类的东西对数据库进行单元测试，都是很好的，但我真的认为我的数据访问代码是完美的吗？当然不是；它也需要测试。

当然，这意味着一些管道。建立一个测试数据库。在 CI 环境中做同样的事情。我以前已经做过十几次了。这很容易。这很无聊。为什么我不能有一个 Raku 模块来消除这种乏味呢？

好吧，如果我写的话，我可以。因此 `Test::ContainerizedService`，`Dev::ContainerizedService` 的后裔。它实际上是 `Dev::ContainerizedService` 核心的一个小包装，这意味着人们只需要在 `Dev::ContainerizedService` 中添加对数据库或队列的支持，然后它在 `Test::ContainerizedService` 中也可以使用。

使用它看起来像这样:

```raku
use Test;
use Test::ContainerizedService;
use DB::Pg;
 
# Either receive a formed connection string:
test-service 'postgres', :tag<14.4> -> (:$conninfo, *%) {
    my $pg = DB::Pg.new(:$conninfo);
    # And now there's a connection to a throwaway test database
}
```

简而言之，将测试封装在一个 `test-service` 块中，该块做了让 Postgres 容器启动和运行所需的工作，然后传入连接信息。如果 docker 不可用，测试将被跳过。

迁移怎么办？

前面的两份礼物已经准备好在今年圣诞节拆开了。我还在开发一个可能只有冒险者才能拆开的礼物。`DB::Migration::Declare`。

这并不是 Raku 在数据库迁移方面的第一次努力--也就是说，有一个有序的、仅有附录的数据库变化列表，共同将数据库模式提升到当前状态的想法。Red ORM 在这个方向上有一些工作，对于那些使用 Red 的人来说。还有一个模块，在那里你可以写出 SQL DDL 的上下步骤，并应用它们。我已经用过了，它很有效。但是受到 Knex.js 迁移的好处和缺点的启发，我今年在一个客户那里使用了很多，我决定在 Raku 中建立类似的东西。

这个想法相对简单：使用 Raku DSL 来指定迁移，并使用 SQL 来使变化生效。假设我们想要一个数据库表来跟踪最高的摩天大楼，我们可以这样写:

```raku
use DB::Migration::Declare;
 
migration 'Setup', {
    create-table 'skyscrapers', {
        add-column 'id', integer(), :increments, :primary;
        add-column 'name', text(), :!null, :unique;
        add-column 'height', integer(), :!null;
    }
}
```

假设它在文件 migrations.raku 中，与应用程序的入口脚本一起，我们可以添加这样的代码:

```raku
use DB::Migration::Declare::Applicator;
use DB::Migration::Declare::Database::Postgres;
use DB::Pg;
 
my $conn = $pg.new(:conninfo(%*ENV<DB_CONN_INFO>));
 
my $applicator = DB::Migration::Declare::Applicator.new:
        schema-id => 'my-project',
        source => $*PROGRAM.parent.add('migrations.raku'),
        database => DB::Migration::Declare::Database::Postgres.new,
        connection => $conn;
my $status = $applicator.to-latest;
note "Applied $status.migrations.elems() migration(s)";
```

在应用程序启动时，它将检查我们写的迁移是否已经应用到数据库中，如果没有，就将其翻译成 SQL 并应用。

如果稍后我们意识到我们还想知道每个摩天大楼在哪个国家，我们可以在这第一个迁移之后再写第二个迁移:

```raku
migration 'Add countries', {
    create-table 'countries', {
        add-column 'id', integer(), :increments, :primary;
        add-column 'name', varchar(255), :!null, :unique;
    }
 
    alter-table 'skyscrapers',{
        add-column 'country', integer();
        foreign-key table => 'countries', from => 'country', to => 'id';
    }
}
```

在启动我们的应用程序时，它将检测到最新的迁移还没有被应用，并这样做。

然而，`DB::Migration::Declare` 并不只是从 Raku 代码中产生模式变化的 SQL。它还维护了一个数据库的当前状态的模型。因此，如果我之前的迁移有一个这样的错字。

```raku
alter-table 'skyskrapers',{
    add-column 'country', integer();
    foreign-key table => 'countries', from => 'country', to => 'id';
}
```

它可以检测到它并让我知道，甚至在它试图建立 SQL 之前。
	
```
Migration at migrations.raku:11 has problems:
  Cannot alter non-existent table 'skyskrapers'
```

它检测到了一系列这样的错误--不仅是错别字，还有语义问题，比如试图删除一个已经被删除的表，或者添加一个重复的主键。

开发环境、测试环境和迁移

虽然不是黄金、乳香和没药，但我希望其他人也会发现这些东西很有用。干杯!