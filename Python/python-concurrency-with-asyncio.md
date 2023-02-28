# asyncio basics

Think of a coroutine like a regular Python function but with the superpower that it
can pause its execution when it encounters an operation that could take a while to
complete. When that long-running operation is complete, we can “wake up” our
paused coroutine and finish executing any other code in that coroutine.

While a paused coroutine is waiting for the operation it paused for to finish, we can run other
code. This running of other code while waiting is what gives our application concurrency.
We can also run several time-consuming operations concurrently, which can
give our applications big performance improvements.

The async keyword will let us define a coroutine; the await keyword
will let us pause our coroutine when we have a long-running operation.

使用 async 关键字创建 coroutine。

```python
async def my_coroutine() -> None:
    print('Hello World')
```

Comparing coroutines to normal functions:

```python
async def coroutine_add_one(number: int) -> int:
    return number + 1

def add_one(number: int) -> int:
    return number + 1

function_result = add_one(1)
coroutine_result = coroutine_add_one(1)

print(f'Function result is {function_result} and the type is {type(function_result)}')
print(f'Coroutine result is {coroutine_result} and the type is {type(coroutine_result)}')
```

输出:

```
Function result is 2 and the type is <class 'int'>
Coroutine result is <coroutine object coroutine_add_one at 0x7f0281877b40> and the type is <class 'coroutine'>
```

coroutines aren’t executed when we call them
directly. Instead, we create a coroutine object that can be run later. To run a coroutine,
we need to explicitly run it on an event loop. 

So how can we create an event loop and run our coroutine?

In versions of Python older than 3.7, we had to create an event loop if one did not
already exist. However, the asyncio library has added several functions that abstract
the event loop management. There is a convenience function, asyncio.run, we can
use to run our coroutine.

```python
import asyncio

async def coroutine_add_one(number: int) -> int:
    return number + 1

result = asyncio.run(coroutine_add_one(1))
print(result)    
```

`asyncio.run` is doing a few important things in this scenario. First, it creates a
brand-new event. Once it successfully does so, it takes whichever coroutine we pass
into it and runs it until it completes, returning the result.

`asyncio.run` will also do
some cleanup of anything that might be left running after the main coroutine finishes.
Once everything has finished, it shuts down and closes the event loop.

`asyncio.run` is intended to be
the main entry point into the asyncio application we have created. It only executes
one coroutine, and that coroutine should launch all other aspects of our application.

The coroutine that `asyncio.run` executes will create and run other
coroutines that will allow us to utilize the concurrent nature of asyncio.

The real benefit of asyncio is being able to pause execution
to let the event loop run other tasks during a long-running operation.

To pause execution, we use the `await` keyword.

Using `await` to wait for the result of coroutine:

```python
import asyncio

async def add_one(number: int) -> int:
    return number + 1


async def main() -> None:
    one_plus_one = await add_one(1) # Pause, and wait for the result of add_one(1).
    two_plus_one = await add_one(2) # Pause, and wait for the result of add_one(2).

    print(one_plus_one)
    print(two_plus_one)
```

When we hit an await expression, we pause our parent coroutine and run the coroutine in the
await expression. Once it is finished, we resume the parent coroutine and assign the return value.

2.2 Introducing long-running coroutines with asyncio.sleep

`asyncio.sleep` is itself a coroutine, so we must use it with the `await` keyword.

A first application with `sleep`:

```python
import asyncio

async def hello_god_message() -> str:
    await asyncio.sleep(1) # Pause hello_god_message for 1 second.
    return 'Hello God!'

async def main() -> None:
    message = await hello_god_message() # Pause main until hello_god_message finishes.
    print(message)

asyncio.run(main())        
```

A reusable `delay` function

```python
import asyncio

async def delay(delay_seconds: int) -> int:
    print(f'sleeping for {delay_seconds} second(s)')
    await asyncio.sleep(delay_seconds)
    print(f'finished sleeping for {delay_seconds}' second(s))
    return delay_seconds
```

2.3 Running concurrently with tasks

