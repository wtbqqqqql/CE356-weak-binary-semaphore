# Semaphore Concepts Notes

这份笔记把你现在最容易混的几个概念串起来：

- global variable
- shared variable
- critical section
- race condition
- semaphore

目标不是讲完整理论，而是帮助你先建立一个能用的直觉。

## 1. Global Variable 是什么

像这样定义在函数外面的变量：

```cpp
int shared_counter = 0;
```

这叫 `global variable`，也就是全局变量。

它的特点是：

- 不属于某一个函数
- 程序里很多地方都能访问它
- 如果多个线程都能访问它，它就很容易变成共享数据

但要注意：

- `global variable` 不一定危险
- 危险的是“多个线程同时访问并修改它”

例如：

```cpp
const int N = 10;
```

这种全局常量一般就没事，因为它不会被修改。

## 2. Shared Variable 是什么

`shared variable` 的意思是：多个线程都能访问到的变量。

它不一定非得是 global。

例如下面几种都可能是 shared variable：

- 全局变量
- 多个线程共同访问的对象成员
- 通过指针或引用传给多个线程的数据

所以更准确的说法是：

- `global` 讲的是作用域
- `shared` 讲的是线程之间是否共用

在并发里，真正需要小心的是：

`shared mutable state`

也就是：

- 共享的
- 并且还能被修改的状态

## 3. Critical Section 是什么

`critical section`，中文通常叫“临界区”。

它不是指某个变量，而是指一小段代码：

```cpp
++shared_counter;
```

或者更完整一点：

```cpp
shared_counter = shared_counter + 1;
```

为什么这段代码是临界区？

因为它访问了共享变量，而且结果会受线程交错执行影响。

所以临界区可以理解成：

- 访问共享数据的一段敏感代码
- 同一时刻通常不希望多个线程同时执行它

## 4. Race Condition 是什么

`race condition`，就是竞态条件。

意思是：

- 程序结果依赖线程执行的先后顺序
- 不同执行顺序会得到不同结果
- 某些顺序是错的

例如两个线程同时做：

```cpp
++shared_counter;
```

表面上看都是“加 1”，但底层往往不是一步完成，而是三步：

1. 读出旧值
2. 加 1
3. 写回去

假设 `shared_counter` 原来是 `100`：

- 线程 A 读到 100
- 线程 B 也读到 100
- A 算出 101 并写回
- B 也算出 101 并写回

结果本来应该加 2，最后却只加了 1。

这就是 race condition。

所以你可以记成一句话：

多个线程同时无保护地访问共享可变数据，就可能出现 race condition。

## 5. Semaphore 是什么

`semaphore`，信号量，可以先把它理解成“带计数的门禁”。

它最常见的两个操作是：

- `P()`：申请一个名额，没有名额就等
- `V()`：归还一个名额，或者通知别人现在可以继续了

它的用途主要有两类：

1. 互斥
2. 同步/通知

### 5.1 用作互斥

如果这样初始化：

```cpp
Semaphore mutex_sem(1);
```

意思是：

- 一开始只有 1 个名额
- 同一时刻只允许 1 个线程进入

所以可以这样写：

```cpp
mutex_sem.P();
++shared_counter;
mutex_sem.V();
```

这表示：

- 先进入临界区
- 修改共享变量
- 再离开临界区

这样就把并发修改变成了“排队修改”。

### 5.2 用作通知

如果这样初始化：

```cpp
Semaphore items_ready(0);
```

意思是：

- 一开始没有可用资源
- 线程调用 `P()` 时会等待
- 另一个线程调用 `V()` 后，它才能继续

这常用于：

- 生产者通知消费者
- 一个线程等另一个线程做完某件事

## 6. 它们之间的关系

你可以把这几个概念串成下面这条线：

1. 程序里有一些变量是 global variable
2. 如果多个线程都能访问它，它就成了 shared variable
3. 如果多个线程还会修改它，就容易出问题
4. 修改它的那段敏感代码，就是 critical section
5. 如果不做保护，就可能发生 race condition
6. semaphore 可以用来保护 critical section，或者做线程间同步

## 7. 你现在最该记住的版本

可以直接记这一段：

在多线程程序中，真正危险的不是“global”这件事本身，而是“多个线程共享并修改同一份数据”。这会让访问该数据的代码变成临界区。如果临界区没有同步保护，就可能出现 race condition。semaphore 的作用，就是让线程排队进入临界区，或者在线程之间传递“现在可以继续了”的信号。

## 8. 对应到你现在的例子

[00_no_lock_race.cpp](/D:/nu_courses/ce356/assignment/project/semaphore_examples/00_no_lock_race.cpp)

- `shared_counter` 是 global variable
- 它也是 shared variable
- `++shared_counter` 是 critical section
- 没有保护，所以会出现 race condition

[01_binary_semaphore_mutex.cpp](/D:/nu_courses/ce356/assignment/project/semaphore_examples/01_binary_semaphore_mutex.cpp)

- `shared_counter` 还是那个共享变量
- 但这次外面包了 `P()` 和 `V()`
- 所以同一时刻只有一个线程能修改它
- race condition 被避免了

## 9. 一句最短总结

不是所有 global variable 都有问题。

真正的问题是：

多个线程无保护地同时修改 shared variable。

而 semaphore 是解决这个问题的一种经典办法。
