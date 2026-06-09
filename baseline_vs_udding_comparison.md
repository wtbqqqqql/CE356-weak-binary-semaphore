# Baseline Mutex 与 Udding Algorithm 对比说明

## 1. 项目背景

这个 project 的核心不是“实现一个能互斥的锁”这么简单，而是：

- 实现 `n` 进程互斥
- 只使用 **weak binary semaphore**
- 用 **TLA+ / TLC** 说明模型正确性

因此，一个合理的项目结构是：

1. 先给出最自然的 baseline
2. 说明 baseline 为什么虽然满足 mutual exclusion，但在 weak semaphore 下仍然不够
3. 再引入 Udding algorithm，解释它如何改善 progress / starvation 问题
4. 用 TLA+ 把两者形式化并进行对照

## 2. Baseline 的原理

### 2.1 算法思想

Baseline 就是最经典的单信号量互斥：

```text
do true ->
    NCS;
    P(mutex);
    CS;
    V(mutex)
od
```

它只有一个二元信号量 `mutex`：

- `mutex = 1` 表示临界区可进入
- `mutex = 0` 表示已经被某个进程持有

在 TLA+ 模型里，这个过程被拆成几个离散步骤：

- `ncs -> trying`
- 如果 `mutex = 1`，则进入 `cs`
- `cs -> exit`
- `exit -> ncs` 时释放 `mutex`

对应文件：

- [BaselineMutex.tla](/d:/nu_courses/ce356/assignment/project/BaselineMutex.tla:1)

### 2.2 它为什么能保证 mutual exclusion

原因很直接：

- 只有当 `mutex = 1` 时，进程才能从 `trying` 进入 `cs`
- 一旦某个进程进入 `cs`，`mutex` 就被置为 `0`
- 其他进程在 `mutex` 重新变回 `1` 之前都进不了 `cs`

所以 TLC 很容易验证：

- 任意时刻 `cs` 中最多一个进程

### 2.3 它为什么不够

Baseline 的问题不在 safety，而在 progress。

如果底层 semaphore 只是 **weak**：

- 它不承诺 FIFO
- 也不承诺等待者一定按某种公平顺序被服务

于是可能发生：

- 某个刚刚离开 `CS` 的进程又很快回来争抢 `mutex`
- 它反复比其他等待者更快
- 某些等待进程一直进不了 `CS`

也就是说：

- baseline 很适合做 safety baseline
- 但它不能体现 “weak semaphore 下如何避免个体饥饿”

## 3. Udding Algorithm 的原理

### 3.1 它解决的核心问题

Udding 的目标不是单纯保持互斥，而是：

- 在只拥有 weak semaphores 的前提下
- 依然避免 individual starvation

它的关键思路是：

- 不让所有进程直接去抢最终的 `mutex`
- 而是把进入过程拆成多个阶段
- 让“新到达的进程”和“已经进入当前批次的进程”分开推进

### 3.2 共享变量和含义

在当前 TLA+ 模型中，Udding 使用了：

- `enter`：控制新进程是否还能继续向内推进
- `queue`：保护第二次 `P(enter)`，避免那里发生无序竞争
- `mutex`：内层批次进入临界区的最终通道
- `ne`：外层等待人数
- `nm`：内层等待 `mutex` 的人数

对应文件：

- [UddingMutex.tla](/d:/nu_courses/ce356/assignment/project/UddingMutex.tla:1)

### 3.3 算法流程

当前模型对应的论文级流程可以概括为：

```text
P(enter); ne := ne + 1; V(enter);
P(queue); P(enter); nm := nm + 1; ne := ne - 1;
if ne > 0 then V(enter) else V(mutex);
V(queue);
P(mutex); nm := nm - 1;
CS;
if nm > 0 then V(mutex) else V(enter)
```

它的直觉是：

1. 进程先在外层登记自己要进入
2. `queue` 保证一次只有一个进程去参与第二次 `P(enter)`
3. 一旦进入内层等待组，系统根据 `ne` 判断：
   - 还要不要继续放外层进程进来
   - 还是优先清空已经靠近临界区的内层批次
4. 离开 `CS` 时，如果内层还有等待者，就继续 `V(mutex)`；否则重新打开 `enter`

于是协议形成了一个“分批推进”的效果：

- 外层人群先被组织好
- 内层人群再被逐个排入 `CS`
- 新来者不会无限制插队打断已在队列深处的进程

## 4. Baseline 与 Udding 的核心区别

