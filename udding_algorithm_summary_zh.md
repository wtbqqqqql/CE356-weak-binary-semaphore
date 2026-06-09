# Udding 算法总结

来源论文：

- Jan Tijmen Udding, **"Absence of individual starvation using weak semaphores"**, *Information Processing Letters*, 23(3), 1986, pp. 159-162
- 本地文件：[udding_algorithm.pdf](/D:/nu_courses/ce356/assignment/project/udding_algorithm.pdf)

## 1. Udding 在解决什么问题

Udding 研究的是经典的互斥问题：

- 每个进程不断循环执行 `NCS -> CS -> NCS -> ...`
- 任意时刻最多只能有一个进程进入临界区 `CS`
- 唯一可用的同步原语是 **weak semaphore**

目标性质有三个：

1. mutual exclusion
2. absence of deadlock
3. absence of individual starvation

难点在于：weak semaphore 本身**不保证公平**。  
因此标准写法：

```text
do true ->
    NCS;
    P(mutex);
    CS;
    V(mutex)
od
```

虽然可以保证互斥，但**不能保证没有饥饿**。

## 2. 论文里 weak semaphore 的含义

论文区分了两类 semaphore：

- **strong semaphore**：一个等待进程被别人反复插队的次数存在上界
- **weak semaphore**：不保证这种个体无饥饿

不过 Udding 仍然假设 weak semaphore 至少满足一个很弱的条件：

- 如果某个进程对信号量 `s` 执行 `V(s)`，并且此时已经有别的进程阻塞在 `P(s)` 上，那么执行 `V(s)` 的这个进程不会立刻自己再次通过下一次 `P(s)` 抢回它；应该允许某个已经在等待的进程先通过

这不是 FIFO，也不是强公平，但足够在其上构造更强的协议。

## 3. 算法的核心直觉

标准单锁互斥的问题是：

- 某个进程刚执行完 `V(mutex)`
- 它很快又回来执行 `P(mutex)`
- 在三个及以上进程的情况下，它可能反复超过其他等待者
- 于是有的进程可能永远进不了 `CS`

Udding 的想法是：

- 不让所有竞争者直接去抢最后的 `mutex`
- 而是设计一个有结构的准入流程
- 把“新来的进程”和“已经在等待链条里的进程”区分开
- 让系统按阶段推进

所以这个算法不是“简单的一把锁”，而是一个**多阶段准入协议**。

## 4. 论文是怎么一步步推导出最终算法的

这篇论文很好的地方在于，它不是直接扔出最后结果，而是一步步推导出来。

### 阶段 1：标准 mutex

最朴素的做法只有一个二元信号量 `mutex`。

问题：

- 饥饿可能出现，因为某个进程释放后可以很快重新竞争

### 阶段 2：把入口控制拆开

Udding 额外引入一个信号量 `enter`，和 `mutex` 一起构成 **split binary semaphore**：

```text
0 <= mutex + enter <= 1
```

直觉是：

- `enter` 控制新进程能不能继续往里走
- `mutex` 控制已经进入当前批次的进程如何继续流向临界区

同时引入：

- `nm`：等待在 `P(mutex)` 处的进程数

目标：

- 一旦一批进程已经聚集到 `mutex` 前，就暂时阻止新的进程继续干扰，先把这一批“冲刷”过去

### 阶段 3：统计更外层的等待者

但上一步只是把饥饿问题从 `mutex` 挪到了 `enter`。

因此 Udding 又引入：

- `ne`：等待在 `P(enter)` 处的进程数

这样系统就能判断：

- 什么时候应该继续给外层等待者机会
- 什么时候应该继续清空已经靠近临界区的那一批

到了这一步，算法已经出现了下面这种结构：

- 外层等待区
- 内层等待区
- 根据等待人数决定下一步该开哪一道门

### 阶段 4：保护第二次 `P(enter)`

最后剩下的关键问题是：

- 阻塞在**第一次** `P(enter)` 的进程，应该比阻塞在**第二次** `P(enter)` 的进程有更高优先级

Udding 观察到：

- 如果第二次 `P(enter)` 那里也同时挤着多个进程，就可能破坏这个优先级安排

所以他再加入一个二元信号量：

- `queue`

作用是：

- 在第二次 `P(enter)` 之前先做一次排队
- 保证在那个位置不会发生失控竞争

这就是最终算法成立的关键一步。

