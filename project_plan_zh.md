# CE356 Project 思路梳理

## 1. 项目总思路

我们打算采用一个非常稳妥、也很适合课程要求的方案：

- `baseline`：传统的单 `mutex` 方案，即用一个 weak binary semaphore 保护 critical section
- `target`：Udding 协议，即在 weak semaphore 条件下避免个体饥饿的互斥协议

项目的核心不再是“我们直接使用了 Udding”，而是：

> 我们研究为什么朴素的 weak-semaphore mutex 不够，以及 Udding 协议到底解决了什么问题、付出了什么代价。

也就是说，项目的主线是：

1. 先建模一个最自然、最直观的 baseline
2. 说明这个 baseline 的优点和局限
3. 再引入 Udding 作为改进协议
4. 对二者做形式化比较

这个结构的好处是：

- 符合老师题目要求
- 不显得只是“照搬 Udding”
- 自然形成一篇完整的 specification and verification project

## 2. 为什么这样做是合理的

老师给出的题目核心是：

- weak binary semaphore 可能导致 starvation
- 但仍然要实现 `n`-process mutual exclusion
- 用 TLA+ 证明方案正确

如果我们一开始就直接写 Udding，会有两个问题：

1. 缺少问题对比，老师看不出为什么 Udding 有必要
2. 容易显得像“直接采用了现成算法”

引入 baseline 之后，项目会变成：

- baseline 展示“最自然的做法为什么不够”
- Udding 展示“更复杂协议为什么值得”

这样就很自然地形成了研究味道。

## 3. baseline 是什么

baseline 是传统的单 `mutex` 方案：

```text
do true ->
    NCS;
    P(mutex);
    CS;
    V(mutex)
od
```

这里：

- `mutex` 是一个 weak binary semaphore
- `NCS` 是 non-critical section
- `CS` 是 critical section

这个 baseline 的特点是：

- 非常直观
- 很容易保证 `mutual exclusion`
- 但是在 weak semaphore 下可能出现 `starvation`

也就是说：

- 作为 safety baseline，它很好
- 作为完整答案，它不够

## 4. 为什么 baseline 不够

baseline 的根本问题是：

- 一个进程刚执行完 `V(mutex)`，可能很快又回来竞争 `P(mutex)`
- weak semaphore 不保证公平顺序
- 因此某些等待者可能被反复插队

所以 baseline 虽然可能满足：

- mutual exclusion

但未必满足：

- absence of individual starvation

而老师在题目描述里专门强调了这种风险，这说明：

- 仅仅验证一个单 `mutex` 的互斥，并不能构成完整 project

## 5. 为什么引入 Udding

Udding 协议的作用是：

- 在 weak semaphores 的条件下
- 通过一个更复杂的准入结构
- 避免等待进程被后来者无限次插队

它的核心价值不只是“还能互斥”，而是：

- 它专门处理了 weak semaphore 带来的 starvation 风险

从项目角度看，Udding 是一个很好的 `target algorithm`，因为它：

1. 是一个具体命名的协议
2. 与老师题目高度匹配
3. 可以自然地和 baseline 做对比
4. 非常适合做 TLA+ 建模与分析

## 6. 项目主线怎么讲

整个项目可以围绕下面这句话来展开：

> 我们研究在 weak binary semaphore 的前提下，为什么最朴素的互斥方案不足，以及 Udding 协议如何提供更强的 progress guarantee。

这句话非常重要，因为它把项目从“复现一个算法”变成了“比较并分析两类方案”。

## 7. 我们要比较什么

当前计划的比较维度有四个：

### 7.1 mutual exclusion

这是最基本的 safety 性质。

我们会比较：

- baseline 是否满足 mutual exclusion
- Udding 是否满足 mutual exclusion

预期结果：

- 二者都应满足 mutual exclusion

### 7.2 starvation risk

这是最关键的比较维度。

我们会分析：

- baseline 在 weak semaphore 下为什么可能 starvation
- Udding 如何避免 individual starvation

这里会是整个项目最有价值的部分，因为它正好对应老师题目里强调的难点。

### 7.3 protocol complexity

我们会比较：

- baseline 的结构非常简单，只需要一个 `mutex`
- Udding 需要：
  - `enter`
  - `queue`
  - `mutex`
  - `ne`
  - `nm`

这说明：

- Udding 的代价是更高的协议复杂度
- 但它换来了更强的 progress 性质

### 7.4 TLA+ state complexity

这是一个非常适合 project 的分析点。

我们可以比较：

- baseline 模型状态少、容易验证
- Udding 模型状态更多、动作更多、状态空间更大

这体现出：

- 更强的行为保证通常意味着更复杂的形式化模型

## 8. 项目最终要回答的问题

如果按这个路线做，项目最终回答的就不是：

- “Udding 算法怎么写”

而是：

- 为什么 naive weak-semaphore mutex 不够
- Udding 到底解决了什么问题
- 它用什么机制解决
- 代价是什么
- 在 TLA+ 中如何体现这种差异

这样项目就会比“单纯实现一个经典算法”更完整。

## 9. 文档和实现建议结构

后续文档和报告可以按下面这个结构组织。

### 9.1 Introduction

- 介绍 weak binary semaphore
- 解释为什么 starvation 是题目的关键难点
- 说明项目将比较 baseline 和 Udding

### 9.2 Baseline Protocol

- 给出单 `mutex` 协议
- 解释它为什么能保证互斥
- 解释它为什么不能很好解决 starvation

### 9.3 Udding Protocol

- 介绍 Udding 的背景和目标
- 解释 `enter / queue / mutex / ne / nm` 的作用
- 给出算法流程

### 9.4 TLA+ Modeling

- baseline 的模型
- Udding 的模型
- 公共性质定义

### 9.5 Verification Results

- mutual exclusion 检查结果
- deadlock / liveness 分析
- state complexity 比较

### 9.6 Discussion

- Udding 相比 baseline 的收益
- Udding 的复杂度代价
- weak semaphore 语义带来的建模挑战

## 10. 当前建议的执行顺序

建议按下面顺序推进：

1. 先写 baseline 的算法说明和 TLA+ 模型
2. 用它作为对照，把 starvation 风险讲清楚
3. 再整理 Udding 协议的伪代码和流程
4. 建 Udding 的 TLA+ 模型
5. 最后做对比分析

这样做的优点是：

- 先从简单模型开始，容易落地
- 先有一个能跑的 baseline
- 再逐步引入 Udding 的复杂性

## 11. 一句话总结

这个项目最自然的定位是：

> 以单 weak-semaphore mutex 作为 baseline，以 Udding 作为主算法，研究 weak semaphore 条件下 mutual exclusion 与 starvation 风险之间的差异，并用 TLA+ 进行形式化建模和比较。
