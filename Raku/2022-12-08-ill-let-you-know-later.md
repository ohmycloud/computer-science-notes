原文链接: https://raku-advent.blog/2022/12/08/day-8-ill-let-you-know-later/

当网络还很年轻的时候，你能知道一个资源是否改变了它的状态的唯一方法是手动重新请求页面，这在只有静态页面不经常改变的情况下并不是一个太大的问题。后来出现了服务器端的应用程序，如 CGI 等，这些程序可以以你可能感兴趣的方式更频繁地改变它们的状态，但实际上你仍然停留在刷新页面的某种变化上（尽管可能是由浏览器根据页面中的某些标签的指示发起的），所以，如果说，你有一个应用程序，它启动了一个长期运行的后台任务，它可能会将你重定向到另一个检查工作状态的页面，该页面会定期刷新自己，然后在任务完成后重定向到结果，（事实上，我知道至少有一个相当知名的报告应用程序在 2022 年仍然这样做。 )

然后在本世纪初的某个时候，随着 [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest) API 的引入，事情开始变得更加互动，它允许网页中的脚本向服务器发出请求，并根据响应适当地更新视图，从而使网页有可能反映服务器中的状态变化，而不需要任何刷新（尽管客户端脚本仍然需要在后台对服务器进行一些轮询）。然后，[WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) API 出现了，它提供了客户端和服务器之间的双向通信，以及 [Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)，它提供了服务器推送事件（以及相关数据）。

在这里，我将描述一种使用服务器发送的事件从 Raku Web 应用程序实现客户端通知的方法。

# Server-sent Events

服务器发送的事件提供了一个服务器到客户端的推送机制，该机制使用一个持久的、但其他方面标准的 HTTP 连接，并使用 Chunked 传输编码和典型的 text/event-stream 的内容类型。客户端 API 是 EventSource，被大多数现代浏览器所支持，也有一些客户端库（包括 EventSource::Client），允许非 Web 应用程序消费事件流（但那将是另一个时间。）

在服务器端，我实现了 EventSource::Server；虽然这里的例子使用的是 Cro，但它可以与任何 HTTP 服务器框架一起使用，这些框架可以接受 Supply 作为响应数据并向客户端发送分块数据，直到 Supply 完成。

从概念上讲，EventSource::Server 非常简单：它接受事件的供应，并将其转化为正确格式化的 EventSource 事件，从而以分块数据流的形式传输给客户端。

客户端部分

这是 index.html，将作为静态内容从我们的服务器上提供，这是我能想到的最简单的方法（使用 jQuery 和 Bootstrap 来简化）。本质上，它是一个向服务器发出请求的按钮，一个放置我们的 "通知"的空间，以及从服务器获取事件并显示通知的 JavaScript。

我不认为客户端的东西是我的核心能力之一，所以请原谅我的说法。

```html
<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bootstrap 101 Template</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap-theme.min.css">
 </head>
 <body>
  <main role="main" class="container-fluid">
   <div class="row">
    <div class="col"></div>
    <div class="col-8 text-center">
     <a href="button-pressed" class="btn btn-danger btn-lg active" role="button" aria-pressed="true">Press Me!</a>
    </div>
    <div class="col" id="notification-holder"></div>
   </div>
  </main>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/js/bootstrap.min.js"></script>
  <script>
    var sse;
    function createNotification(message, type) {
      var html = '<div class="shadow bg-body rounded alert alert-' + type + ' alert-dismissable page-alert">';
      html += '<button type="button" data-dismiss="alert" class="close"><span aria-hidden="true">×</span><span class="sr-only">Close</span></button>';
      html += message;
      html += '</div>';
      $(html).hide().prependTo('#notification-holder').slideDown();
    };
    function notificationHandler(e) {
      const message = JSON.parse(event.data);
      createNotification(message.message, message.type);
    };
    function setupNotifications() {
      if ( sse ) {
        sse.removeEventListener("notification", notificationHandler);
        sse.close;
      }
 	 
      sse = new EventSource('/notifications');
      sse.addEventListener("notification", notificationHandler );
      $('.page-alert .close').click(function(e) {
        e.preventDefault();
        $(this).closest('.page-alert').slideUp();
      });
      return sse
    };
    setupNotifications();
  </script>
 </body>
</html>
```