To run coroutines concurrently, we’ll need to introduce tasks.

Tasks are wrappers around a coroutine that schedule a coroutine to run on the event loop as soon as possible.

This scheduling and execution happen in a non-blocking
fashion, meaning that, once we create a task, we can execute other code instantly
while the task is running.

The basics of creating tasks

Creating a task is achieved by using the `asyncio.create_task` function.

When we call this function, we give it a coroutine to run, and it returns a task object instantly. Once
we have a task object, we can put it in an await expression that will extract the return
value once it is complete.

Creating a task:

```python
import asyncio
from util import delay

async def main():
    sleep_for_three = asyncio.create_task(delay(3))
    print(type(sleep_for_three))
    result = await sleep_for_three
    print(result)

asyncio.run(main())
```

输出:

```
<class '_asyncio.Task'>
sleeping for 3 second(s)
finished sleeping for 3 second(s)
3
```

Running multiple tasks concurrently

Given that tasks are created instantly and are scheduled to run as soon as possible, this
allows us to run many long-running tasks concurrently. We can do this by sequentially
starting multiple tasks with our long-running coroutine.

```python
import asyncio
from util import delay

async def main():
    sleep_for_three = asyncio.create_task(delay(3))
    sleep_again = asyncio.create_task(delay(3))
    sleep_once_more = asyncio.create_task(delay(3))

    await sleep_for_three
    await sleep_again
    await sleep_once_more

asyncio.run(main())
```

While our code is waiting,
we can execute other code. As an example, let’s say we wanted to print out a status
message every second while we were running some long tasks

```python
import asyncio
from util import delay

async def hello_every_second():
    for i in range(2):
        await asyncio.sleep(1)
        print("I'm running other code while I'm waiting!")

async def main():
    first_delay = asyncio.create_task(delay(3))
    second_delay = asyncio.create_task(delay(3))

    await hello_every_second()
    await first_delay
    await second_delay

asyncio.run(main())     
```

输出:

```
sleeping for 3 second(s)
sleeping for 3 second(s)
I'm running other code while I'm waiting!
I'm running other code while I'm waiting!
finished sleeping for 3 second(s)
finished sleeping for 3 second(s)
```

One potential issue with tasks is that they can take an indefinite amount of time to
complete. We could find ourselves wanting to stop a task if it takes too long to finish.
Tasks support this use case by allowing cancellation.

Canceling tasks and setting timeouts

Canceling tasks

Each task object has a method named `cancel`, which we can call whenever we'd like to stop a task. Canceling a task will cause that task to raise a `CancelledError` when we `await` it, which we can then handle as needed.

To illustrate this, let’s say we launch a long-running task that we don’t want to run
for longer than 5 seconds. If the task is not completed within 5 seconds, we’d like to
stop that task, reporting back to the user that it took too long and we’re stopping it.
We also want a status update printed every second, to provide up-to-date information
to our user, so they aren’t left without information for several seconds.

Canceling a task

```python
import asyncio
from asyncio import CancelledError
from util import delay

async def main():
    long_task = asyncio.create_task(delay(10))
    seconds_elapsed = 0

    while not long_task.done():
        print('Task not finished, checking again in a second.')
        await asyncio.sleep(1)
        seconds_elapsed = seconds_elapsed + 1
        if seconds_elapsed == 5:
            long_task.cancel()

    try:
        await long_task
    except CancelledError:
        print('Our task was cancelled')

asyncio.run(main())
```

输出:

```
Task not finished, checking again in a second.
sleeping for 10 second(s)
Task not finished, checking again in a second.
Task not finished, checking again in a second.
Task not finished, checking again in a second.
Task not finished, checking again in a second.
Task not finished, checking again in a second.
Our task was cancelled
```

Calling cancel won’t magically stop the task in its tracks; it will only stop the task if you’re
currently at an await point or its next await point.

Setting a timeout and canceling with wait_for

`asyncio.wait_for` takes in a coroutine or task object, and a timeout specified in seconds.