## 5. 论文中的最终算法

Udding 最终给出的程序是：

```text
P(enter); ne := ne + 1; V(enter);
P(queue); P(enter); nm := nm + 1;
ne := ne - 1;
V(queue);
P(mutex);
if ne > 0 -> V(enter)
[] ne = 0 -> V(mutex)
fi;
nm := nm - 1;
CS;
if nm > 0 -> V(mutex)
[] nm = 0 -> V(enter)
fi
```

初始值：

- `queue = 1`
- `enter = 1`
- `mutex = 0`

共享变量：

- `ne`：阻塞在 `queue` 或第二次 `P(enter)` 前后的进程数
- `nm`：等待在 `P(mutex)` 的进程数

## 6. 怎么读这个最终算法

最好的方式是把它拆成几个阶段来看。

### 阶段 A：登记自己要进入

```text
P(enter); ne := ne + 1; V(enter);
```

含义：

- 一个进程先安全地把自己登记为“正在尝试进入”
- `ne` 记录外层竞争者数量

### 阶段 B：串行化地穿过第二道门

```text
P(queue); P(enter); nm := nm + 1;
ne := ne - 1;
V(queue);
```

含义：

- `queue` 保证不会有多个进程同时在第二次 `P(enter)` 那里乱抢
- 一次只允许一个进程完成这段推进
- 一旦通过，它就进入靠近 `mutex` 的内层等待组

### 阶段 C：等待进入当前这一批的关键区通道

```text
P(mutex);
```

含义：

- 这个进程现在已经在内层等待组中
- 它等待被准许真正进入临界区

### 阶段 D：通过 `mutex` 后如何交接

```text
if ne > 0 -> V(enter)
[] ne = 0 -> V(mutex)
fi;
```

含义：

- 如果外层还有竞争者（`ne > 0`），就先给外层一点推进机会
- 如果外层已经没人了，就继续清空当前内层组，让下一位通过 `mutex`

这是整个协议非常关键的平衡规则。

### 阶段 E：离开临界区

```text
nm := nm - 1;
CS;
if nm > 0 -> V(mutex)
[] nm = 0 -> V(enter)
fi
```

含义：

- 完成临界区后，如果 `mutex` 前面还有人在等，就继续放行内层组
- 如果内层已经清空，就重新打开 `enter`，让下一批外层竞争者进来

这就形成了“分批推进”的行为。

## 7. 为什么这个算法能够避免 starvation

核心原因是：

- 新到达的进程不能无限制地和已经深入协议内部的进程竞争
- `queue` 防止第二次 `P(enter)` 附近发生破坏优先级的混乱
- `enter` 和 `mutex` 配合控制系统此时是在：
  - 让外层竞争者继续推进
  - 还是清空已经进入内层的那一批

因此，一个等待中的进程不会被后来者无限次插队。

论文最终结论是：  
这个协议只使用 weak semaphores，也能实现：

- mutual exclusion
- no deadlock
- absence of individual starvation

## 8. 为什么它适合做课程 project

这个算法非常适合 CE356 project，因为：

1. 它是一个**具体命名的协议**，不是玩具例子
2. 它和题目高度一致：weak semaphores + `n`-process mutual exclusion
3. 它同时包含：
   - safety：mutual exclusion
   - liveness：starvation freedom
4. 它结构清楚，适合翻译成 TLA+ 模型

## 9. 如果要在 TLA+ 里建模，主要对象是什么

一个合理的 TLA+ 模型可以包括：

- `Proc`：进程集合
- `pc[i]`：第 `i` 个进程当前控制位置
- 三个二元信号量：
  - `enter`
  - `queue`
  - `mutex`
- 两个计数器：
  - `ne`
  - `nm`

控制状态可以设计成：

- `idle`
- `at_enter_1`
- `at_queue`
- `at_enter_2`
- `at_mutex`
- `cs`
- `exit`

核心 safety 性质：

- 任意时刻最多一个进程处于 `cs`

核心 liveness 问题：

- 在选定 fairness 假设下，怎样表达和检查“没有个体饥饿”

## 10. 一句话总结

Udding 算法是一个分阶段的互斥准入协议，它通过 `enter`、`queue`、`mutex` 以及计数器 `ne`、`nm` 来组织竞争者的推进顺序，从而在 weak semaphore 的前提下仍然避免 individual starvation。