从本质上讲，Javascript 设置了 EventSource 客户端，以消费我们将在 `/notifications` 上发布的事件，并添加了一个 Listener，它解析了事件中的 JSON 数据（它不一定是 JSON，但我发现这是最方便的，），然后在 DOM 中插入 "通知"。剩下的部分主要是 Bootstrap 的东西，用于驳回通知。

当然，你可以在任何其他客户端框架（Angular、React 或任何新的热点）中实现这一点，但我们在这里是为了 Raku 而不是 Javascript。

总之，这一点不会有任何改变，所以如果你真的想运行这些例子，你可以保存它并忘记它。
服务器端

我们的应用程序的服务器部分主要是一个简单的 Cro::HTTP 应用程序，有三个路由：一个用于提供我们上面的 index.html，另一个用于处理按钮推送请求，显然还有一个路由用于提供 `/notifications` 上的事件流。

为了方便阐述，这些都被捆绑在一个脚本中，在现实世界的应用中，你几乎肯定要把它分割成几个文件。

```raku
class NotificationTest {
    use Cro::HTTP::Server;
    has Cro::Service $.http;

    class Notifier {
        use EventSource::Server;
        use JSON::Class;

        has Supplier::Preserving $!supplier = Supplier::Preserving.new;

        enum AlertType is export (
          Info    => "info",
          Success => "success",
          Warning => "warning",
          Danger  => "danger"
        );

        class Message does JSON::Class {
            has AlertType $.type is required is marshalled-by('Str');
            has Str $.message is required;
            has Str $.event-type = 'notification';
        }

        method notify(
          AlertType  $type,
              Str()  $message,
              Str  :$event-type = 'notification'
        --> Nil ) {
            $!supplier.emit:
              Message.new(:$type, :$message :$event-type );
        }

        multi method event-stream( --> Supply) {
            my $supply = $!supplier.Supply.map: -> $m {
                EventSource::Server::Event.new(
                  type => $m.event-type,
                  data => $m.to-json(:!pretty)
                )
            }
            EventSource::Server.new(
              :$supply,
              :keepalive,
              keepalive-interval => 10
            ).out-supply;
        }
    }

    class Routes {
        use Cro::HTTP::Router;

        has Notifier $.notifier
          handles <notify event-stream> = Notifier.new;

        method routes() {
            route {
                get -> {
                    static $*PROGRAM.parent, 'index.html';
                }
                get -> 'notifications' {
                    header 'X-Accel-Buffering', 'no';
                    content 'text/event-stream', $.event-stream();
                }
                get -> 'button-pressed' {
                    $.notify(Notifier::Info, 'Someone pressed the button');
                }
            }
        }
    }

    has $.routes-object;

    method routes-object( --> Routes ) handles <routes> {
        $!routes-object //= Routes.new();
    }

    method http( --> Cro::Service ) handles <start stop> {
        $!http //= Cro::HTTP::Server.new(
          http => <1.1>,
          host => '0.0.0.0',
          port => 9999,
          application => $.routes,
        );
    }
}

multi sub MAIN() {
    my NotificationTest $http = NotificationTest.new;
    $http.start;
    say "Listening at https://127.0.0.1:9999";
    react {
        whenever signal(SIGINT) {
            $http.stop;
            done;
        }
    }
}
```

这没有什么特别不寻常的地方，但你可能会发现，几乎所有的事情都发生在 Notifier 类中。路由被定义在 Routes 类的一个方法中，因此 Notifier 的关键方法可以从该类的一个实例中被委托，这比拥有一个全局对象要好，但也使得在运行时重构甚至替换 Notifier 更容易（例如，可能是为了本地化消息。）

