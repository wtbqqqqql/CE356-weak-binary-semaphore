# 引言与项目介绍

## 1. 项目背景

在本次 CE356 的 project 中，我们小组选择研究 **Weak Binary Semaphore** 相关问题。课程题目指出，weak binary semaphore 是一种只具有弱公平性（weak fairness）的二元信号量。与课程选题列表中的 **Cache Coherence** 不同，我们的项目重点不在于建模完整的缓存一致性协议，而在于研究：当底层同步原语只具有弱公平性时，如何为多个线程或多个并发任务设计正确的互斥机制，并尽可能保证等待者能够公平地获得进入 critical section 的机会。

更具体地说，我们关注的是这样一个问题：多个进程、线程或任务反复竞争同一个共享 critical section，而 weak binary semaphore 本身并不保证等待者按公平顺序获得资源。因此，在最简单的互斥方案下，某些等待进程可能被后来者反复插队，甚至长期无法进入 critical section。如何在只允许使用 weak binary semaphores 的条件下，构造一个适用于 `n` 个进程的 mutual exclusion protocol，并用 TLA+ 对其正确性进行形式化验证，是本项目的核心目标。

## 2. 项目目标

本项目的总体目标是围绕 weak binary semaphore 的局限性，比较朴素互斥方案与改进协议之间的差异，并分析更复杂的协议到底带来了什么收益。我们的研究重点包括以下几个方面：

- 在 weak semaphore 语义下，最传统的单 `mutex` 互斥方案能够保证什么性质；
- 为什么该 baseline 虽然可以满足 mutual exclusion，却可能导致 individual starvation；
- Udding Algorithm 如何通过更复杂的准入结构缓解或避免等待进程被无限次插队；
- 更强的 progress guarantee 是否必然带来更复杂的 TLA+ 状态空间。

## 3. 项目分阶段思路

为了保证项目能够按阶段稳步推进，我们将整个工作分成多个目标和阶段性任务。

### 3.1 理论与建模准备

首先，我们将结合课程材料与相关参考资料，建立对并发互斥问题和形式化建模方法的基础理解。主要参考内容包括：

- Chapter 4 中关于 **Peterson’s Algorithm** 的内容，用于理解经典 mutual exclusion protocol 的结构；
- Chapter 5 中关于 **Caching Memory** 的建模方式，用于学习如何将一个现实并发问题抽象为形式化状态机模型；
- 操作系统与并发编程的相关学习资料，用于进一步理解 semaphore、mutual exclusion、deadlock 和 starvation 等核心概念。

### 3.2 建立 baseline 模型

在具备基本背景后，我们将首先构建一个最自然、最传统的 baseline：单 `mutex` 互斥方案。该方案通常可表示为：

```text
NCS;
P(mutex);
CS;
V(mutex);
```

其中 `mutex` 是一个 weak binary semaphore。这个 baseline 的优点在于结构简单、直观，适合作为后续比较的参考对象。它能够很好地体现 mutual exclusion 的基本思想，但同时也正好暴露出 weak semaphore 下的关键问题：虽然同一时刻最多只有一个进程进入 critical section，但某些进程仍可能因为竞争失败而长期无法进入，即出现 individual starvation。

因此，baseline 的作用不是给出最终答案，而是作为一个对照对象，帮助我们清楚说明 weak fairness 下“简单互斥不等于公平进入”。

### 3.3 引入 Udding Algorithm 作为核心协议

在 baseline 的基础上，我们将引入通过文献调研得到的 **Udding Algorithm** 作为本次项目的核心实现目标。与单一 `mutex` 的直接竞争不同，Udding 协议通过更复杂的准入结构组织等待进程的推进过程，主要是通过多个 semaphore 以及辅助计数器将“已经在等待链条中的进程”与“后来到达的进程”区分开，从而尽量避免等待者被无限次插队。

Udding 协议的核心价值在于，它不只是简单地保证 mutual exclusion，而是进一步关注 weak semaphore 条件下的 progress 问题，尤其是 individual starvation 的风险。因此，它非常适合作为本项目的核心研究对象。

## 4. 比较与分析维度

为了系统地展示 baseline 和 Udding 之间的差异，我们计划从以下三个维度进行比较和分析。

### 4.1 Mutual Exclusion

这是最基本的 safety 性质，也是整个项目的基础。我们将比较：

- baseline 是否满足 mutual exclusion；
- Udding 是否满足 mutual exclusion。

预期结果是：两者都应当满足 mutual exclusion。也就是说，在 safety 层面，baseline 与 Udding 都能够保证任意时刻最多只有一个进程位于 critical section。

### 4.2 Starvation Risk

这是本项目最关键、也最有研究价值的比较维度。我们将重点分析：

- baseline 在 weak semaphore 条件下为什么可能出现 starvation；
- Udding 如何通过更复杂的协议结构避免 individual starvation。

这一部分正好对应老师题目中强调的难点：单个 weak binary semaphore 虽然足以保护 critical section，但并不能自动保证等待者的公平进入。

### 4.3 TLA+ State Complexity

最后，我们还将从形式化验证的角度比较两种方案的模型复杂度。

- baseline 的 TLA+ 模型状态较少、结构较简单，因此更容易建模和验证；
- Udding 的 TLA+ 模型包含更多状态、更多动作以及更大的状态空间，因此验证成本也更高。

这个维度能够体现出一个重要事实：更强的行为保证往往意味着更复杂的形式化模型，而形式化验证本身也会更加具有挑战性。