### 4.1 结构复杂度

Baseline 只需要：

- `mutex`

Udding 需要：

- `enter`
- `queue`
- `mutex`
- `ne`
- `nm`

所以 Udding 的代价很明显：

- 状态更多
- 控制流更长
- 模型更复杂

### 4.2 关注点不同

Baseline 的重点是：

- “怎么保证一次只有一个进程在 CS”

Udding 的重点是：

- “在 weak semaphore 不提供强公平性的情况下，怎么让等待者仍然逐步向前”

换句话说：

- baseline 主要回答 safety
- Udding 进一步尝试回答 starvation / progress

### 4.3 为什么要加 `queue`

这是 Udding 里很关键的一点。

如果没有 `queue`：

- 多个进程可能同时在第二次 `P(enter)` 附近竞争
- 这样会破坏“第一次 `P(enter)` 的等待者优先于第二次 `P(enter)` 的等待者”这件事

所以 `queue` 的作用不是再做一层普通锁，而是：

- 把第二次 `P(enter)` 前的竞争串行化
- 保证 Udding 论文里需要的优先级结构成立

## 5. 当前 TLA+ 模型如何对应算法

### 5.1 Baseline

`BaselineMutex.tla` 中的主要控制状态：

- `ncs`
- `trying`
- `cs`
- `exit`

这是一个非常直接的状态机翻译。

### 5.2 Udding

`UddingMutex.tla` 中把论文伪代码拆成了更细的 PC 状态：

- `e1`, `ne_inc`, `e1_rel`
- `q_wait`, `e2_wait`
- `nm_inc`, `ne_dec`, `handoff`
- `q_rel`, `mu_wait`, `nm_dec`
- `cs`

这种拆法的好处是：

- 每一步只做一个原子更新
- 更适合 TLC 离散状态探索
- 更容易给每一段共享变量变化单独建模

## 6. 本次 TLC 运行结果

本次已经实际运行并通过了下面这些检查：

### 6.1 Baseline

- 使用 Toolbox 包装模型 `BaselineMutex.toolbox/Model_1/MC.tla`
- 检查通过：
  - `TypeOK`
  - `MutualExclusion`

结果摘要：

- `21` states generated
- `12` distinct states
- depth `5`
- no error found

### 6.2 Udding

- 使用 Toolbox 包装模型 `UddingMutex.toolbox/Model_1/MC.tla`
- 检查通过：
  - `TypeOK`
  - `MutualExclusion`
  - `SplitBinary`

结果摘要：

- `131` states generated
- `88` distinct states
- depth `23`
- no error found

### 6.3 Udding 三进程直接运行

另外还直接对根目录 spec 做了三进程配置检查：

- 配置文件：[UddingMutex_3P.cfg](/d:/nu_courses/ce356/assignment/project/UddingMutex_3P.cfg:1)

结果摘要：

- `973` states generated
- `520` distinct states
- depth `33`
- no error found

这说明当前的 Udding TLA 模型至少在：

- 两进程 Toolbox 模型
- 三进程直接 TLC 配置

这两种入口下都能正常运行并保持互斥与 split-binary 约束。

## 7. 如何运行

如果你已经有 Java / TLC 环境，可以直接运行根目录 spec。

### 7.1 跑 Baseline

```powershell
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -cleanup -config BaselineMutex_3P.cfg BaselineMutex.tla
```

### 7.2 跑 Udding

```powershell
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -cleanup -config UddingMutex_3P.cfg UddingMutex.tla
```

如果你想沿用 Toolbox 风格入口，也可以运行：

- [BaselineMutex.toolbox/Model_1/MC.tla](/d:/nu_courses/ce356/assignment/project/BaselineMutex.toolbox/Model_1/MC.tla:1)
- [UddingMutex.toolbox/Model_1/MC.tla](/d:/nu_courses/ce356/assignment/project/UddingMutex.toolbox/Model_1/MC.tla:1)

## 8. 小结

这个 project 最自然的叙述方式就是：

- baseline 说明最朴素的 weak-semaphore mutex 虽然能互斥，但 progress 保证不足
- Udding 说明为了避免 starvation，需要更复杂的 staged admission structure
- TLA+ 模型则把这两者的结构差异清楚地落成状态机

所以最后报告可以把重点放在这一句上：

> 我们不是单纯“实现一个 mutex”，而是在 weak binary semaphore 的约束下，比较一个朴素 mutual exclusion protocol 与一个更强的 anti-starvation protocol。
