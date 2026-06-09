先把背景讲清楚，再把这个项目怎么一步一步做讲清楚。

**Semaphore 背景**

`Semaphore`（信号量）是并发程序里最经典的同步工具之一，用来协调多个进程或线程对共享资源的访问。它本质上是一个共享变量，加上两个原子操作：

- `wait` / `P`：请求资源，如果资源不可用就等待
- `signal` / `V`：释放资源，唤醒别人或者把资源数加回去

最常见的两类是：

- `counting semaphore`
  值可以是 `0, 1, 2, ...`，表示有多少个资源单位可用。
- `binary semaphore`
  值只有 `0` 或 `1`，可以把它看成一种简化版锁。

在你们这个题目里，重点不是普通 binary semaphore，而是 `weak binary semaphore`。

**什么叫 weak binary semaphore**

强弱的区别，不在于它能不能互斥，而在于“等待的人将来能不能公平地被放进去”。

- `strong semaphore`
  通常有较强的排队保证，比如 FIFO。谁先等，谁更早被唤醒，不容易饿死。
- `weak semaphore`
  只保证操作是原子的，但不保证等待队列顺序。一个进程可能一直在等，但总被别的进程抢先，这就会发生 `starvation`。

你们题目里提到的例子是 `test-and-set` 风格实现。它能保证某一时刻最多一个人拿到锁，但不能保证“等得久的人最终一定进去”。

**为什么这题有意思**

这题的难点不只是“互斥”，而是：

- 你只能用 weak binary semaphores
- 进程数 `n` 还是参数，不是固定 2 个
- 你要用 `TLA+` 证明方案正确

所以它考的是两层能力：

- 并发算法设计能力
- 形式化建模和验证能力

**这题里通常关心哪些性质**

1. `Mutual exclusion`
   任意时刻最多一个进程在 critical section。

2. `Deadlock freedom`
   系统不能卡死在“大家都进不去”的状态。

3. `Starvation freedom`
   一个一直请求进入的进程，最终应该能进去。

这里最重要的一点是：  
`weak semaphore` 往往比较容易保证 mutual exclusion，但不容易保证 starvation freedom。

所以你们做项目时，要把“哪些性质能保证，哪些不能保证”说得非常清楚。

**Critical Section 问题背景**

这题本质上属于 `critical section problem`。多个进程共享某个资源，比如：

- 一个共享变量
- 一个文件
- 一个硬件设备
- 一块共享内存

如果两个进程同时修改，就可能出错。所以要设计协议，让它们按规则进入临界区：

- 入口区 `entry section`
- 临界区 `critical section`
- 退出区 `exit section`
- 剩余区 `remainder section`

目标就是既要安全，又尽量有进展性。

---

**你这个项目一步一步怎么做**

我建议按“先做出可跑版本，再扩展分析”的节奏走。

**第 1 步：先把题目翻译成你们自己的明确目标**

把题目改写成一句工程化目标：

- 设计一个只使用 weak binary semaphores 的 `n` 进程 mutual exclusion 算法
- 用 TLA+ 建模
- 证明至少满足 `mutual exclusion`
- 再分析它是否满足 `deadlock freedom` 和 `starvation freedom`

这一步很重要，因为后面报告就围绕这几句话展开。

**第 2 步：先补并发理论背景**

在开始写模型前，你最好先真正理解下面这些概念：

- semaphore / binary semaphore
- weak vs strong fairness
- mutual exclusion
- deadlock
- starvation
- scheduler / overtaking

你现在最需要建立的直觉是：

- “不公平”不一定破坏互斥
- 但“不公平”很容易破坏活性

**第 3 步：选一个具体算法，不要空泛讨论**

项目最怕一直讲概念，没有落地算法。  
你们需要先定一个“候选方案”，哪怕是基础版。

通常可以这样推进：

- 先从 `n = 2` 的直觉出发
- 再推广到一般 `n`
- 或者先找一个 tree / tournament 风格的结构
- 或者先设计一个层级进入协议

重点不是一开始就完美，而是要有“可建模的规则”。