Notifier 类本身可以被认为是 EventSource::Server 的封装器，有一个 Supplier（这里是 Supplier::Preserving，对这种情况更好），Message 的对象或通过 notify 方法发出的对象，Message 类消耗 JSON::Class，这样在创建最终事件时可以很容易地被序列化为 JSON，输出到事件流。这里的 EventType 枚举映射到所产生的通知 HTML 中的 CSS 类，影响通知显示的颜色。

这里的大部分动作实际上是在事件流方法中进行的，它构建了输出到客户端的流。

```raku
multi method event-stream( –> Supply) {
    my $supply = $!supplier.Supply.map: -> $m {
        EventSource::Server::Event.new(
          type => $m.event-type,
          data => $m.to-json(:!pretty)
        )
    }
    EventSource::Server.new(
      :$supply,
      :keepalive,
      keepalive-interval => 10
    ).out-supply;
} 
```

这映射了从我们的 Supplier 派生出来的 Supply，使 Message 对象被序列化并包裹在 `EventSource::Server::Event` 对象中，然后产生的新 Supply 被传递给 EventSource::Server。out-supply 返回一个进一步的 Supply，它发出适合作为 Cro 路由中内容传递的编码事件流数据。严格来说，在事件中包装消息并不是必须的，因为 EventSource::Server 会在内部进行包装，但这样做可以控制类型，也就是在你的 Javascript 中添加事件监听器时指定的事件类型，因此，例如，你可以在你的流中发射不同类型的事件，并在 Javascript 中为每个事件设置不同的监听器，每个事件对你的页面有不同的影响。

/notifications 的路由可能值得仔细检查。

```raku
get -> 'notifications' {
    header 'X-Accel-Buffering', 'no';
    content 'text/event-stream', $.event-stream();
} 
```

首先，除非你有特殊原因，否则内容类型应该总是文本/事件流，否则客户端将无法识别流，而且，至少在我尝试过的所有实现中，将只是烦人地坐在那里什么都不做。在这个例子中，这里的标头并不是严格必要的，但是如果你的客户将通过一个反向代理（如 nginx）访问你的应用程序，那么你可能需要提供这个标头（或一个特定于你的代理的标头），以防止代理缓冲你的流，这可能导致事件永远不会被传递到客户端。

但是，如果不希望每个人都得到同样的通知呢？

这一切都很好，但对于大多数应用程序来说，你可能想发送通知给特定的用户（或会话），我们的应用程序的所有用户不可能对有人按下按钮感兴趣，所以我们将使用 Cro:HTTP::Session::InMemory 引入会话的概念，这具有非常简单的实现（和内置）的优势。

对我们原来的例子的改动其实很小（为了保持简单，我省略了任何认证：)

```raku
class NotificationTest {
    use Cro::HTTP::Server;
    use Cro::HTTP::Auth;

    has Cro::Service $.http;

    class Session does Cro::HTTP::Auth {
        has Supplier $!supplier handles <emit Supply> = Supplier.new;
    }

    class Notifier {
        use EventSource::Server;
        use JSON::Class;

        enum AlertType is export (
          Info    => "info",
          Success => "success",
          Warning => "warning",
          Danger  => "danger"
        );

        class Message does JSON::Class {
            has AlertType $.type is required is marshalled-by('Str');
            has Str $.message is required;
            has Str $.event-type = ‘notification‘;
        }

        method notify(
          Session   $session,
          AlertType $type,
              Str() $message,
              Str  :$event-type = 'notification'
        –> Nil) {
            $session.emit: Message.new(:$type, :$message :$event-type );
        }

        multi method event-stream(Session $session, –> Supply) {
            my $supply = $session.Supply.map: -> $m {
                EventSource::Server::Event.new(
                  type => $m.event-type,
                  data => $m.to-json(:!pretty)
                )
            }
            EventSource::Server.new(
              :$supply,
              :keepalive,
              keepalive-interval => 10
            ).out-supply;
        }
    }

    class Routes {
        use Cro::HTTP::Router;
        use Cro::HTTP::Session::InMemory;

        has Notifier $.notifier handles <notify event-stream> = Notifier.new;

        method routes() {
            route {
                before Cro::HTTP::Session::InMemory[Session].new;
                get -> Session $session {
                    static $*PROGRAM.parent, ‘index.html‘;
                }
                get -> Session $session, ‘notifications‘ {
                    header ‘X-Accel-Buffering‘, ‘no‘;
                    content ‘text/event-stream‘, $.event-stream($session);
                }
                get -> Session $session, ‘button-pressed‘ {
                    $.notify($session, Notifier::Info, ‘You pressed the button‘);
                }
            }
        }
    }

    has $.routes-object;

    method routes-object( –> Routes ) handles <routes> {
        $!routes-object //= Routes.new();
    }

    method http( –> Cro::Service ) handles <start stop> {
        $!http //= Cro::HTTP::Server.new(
          http => <1.1>,
          host => ‘0.0.0.0‘,
          port => 9999,
          application => $.routes,
        );
    }
}

multi sub MAIN() {
    my NotificationTest $http = NotificationTest.new;
    $http.start;
    say “Listening at https://127.0.0.1:9999“;
    react {
        whenever signal(SIGINT) {
            $http.stop;
            done;
        }
    }
}
```

