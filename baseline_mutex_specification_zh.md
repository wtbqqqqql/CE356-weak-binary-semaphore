# Baseline Mutex 的 Specification 分析

## 1. 目的

在本项目中，我们将传统的单 `mutex` 方案作为 baseline。这样做的目的不是把它当作最终答案，而是将其作为一个最自然、最直观的参考对象，用来回答以下问题：

- 在 weak binary semaphore 的条件下，最简单的互斥协议能够保证什么；
- 为什么这种协议虽然满足 mutual exclusion，却仍然可能导致 starvation；
- 为什么需要更复杂的协议，例如 Udding Algorithm。

因此，本节的重点不是提出一个新算法，而是先对最朴素的 `mutex` 方案进行 specification 和分析，为后续的改进协议建立对照基础。

## 2. baseline 协议描述

我们考虑 `n` 个并发进程，每个进程都不断重复如下循环：

```text
NCS;
P(mutex);
CS;
V(mutex);
```

其中：

- `NCS` 表示 non-critical section，即不访问共享资源的普通执行阶段；
- `CS` 表示 critical section，即访问共享资源、必须互斥执行的关键代码段；
- `mutex` 是一个 weak binary semaphore；
- `P(mutex)` 表示请求获取 semaphore；
- `V(mutex)` 表示释放 semaphore。

直观上，这个协议的含义非常简单：

- 如果某个进程成功执行 `P(mutex)`，它就可以进入 critical section；
- 当该进程完成 critical section 后，它执行 `V(mutex)`，允许其他等待者继续竞争；
- 由于 `mutex` 是 binary semaphore，因此任意时刻至多只有一个进程能够持有它。

## 3. 系统抽象

为了对 baseline 做形式化 specification，我们需要先把问题抽象成状态机模型。

### 3.1 进程集合

设系统中有一个参数化的进程集合：

```text
Proc = {1, 2, ..., n}
```

其中 `n` 是系统参数，也是题目要求中的关键部分。这意味着我们关注的是一个适用于一般 `n` 个进程的互斥协议，而不是只针对两个进程的特例。

### 3.2 每个进程的局部状态

每个进程可以处于如下几个控制阶段之一：

- `ncs`：位于 non-critical section；
- `trying`：正在尝试进入 critical section；
- `cs`：已经进入 critical section；
- `exit`：准备释放 semaphore 并离开 critical section。

在 TLA+ 模型中，这通常可以用一个映射 `pc[i]` 来表示，即 `pc[i]` 表示第 `i` 个进程当前所处的控制状态。

### 3.3 semaphore 状态

由于 `mutex` 是 binary semaphore，因此它的状态可以抽象成：

- `1`：semaphore 可用；
- `0`：semaphore 已被占用。

因此，在最简单的形式下，我们可以用一个变量 `mutex` 表示信号量状态，其中：

```text
mutex ∈ {0, 1}
```

初始状态通常设为：

```text
mutex = 1
```

表示一开始 critical section 没有被任何进程占用。

## 4. baseline 的操作语义

为了写 specification，需要明确 baseline 中每个动作的含义。

### 4.1 从 NCS 发起竞争

当某个进程完成自己的普通工作后，它会从 `ncs` 进入 `trying` 状态，表示它开始竞争进入 critical section。

这个动作本身不改变 `mutex` 的值，只改变该进程自己的局部状态。

### 4.2 执行 `P(mutex)`

若某个进程当前位于 `trying`，并且 `mutex = 1`，则它可以成功执行 `P(mutex)`：

- `mutex` 从 `1` 变成 `0`
- 该进程从 `trying` 进入 `cs`

这个动作体现了“获取锁并进入 critical section”的过程。

若 `mutex = 0`，则该进程无法完成该动作，只能继续等待。

### 4.3 执行 critical section

