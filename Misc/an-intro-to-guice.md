# guice 入门

https://github.com/google/guice/wiki/ 是谷歌出的依赖注入。

## 绑定

注入器(injector)的工作是组装对象图。你请求一个给定类型的实例，它会确定要构建的内容，解析依赖关系，并将所有内容连接在一起。要指定如何解析依赖关系，请使用绑定配置该注入器。

### 创建绑定

要创建绑定，请扩展 `AbstractModule` 并重写其 `configure` 方法。在方法体中，调用 `bind()` 来指定每个绑定。这些方法是带有类型检查的，因此如果使用错误的类型，编译器可以报告错误。创建模块后，将它们作为参数传递给 `Guice.createInjector()` 以构建注入器。

使用模块来创建 [linked bindings](https://github.com/google/guice/wiki/LinkedBindings), [instance bindings](https://github.com/google/guice/wiki/InstanceBindings), [@Provides methods](https://github.com/google/guice/wiki/ProvidesMethods), [provider bindings](https://github.com/google/guice/wiki/ProviderBindings), [constructor bindings](https://github.com/google/guice/wiki/ToConstructorBindings) 和 [untargetted bindings](https://github.com/google/guice/wiki/UntargettedBindings).

### 更多绑定

除了您指定的绑定外，注入器还包含[内置绑定](https://github.com/google/guice/wiki/BuiltInBindings)。当请求的依赖项未找到时，它会尝试创建[即时绑定](https://github.com/google/guice/wiki/JustInTimeBindings)。注入器还包括用于其他绑定的[providers](https://github.com/google/guice/wiki/InjectingProviders)的绑定。


## 关联绑定

关联绑定将类型映射到它的实现上。这个例子将接口 `TransactionLog` 映射到 `DatabaseTransactionLog` 实现上：

```java
public class BillingModule extends AbstractModule {
  @Override 
  protected void configure() {
    bind(TransactionLog.class).to(DatabaseTransactionLog.class);
  }
}
```

现在, 当你调用  `injector.getInstance(TransactionLog.class)` 时, 或者当注入器遇到对 `TransactionLog` 的依赖时, 它就会使用 `DatabaseTransactionLog`。从一个类型关联到它的子类型中的任何一个, 例如实现类或扩展类。你甚至可以将具体的 `DatabaseTransactionLog` 类关联到子类上：

```java
bind(DatabaseTransactionLog.class).to(MySqlDatabaseTransactionLog.class);
```

关联绑定还可以链接到一块儿：

```java
public class BillingModule extends AbstractModule {
  @Override 
  protected void configure() {
    bind(TransactionLog.class).to(DatabaseTransactionLog.class);
    bind(DatabaseTransactionLog.class).to(MySqlDatabaseTransactionLog.class);
  }
}
```

在这个情况下, 当要求 `TransactionLog` 时, 注入器会返回 `MySqlDatabaseTransactionLog`。

# 实例绑定

您可以将类型绑定到该类型的特定实例上。这通常仅适用于不具有自己的依赖关系的对象，例如值对象：

```java
bind(String.class)
        .annotatedWith(Names.named("JDBC URL"))
        .toInstance("jdbc:mysql://localhost/pizza");
bind(Integer.class)
        .annotatedWith(Names.named("login timeout seconds"))
        .toInstance(10);
```

避免将 `.toInstance` 用于创建复杂的对象，因为它会减慢应用程序的启动速度。您可以改为使用@ `Provides` 方法。

# @Provides 方法

当你需要代码来创建一个对象时，使用 `@Provides` 方法。该方法必须在模块中定义，并且必须具有 `@Provides` 注解。该方法的返回类型是绑定类型。只要注入器需要该类型的实例，它就会调用该方法。

```java
public class BillingModule extends AbstractModule {
  @Override
  protected void configure() {
    ...
  }

  @Provides
  TransactionLog provideTransactionLog() {
    DatabaseTransactionLog transactionLog = new DatabaseTransactionLog();
    transactionLog.setJdbcUrl("jdbc:mysql://localhost/pizza");
    transactionLog.setThreadPoolSize(30);
    return transactionLog;
  }
}
```

如果 `@Provides` 方法具有像 `@PayPal` 或 `@Named("Checkout")`这样的绑定注释，Guice 绑定注释类型。依赖关系可以作为参数传递给方法。在调用该方法之前，注射器将为每个注入器执行绑定。

```java
 @Provides @PayPal
  CreditCardProcessor providePayPalCreditCardProcessor(
      @Named("PayPal API key") String apiKey) {
    PayPalCreditCardProcessor processor = new PayPalCreditCardProcessor();
    processor.setApiKey(apiKey);
    return processor;
  }
```

## 抛出异常

Guice 不允许从 Providers 抛出异常。 `@Provides` 方法引发的异常将被包装在 `ProvisionException` 中。允许从 `@Provides` 方法抛出任何类型的异常（运行时或检查）是不好的做法。如果由于某种原因需要抛出异常，则可能需要使用 [ThrowingProviders 扩展](https://github.com/google/guice/wiki/ThrowingProviders) 的 `@CheckedProvides` 方法。

## Provider 绑定

当你的 `@Provides` 方法开始变得复杂时, 你可以考虑将它们移动到自己的类中。provider 类实现了 Guice 的 `Provider` 接口，这是一个用于提供值的简单通用接口：

```java
public interface Provider<T> {
  T get();
}
```

我们的 provider 实现类具有自己的依赖关系，它通过 `@Inject`-annotated 构造函数接收。它实现了 `Provider` 接口，用于定义具有完整类型安全性的返回内容：

```java
public class DatabaseTransactionLogProvider implements Provider<TransactionLog> {
  private final Connection connection;

  @Inject
  public DatabaseTransactionLogProvider(Connection connection) {
    this.connection = connection;
  }

  public TransactionLog get() {
    DatabaseTransactionLog transactionLog = new DatabaseTransactionLog();
    transactionLog.setConnection(connection);
    return transactionLog;
  }
}
```

最后，我们使用 `.toProvider` 子句绑定到提供者(provider)：

```java
public class BillingModule extends AbstractModule {
  @Override
  protected void configure() {
    bind(TransactionLog.class)
        .toProvider(DatabaseTransactionLogProvider.class);
  }
```

如果你的 providers 很复杂，请务必测试它们！

## 无目标绑定

创建没有目标的绑定。

你可以在不指定目标的情况下创建绑定。这对于由 `@ImplementedBy` 或 `@ProvidedBy` 注解的具体类和类型最有用。无目标绑定通知注入器有关类型的信息，因此它可能会急切地准备依赖关系。 无目标绑定没有子句，如下所示：

```java
bind(MyConcreteClass.class);
bind(AnotherConcreteClass.class).in(Singleton.class);
```

指定绑定注解时，你仍必须添加目标绑定，即使它是相同的具体类。例如：

```java
    bind(MyConcreteClass.class)
        .annotatedWith(Names.named("foo"))
        .to(MyConcreteClass.class);
    bind(AnotherConcreteClass.class)
        .annotatedWith(Names.named("foo"))
        .to(AnotherConcreteClass.class)
        .in(Singleton.class);
```

https://blog.csdn.net/xtayfjpk/article/details/40657781

# 学习 Guice（一）：第一个 Guice 应用

原文在：http://dyingbleed.com/guice-1/, http://dyingbleed.com/guice-2/, http://dyingbleed.com/guice-3/, 这儿照搬下来, 放在一块

Guice 是 Google 开发并开源的轻量级 DI （依赖注入）框架

GitHub 地址：[https://github.com/google/guice](https://github.com/google/guice)

## 依赖

编辑 pom.xml 文件, 添加依赖:

```
<dependency>  
    <groupId>com.google.inject</groupId>
    <artifactId>guice</artifactId>
    <version>4.1.0</version>
</dependency>  
```

## 绑定

定义模块类, 继承 `com.google.inject.AbstractModule` 抽象类, 实现 `configure` 方法。在 configure 方法内部, 绑定(调用 bind 方法)接口到实现类(调用 to 方法)。例子：

```java
public class ApplicationModule extends AbstractModule {
    @override
    protected void configure() {
        bind(UserService.class).to(UserServiceImpl.class);
    }
}
```

从名字可以看出, Impl 就是 Implement, `bind(UserService.class).to(UserServiceImpl.class);` 这句的意思就是把接口和实现绑定到一块。

## 注入

使用 👆 配置的 ApplicationModule 模块创建 Injector 注入器, 之后, 即可通过注入器获取实例:

```java
Injector injector = Guice.createInjector(new ApplicationModule());
Application app = injector.getInstance(Application.class);
```

通过 `@Inject` 注解, 注入绑定到 UserService 接口的实现类 UserServiceImpl

```java
@Inject
private UserService userService;
```

完整的例子：

```java
public class Application {
    @inject
    private UserService userService;

    public static void main(String[] args) {
        Injector injector = Guice.createInjector(new ApplicationModule());
        Application app = injector.getInstance(Application.class);
        app.run;
    }

    public void run()  {
        // use userService do something 
    }
}
```
# 学习 Guice（二）：Spark 依赖注入

## 绑定

```scala
class ApplicationModule(spark: SparkSession, date: LocalDate) extends AbstractModule {
    override def configure(): Unit = {
        bind(classOf[SparkSession]).toInstance(spark) // ①
        bind(classOf[Source]).to(classOf[SourceImpl]) // ②
        bind(classOf[Sink]).to(classOf[SinkImpl])     // ③
    }
}
```

① 绑定 SparkSession 实例到 SparkSession 类。

② 绑定 SourceImpl 实现类到 Source 接口。

③ 绑定 SinkImpl 实现类到 Sink 接口。

```perl6
> '②'.uniname                    # CIRCLED DIGIT TWO
> say "\c[CIRCLED DIGIT THREE]"  # ③
```

## 定义接口与实现

接口定义举例：

```scala
trait Source {
    def userDF: DataFrame
}
```

实现类举例：

```scala
class SourceImpl @Inject()(spark: SparkSession) extends Source { // 注入 SparkSession 实例
    override def userDF: DataFrame = {
        spark.table("dw.user")
    }
}
```

## 应用入口

```scala
val injector = Guice.createInjector(new ApplicationModule(spark)) // ①
injector.getInstance(classOf[Application]).run()                  // ②
```
① 创建 Injector 实例
② 运行

👇 是应用程序的骨架：

```scala
class Application @Inject() (spark: SparkSession) {
    @Inject
    var source: Source = _

    @Inject
    var sink: Sink = _

    def run(): Unit = {
        // 处理逻辑
    }
}
```

# 学习 Guice（三）：Spark 切面编程实践

## 定义注解

用于标注需要启用测量 Spark 指标的方法。

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
pubic @interface EnableMeasure {}
```

## 定义方法拦截器

```scala
class MeasureInterceptor extends MethodInterceptor {
    @Inject
    private var spark: SparkSession = _

    override def invoke(invocation: MethodInvocation): AnyRef = {
        val listener = new MeasureSparkListener
        spark.sparkContext.addSparkListener(listener)
        val ret = invocation.proceed()
        ret
    }
}
```

## 绑定

在 Module 的 configure 方法中, 将拦截器与注解进行绑定：

```scala
val measureInterceptor = new MeasureInterceptor
requestInjection(measureInterceptor)
bindInterceptor(Matchers.any, Matchers.annotatedWith(classOf[EnableMeasure]), measureInterceptor ) // 绑定注解
```

## 使用

注入依赖

```scala
val injector = Guice.createInjector(module, new ApplicationModule)  //  ① 创建注入器
injector.getInstance(classOf[Application]).run()                    //  ② 获取程序实例并运行
```

启用：

```scala
class Application {
    @EnableMeasure

    def run(): Unit = {
        // TODO
    }
}
```