正如你所看到的，大部分代码保持不变，我们引入了一个新的 Session 类，并对 Notifier 方法和路由做了一些修改。

会话类在一个新的会话开始时被实例化，并将被保存在内存中，直到会话过期。

```raku
class Session does Cro::HTTP::Auth {
    has Supplier $!supplier
      handles <emit Supply> = Supplier.new;
} 
```

因为同一个对象会保留在内存中，我们可以用一个按会话的 Supplier 来代替 Notifier 对象的单一 Supplier，同一个 Session 对象在会话的有效期内被传递给路由。

```raku
method routes() {
    route {
        before Cro::HTTP::Session::InMemory[Session].new;
        get -> Session $session {
            static $*PROGRAM.parent, 'index.html';
        }
        get -> Session $session, 'notifications' {
            header 'X-Accel-Buffering', 'no';
            content 'text/event-stream', $.event-stream($session);
        }
        get -> Session $session, 'button-pressed' {
            $.notify($session, Notifier::Info, 'You pressed the button');
        }
    }
} 
```

Cro::HTTP::Session::InMemory 被介绍为一个中间件，它可以处理会话的创建或检索，在请求被传递到适当的路由之前设置会话 cookie 等等。如果一个路由块的第一个参数的类型是 Cro::HTTP::Auth，那么会话对象将被传递，你可以通过使用你的会话类的更具体的子集来做有趣的认证和授权的事情，但我们在这里不需要，我们只是将会话对象传递给修改的 Notifier 方法。

```raku
method notify(
    Session $session,
  AlertType $type,
      Str() $message,
       Str :$event-type = 'notification'
–> Nil) {
        $session.emit: Message.new(:$type, :$message :$event-type );
}
     
multi method event-stream( Session $session, –> Supply) {
    my $supply = $session.Supply.map: -> $m {
        EventSource::Server::Event.new(
          type => $m.event-type,
          data => $m.to-json(:!pretty)
        )
    }
    EventSource::Server.new(
      :$supply,
      :keepalive,
      keepalive-interval => 10
    ).out-supply;
} 
```

通知和事件流都被简单地修改为将 Session 对象作为第一个参数，并使用 Session 自己的 Supplier 上的（委托的）方法，而不是 Notifier 的共享方法。

现在每个"用户"都可以得到他们自己的通知，这个按钮可以启动一个长期运行的工作，当它完成时，他们可以得到通知。你可以通过在 Notifier 中放回共享的 Supplier 来扩展做"广播"通知，做第二个不需要 Session 的 notify 的多候选人，它将发射到该 Supplier，然后在事件流方法中合并共享和特定实例的 Supplier。

但如果我的应用程序有多个实例呢？

你现在可能已经知道了，如果你有一个以上的应用程序实例，使用"内存"会话是行不通的，你也许可以在负载均衡器上设置"粘性会话"，但可能不是你想依赖的东西。