进程一旦处于 `cs`，说明它已经获得进入权限，可以执行共享资源操作。  
在 specification 中，`CS` 内部的具体操作通常可以被抽象掉，因为我们主要关心的是“谁能进入”，而不是 critical section 内部的业务逻辑。

### 4.4 执行 `V(mutex)`

当某个进程准备离开 critical section 时，它执行 `V(mutex)`：

- `mutex` 从 `0` 变回 `1`
- 该进程从 `cs` 转到 `ncs`，或者先经过 `exit` 再回到 `ncs`

这个动作表示释放共享资源控制权，允许其他等待进程继续竞争。

## 5. 这个 baseline 能够保证什么

### 5.1 Mutual Exclusion

这是 baseline 最直接、也是最容易理解的性质。

因为：

- 任意时刻 `mutex` 只有一个值；
- 一旦某个进程成功执行 `P(mutex)`，`mutex` 就会变成 `0`；
- 在它执行 `V(mutex)` 之前，其他进程都无法再次通过 `P(mutex)`。

因此，任意时刻最多只有一个进程能够位于 critical section。

形式化地说，我们希望满足：

```text
任意时刻，处于 cs 的进程数 <= 1
```

这就是该协议的核心 safety 性质。

### 5.2 协议结构简单

baseline 的另一个优点是结构极其简单：

- 只需要一个 binary semaphore；
- 没有辅助计数器；
- 没有分阶段准入；
- 没有复杂的等待组织结构。

这意味着它非常适合作为建模起点，也非常适合作为后续与 Udding 协议的对照对象。

## 6. 这个 baseline 不能保证什么

### 6.1 不能保证 fair access

虽然 baseline 可以保证 mutual exclusion，但它并不能保证等待者公平地进入 critical section。

在 weak semaphore 的条件下，系统只提供一个很弱的调度承诺，而不提供 FIFO 排队保证。于是可能发生如下情况：

- 进程 `P1` 刚刚执行完 `V(mutex)`；
- `P1` 很快又回到 `P(mutex)`；
- 另一进程 `P2` 虽然已经等待了较长时间，但每次竞争时都失败；
- 这一过程可以无限重复。

于是，`P2` 可能长期甚至永远无法进入 critical section。

### 6.2 可能出现 individual starvation

这正是题目中强调的关键问题：  
使用单个 weak binary semaphore 虽然足以保护临界区，但并不能阻止某个进程被后来者不断插队。

因此，baseline 的主要局限在于：

- 它保证了 safety；
- 但它不自动保证 progress，尤其是不保证 absence of individual starvation。

## 7. 为什么它适合作为 baseline

尽管该方案存在明显局限，它仍然是一个很合适的 baseline，原因有三点：

1. 它是最自然的互斥方案，具有清晰的解释性；
2. 它在 safety 层面是正确的，因此可以作为形式化建模的起点；
3. 它清楚地暴露了 weak semaphore 的核心难点，从而为引入 Udding 提供充分动机。

换句话说，baseline 的作用不是“证明它足够好”，而是“证明它为什么不够好”。

## 8. 后续如何与 Udding 对比

在后续分析中，这个 baseline 将主要从以下三个方面与 Udding 进行对比：

### 8.1 Mutual Exclusion

- baseline 是否满足 mutual exclusion；
- Udding 是否满足 mutual exclusion。

预期是二者都满足。

### 8.2 Starvation Risk

- baseline 为什么可能 starvation；
- Udding 为什么能够避免个体饥饿。

这将是最关键的对比点。

### 8.3 TLA+ State Complexity

- baseline 的模型状态更少；
- Udding 的模型结构更复杂，状态空间也更大。

这说明更强的行为保证往往伴随着更高的形式化建模成本。

## 9. 一句话总结

baseline 单 `mutex` 方案是一个简单、直观且满足 mutual exclusion 的弱信号量互斥协议；但它无法保证等待者的公平进入，因此非常适合作为 Udding 协议的对照基础。