**第 4 步：先写伪代码**

在 TLA+ 之前，先写出人类可读的算法：

- 每个进程本地状态有哪些
- semaphore 有哪些
- 进程什么时候 `wait`
- 进程什么时候 `signal`
- 什么条件下进入 CS
- 退出后释放哪些 semaphore

如果伪代码写不清楚，TLA+ 基本也写不清楚。

**第 5 步：定义你们要验证的性质**

建议分层定义：

- 必做：`MutualExclusion`
- 第二层：`NoDeadlock` 或系统可继续推进
- 第三层：`StarvationFreedom` 或至少说明不满足并给出反例

报告里一定要分清：

- `safety property`
- `liveness property`

这会让整份项目非常清晰。

**第 6 步：建立最小 TLA+ 模型**

第一版模型越小越好。通常先建这些：

- 常量：`N`
- 进程集合：`ProcSet`
- 程序计数器：`pc[i]`
- semaphore 状态
- 必要的辅助变量

然后定义：

- `Init`
- 每个进程可执行的动作
- `Next`
- `Spec`

第一版别追求漂亮，先能跑。

**第 7 步：先只验证 safety**

第一轮只查不变量，例如：

- 同时在 `CS` 的进程数不超过 1

这是最重要的起步。  
如果 safety 都过不了，说明算法或模型基本逻辑有问题，先别碰 liveness。

**第 8 步：跑小规模实例**

先用很小的参数：

- `N = 2`
- `N = 3`
- `N = 4`

看 TLC 是否：

- 很快找到反例
- 状态空间是否爆炸
- 是否有你没想到的 interleaving

小规模模型检查特别适合早期调试。

**第 9 步：再加 fairness 和 liveness**

当 safety 稳定后，再去写：

- weak fairness 假设
- eventual entry
- progress 类性质

这一阶段很可能发现：

- 系统并不会死锁
- 但某个进程可能永远进不去

如果 TLC 给出 trace，这反而是你们报告的高价值内容。

**第 10 步：分析 counterexample**

如果发现 starvation：

- 看是哪几个进程在反复 overtaking
- 看 semaphore 哪一步让某个进程持续吃亏
- 解释为什么这正是 weak semaphore 的本质风险

这一步不要只说“模型失败了”，要说“失败机制是什么”。

**第 11 步：决定项目的最终叙事**

这里有两条都合理的路线。

路线 A：
- 提出一个方案
- 证明它满足 mutual exclusion
- 展示它在 weak semaphore 下可能 starvation

路线 B：
- 先做一个基础方案
- 再提出改进方案
- 比较两个方案在 safety / liveness 上的差别

如果时间紧，我建议先做路线 A，最稳。

**第 12 步：整理报告结构**

你们的报告可以按这个顺序写：

1. Problem statement
2. Background on weak binary semaphore
3. Proposed algorithm
4. TLA+ model
5. Safety properties
6. Liveness analysis
7. TLC results and counterexamples
8. Discussion and limitations
9. Possible improvements

---

**你现在最实际的开工顺序**

如果你今天就开始，我建议这样做：

1. 花 30 到 60 分钟把 semaphore、mutual exclusion、starvation 彻底读懂。
2. 写出一个 1 页以内的算法草稿。
3. 明确要验证的第一个性质：`MutualExclusion`。
4. 开一个最小 TLA+ 文件，把进程状态和 semaphore 变量定义出来。
5. 用 `N = 2` 先跑 TLC。
6. 跑通后再扩展到 `N = 3`。
7. 最后才去碰 liveness。

**一句话总结**

这个项目不要一开始就追求“完整证明所有性质”，最稳的路线是：  
先理解 weak semaphore 为什么会带来 starvation 风险，再先做出一个能在 TLA+ 里验证 mutual exclusion 的最小模型，然后逐步加 liveness 分析和反例讨论。

如果你愿意，我下一步可以直接继续帮你做两件事之一：

1. 用更容易懂的方式给你讲 `weak semaphore` 和 `starvation`，配小例子。  
2. 直接带你开始写这个项目的第一版 TLA+ 建模框架。