我们需要的是一个共享的通知源，所有的新通知都可以被添加到这个通知源中，每个实例都可以从中获取要发送的通知。

为此，我们可以使用 PostgreSQL 数据库，它有一个 NOTIFY，允许服务器向所有要求接收通知的连接客户端发送通知。

在修改后的应用程序中，我们将使用 Red 来访问数据库（加上 DB::Pg 的一个功能，从服务器上消耗通知）。

对于我们的简单应用，我们只有一个表来保存通知，和一个表来保存会话（使用 Cro::HTTP::Session::Red，），所以让我们先把它们做好。

```sql
CREATE FUNCTION public.new_notification() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
    PERFORM pg_notify(‘notifications‘, ‘‘ || NEW.id || ‘‘);
    RETURN NEW;
    END;
    $$;
     
    CREATE TABLE public.notification (
      id uuid NOT NULL,
      session_id character varying(255),
      type character varying(255) NOT NULL,
      message character varying(255) NOT NULL,
      event_type character varying(255) NOT NULL
    );
     
    CREATE TABLE public.session (
      id character varying(255) NOT NULL
    );
     
    ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);
     
    ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);
     
    CREATE TRIGGER notification_trigger AFTER INSERT ON public.notification FOR EACH ROW EXECUTE PROCEDURE public.new_notification();
     
    ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.session(id); 
```

我在这个例子中使用了一个叫做 notification_test 的数据库。通知表有类似于消息类属性的列，增加了 id 和 session_id，在插入时有一个触发器，发送带有新行 id 的 Pg 通知，这将被应用程序所使用。

会话表只有必要的 id 列，在创建新的会话时，会话中间件将填充该列。

与第一个例子相比，代码有一些变化，但大部分的变化是为两个 DB 表引入 Red 模型，并重新设计 Notifier 的工作方式。

```raku
class NotificationTest {
    use Cro::HTTP::Server;
    use Cro::HTTP::Auth;
    use UUID;
    use Red;
    use Red::DB;
    need Red::Driver;
    use JSON::Class;
    use JSON::OptIn;
     
    has Cro::Service $.http;
     
    model Message {
        …
    }
     
    model Session is table('session') does Cro::HTTP::Auth {
        has Str $.id is id;
        has @.messages
          is relationship({ .session-id }, model => Message )
          is json-skip;
    }
     
    enum AlertType is export (
      Info    => "info",
      Success => "success",
      Warning => "warning",
      Danger  => "danger"
    );
     
    model Message is table('notification') does JSON::Class {
        has Str $.id is id is marshalled-by('Str') = UUID.new.Str;
        has Str $.session-id is referencing(model => Session, column => 'id' ) is json-skip;
        has AlertType $.type is column is required is marshalled-by('Str');
        has Str $.message is column is required is json;
        has Str $.event-type is column is json = 'notification';
    }
     
    has Red::Driver $.database = database 'Pg', dbname => 'notification_test';
     
    class Notifier {
        use EventSource::Server;

        has Red::Driver $.database;
     
        method database(–> Red::Driver) handles <dbh> {
            $!database //= get-RED-DB();
        }
     
        has Supply $.message-supply;
     
        method message-supply( –> Supply ) {
            $!message-supply //= supply {
                whenever $.dbh.listen('notifications') -> $id {
                    if Message.^rs.grep(-> $v { $v.id eq $id }).head -> $message {
                        emit $message;
                    }
                }
            }
        }
     
        method notify(
          Session   $session,
          AlertType $type,
              Str() $message,
               Str :$event-type = 'notification'
        –> Nil ) {
            Message.^create(
              session-id => $session.id, :$type, :$message :$event-type
            );
        }
     
        multi method event-stream( Session $session, –> Supply) {
            my $supply = $.message-supply.grep( -> $m {
                $m.session-id eq $session.id
            }).map( -> $m {
                EventSource::Server::Event.new(
                  type => $m.event-type,
                  data => $m.to-json(:!pretty)
                )
            });
            EventSource::Server.new(
              :$supply,
              :keepalive,
              keepalive-interval => 10
            ).out-supply;
        }
    }
         
    class Routes {
        use Cro::HTTP::Router;
        use Cro::HTTP::Session::Red;
     
        has Notifier $.notifier
          handles <notify event-stream> = Notifier.new;
     
        method routes() {
            route {
                before Cro::HTTP::Session::Red[Session].new: cookie-name => 'NTEST_SESSION';
                get -> Session $session {
                    static $*PROGRAM.parent, 'index.html';
                }
                get -> Session $session, 'notifications' {
                    header 'X-Accel-Buffering', 'no';
                    content 'text/event-stream', $.event-stream($session);
                }
                get -> Session $session, 'button-pressed' {
                    $.notify($session, Info, 'You pressed the button');
                }
            }
        }
    }
     
    has $.routes-object;
     
    method routes-object( –> Routes ) handles <routes> {
        $!routes-object //= Routes.new();
    }
     
    method http( –> Cro::Service ) handles <start stop> {
        $!http //= Cro::HTTP::Server.new(
          http => <1.1>,
          host => '0.0.0.0',
          port => 9999,
          application => $.routes,
        );
    }
}
     
multi sub MAIN() {
    my NotificationTest $http = NotificationTest.new;
    $GLOBAL::RED-DB = $http.database;
    $http.start;
    say "Listening at https://127.0.0.1:9999";
    react {
        whenever signal(SIGINT) {
            $http.stop;
            done;
        }
    }
} 
```