```python
import asyncio
from util import delay

async def main():
    delay_task = asyncio.create_task(delay(2))
    try:
        result = await asyncio.wait_for(delay_task, timeout=1)
        print(result)
    except asyncio.exceptions.TimeoutError:
        print('Got a timeout')
        print(f'Was the task cancelled? {delay_task.cancelled()}')

asyncio.run(main())
```

输出:

```
sleeping for 2 second(s)
Got a timeout
Was the task cancelled? True
```

Sometimes, we may want to inform a user that something is
taking longer than expected after a certain amount of time but not cancel the task
when the timeout is exceeded.

To do this we can wrap our task with the asyncio.shield function. This function
will prevent cancellation of the coroutine we pass in, giving it a “shield,” which cancellation
requests then ignore

Shielding a task from cancellation

```python
import asyncio
from util import delay

async def main():
    task = asyncio.create_task(delay(10))

    try:
        result = await asyncio.wait_for(asyncio.shield(task), 5)
        print(result)
    except asyncio.exceptions.TimeoutError:
        print("Task took longer than five seconds, it will finish soon!")
        result = await task
        print(result)

asyncio.run(main())
```

2.5 Tasks, coroutines, futures and awaitables

A future is a Python object that contains a single value that you expect to get at some
point in the future but may not yet have.

Usually, when you create a future, it does
not have any value it wraps around because it doesn’t yet exist. In this state, it is considered
incomplete, unresolved, or simply not done. Then, once you get a result, you
can set the value of the future. This will complete the future; at that time, we can
consider it finished and extract the result from the future

```python
from asyncio import Future

my_future = Future()

print(f'Is my_future done? {my_future.done()}')
my_future.set_result(42)

print(f'Is my_future done? {my_future.done()}')
print(f'What is the result of my_future? {my_future.result()}')
```

Futures can also be used in await expressions. If we await a future, we’re saying
“pause until the future has a value set that I can work with, and once I have a value,
wake up and let me process it.”

Awaiting a future

```python
from asyncio import Future
import asyncio

async def set_future_value(future) -> None:
    await asyncio.sleep(1) # Wait 1 second before setting the value of the future
    future.set_result(42)

def make_request() -> Future:
    future = Future()
    asyncio.create_task(set_future_value(future)) # Create a task to asynchronously set the value of the future.
    return future

async def main():
    future = make_request()
    print(f'Is the future done? {future.done()}')
    value = await future
    print(f'Is the future done? {future.done()}')
    print(value)

asyncio.run(main())
```

输出:

```
Is the future done? False
Is the future done? True
42
```

2.5.2 The relationship between futures, tasks, and coroutines

There is a strong relationship between tasks and futures. In fact, task directly inherits
from future. A future can be thought as representing a value that we won’t have for
a while. A task can be thought as a combination of both a coroutine and a future.
When we create a task, we are creating an empty future and running the coroutine.
Then, when the coroutine has completed with either an exception or a result, we set
the result or exception of the future.

anything that implements the
__await__ method can be used in an await expression.

Coroutines inherit directly
from Awaitable, as do futures. Tasks then extend futures

```
     Awaitable
     |       |       
  Coroutine  Future 
                |
              Task  
```

Going forward, we’ll start to refer to objects that can be used in await expressions as
awaitables. You’ll frequently see the term awaitable referenced in the asyncio documentation,
as many API methods don’t care if you pass in coroutines, tasks, or futures.

2.6 Measuring coroutine execution time with decorators

```python
import asyncio
import time

async def main():
    start = time.time()
    await asyncio.sleep(1)
    end = time.time()
    print(f'Sleeping took {end - start} seconds')

asyncio.run(main())
```

A decorator for timing coroutines

```python
import functools
import time
from typing import Callable, Any

def async_timed():
    def wrapper(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapped(*args, **kwargs) -> Any:
            print(f'starting {func} with args {args} {kwargs}')
            start = time.time()
            try:
                return await func(*args, **kwargs)
            finally:
                end = time.time()   
                total = end - start
                print(f'finished {func} in {total:.4f} second(s)')
            return wrapped    
    return wrapper    
```