我将略过 Red 模型的定义，因为这应该是很明显的，除了注意到消息模型也做了 JSON::Class，它允许实例被序列化为 JSON（就像原来的例子，），所以不需要额外的代码来创建发送到客户端的事件。

主要的变化是在 Notifier 类中引入了 message-supply，它创建了一个按需供应），取代了第一个例子的共享 Supplier 和第二个例子的 per-session Supplier。

```raku
has Supply $.message-supply;
 	 
method message-supply( –> Supply ) {
    $!message-supply //= supply {
        whenever $.dbh.listen('notifications') -> $id {
            if Message.^rs.grep(-> $v { $v.id eq $id }).head -> $message {
                emit $message;
            }
        }
    }
} 
```

这是由底层的 DB::Pg 提供的 Pg 通知的供应，（参考上面描述的 SQL 触发器，）发射数据库中新创建的通知行的 id，然后通知行被检索出来，然后发射到消息供应上。

通知方法被改变以插入消息到通知表中。

```raku
method notify(
  Session $session,
  AlertType $type,
  Str() $message,
  Str :$event-type = 'notification'
–> Nil ) {
        Message.^create(session-id => $session.id, :$type, :$message :$event-type );
} 
```

该方法的签名是不变的，所提供的会话 ID 被插入到消息中。

事件流方法需要被改变，以处理来自消息供应的消息对象，并只选择那些被请求的会话。

```raku
multi method event-stream( Session $session, –> Supply) {
    my $supply = $.message-supply.grep( -> $m {
        $m.session-id eq $session.id
    }).map( -> $m {
        EventSource::Server::Event.new(
          type => $m.event-type,
          data => $m.to-json(:!pretty)
        )
    });
    EventSource::Server.new(
      :$supply,
      :keepalive,
      keepalive-interval => 10
    ).out-supply;
} 
```

基本上就是这样，有一点额外的脚手架来处理数据库，但不是一个特别大的变化。

还有什么？

为了简洁起见，我在这些例子中省略了任何认证，但如果你想有每个用户的通知，那么，如果你有认证的用户，你可以把用户 ID 添加到消息中，并在用户与会话匹配的地方进行过滤。

如果你想继续使用数据库，而不是使用 Pg 通知，你可以作为一个后台任务反复查询通知表以获取新的通知。或者你可以使用一些消息队列来传达通知（例如 ActiveMQ 主题或 RabbitMQ 扇出交换）。

但是现在你可以告诉你的用户在应用程序中发生了什么，而不需要他们做任何事情。