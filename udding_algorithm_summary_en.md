# Udding Algorithm Summary

Source paper:

- Jan Tijmen Udding, **"Absence of individual starvation using weak semaphores"**, *Information Processing Letters*, 23(3), 1986, pp. 159-162.
- Local copy: [udding_algorithm.pdf](/D:/nu_courses/ce356/assignment/project/udding_algorithm.pdf)

## 1. What problem Udding is solving

Udding studies the classical mutual exclusion problem:

- each process repeatedly executes `NCS -> CS -> NCS -> ...`
- at most one process may be in the critical section (`CS`) at a time
- the only synchronization primitives available are **weak semaphores**

The required properties are:

1. mutual exclusion
2. absence of deadlock
3. absence of individual starvation

The key difficulty is that a weak semaphore does **not** guarantee fair service among blocked processes.  
So the standard solution

```text
do true ->
    NCS;
    P(mutex);
    CS;
    V(mutex)
od
```

preserves mutual exclusion, but it does **not** prevent starvation.

## 2. What "weak semaphore" means in this paper

The paper distinguishes:

- **strong semaphore**: there is a bound on how many times a process can be bypassed
- **weak semaphore**: such starvation-freedom at the semaphore itself is not guaranteed

Udding still assumes one minimal property of weak semaphores:

- if a process performs `V(s)` on semaphore `s`, and some process is already blocked on `P(s)`, then the same process that executed `V(s)` will **not** immediately retake `s` with the next `P(s)`; one of the waiting processes must be allowed to pass

This is a very weak fairness assumption, but it is enough to build a stronger protocol on top.

## 3. High-level intuition of the algorithm

The problem with the standard one-semaphore mutex is:

- after a process executes `V(mutex)`, it may quickly return and do `P(mutex)` again
- with three or more processes, this can allow one process to repeatedly overtake others
- some waiting process may never reach `CS`

Udding's idea is:

- do **not** let all contenders race directly for `mutex`
- instead, introduce a structured admission discipline
- separate "new arrivals" from the group already being sluiced toward the critical section
- make progress happen in stages

So the algorithm is not just "a lock".  
It is a **multi-stage protocol** built from weak semaphores.

## 4. How the paper derives the final algorithm

One very nice feature of the paper is that it does not just present the final code.  
It derives it step by step.

### Stage 1: standard mutex

The naive solution uses only one binary semaphore `mutex`.

Problem:

- starvation may happen because a process can re-contend too quickly after releasing `mutex`

### Stage 2: split the entry control

Udding introduces another semaphore `enter`, together with `mutex`, forming a **split binary semaphore**:

```text
0 <= mutex + enter <= 1
```

Intuition:

- `enter` controls whether new processes may continue toward `mutex`
- `mutex` controls the flow of the processes that are already in the current batch

He also introduces:

- `nm`: number of processes waiting at `P(mutex)`

Goal:

- once a set of processes has assembled at `mutex`, stop new arrivals from interfering until this set has been pushed through

### Stage 3: count processes waiting earlier in the pipeline

The previous idea only moves the starvation problem from `mutex` to `enter`.

So Udding introduces:

- `ne`: number of processes waiting at `P(enter)`

This lets the algorithm decide:

- when it is safe to open `mutex`
- when `enter` should keep serving earlier waiters

At this point the algorithm already has the shape of:

- an outer waiting population
- an inner waiting population
- logic deciding which gate to release next

### Stage 4: protect the second `P(enter)`

The crucial remaining problem is that processes blocked at the **first** `P(enter)` must get priority over those blocked at the **second** `P(enter)`.

Udding observes:

- if multiple processes are competing at the second `P(enter)`, they can interfere with the desired priority discipline
- therefore, the second `P(enter)` needs its own local mutual exclusion mechanism

So he adds one more binary semaphore:

- `queue`

This queues processes before they perform the second `P(enter)`.

That is the final step that makes the construction work.

## 5. Final algorithm in the paper

The final program given by Udding is:

```text
P(enter); ne := ne + 1; V(enter);
P(queue); P(enter); nm := nm + 1;
ne := ne - 1;
if ne > 0 -> V(enter)
[] ne = 0 -> V(mutex)
fi;
V(queue);
P(mutex);
nm := nm - 1;
CS;
if nm > 0 -> V(mutex)
[] nm = 0 -> V(enter)
fi
```

Initial values:

- `queue = 1`
- `enter = 1`
- `mutex = 0`

Shared variables:

- `ne`: number of processes blocked at `queue` or at the second `P(enter)`
- `nm`: number of processes waiting at `P(mutex)`

## 6. How to read the final algorithm

A useful way to understand the final algorithm is to split it into phases.

### Phase A: announce entry

```text
P(enter); ne := ne + 1; V(enter);
```

Meaning:

- a process safely registers itself as an entering contender
- `ne` counts processes that are trying to move inward

### Phase B: serialize access to the second gate

```text
P(queue); P(enter); nm := nm + 1;
ne := ne - 1;
V(queue);
```

Meaning:

- `queue` ensures that processes do not pile up uncontrollably at the second `P(enter)`
- only one process at a time moves through this second gate structure
- once through, the process joins the group waiting for `mutex`

### Phase C: wait for the current batch to reach the critical section

```text
if ne > 0 -> V(enter)
[] ne = 0 -> V(mutex)
fi;
V(queue);
P(mutex);
```

Meaning:

- after joining the inner group, the process decides whether to reopen `enter`
  or continue draining the inner batch through `mutex`
- only then does it release `queue`, allowing the next process to approach the
  second `P(enter)`
- finally it waits at `P(mutex)` to be admitted to `CS`

### Phase D: handoff after passing `mutex`

```text
nm := nm - 1;
CS;
```

Meaning:

- after `P(mutex)` succeeds, the process is no longer counted in `nm`
- the process is now the one admitted to the critical section

### Phase E: leave the critical section

```text
if nm > 0 -> V(mutex)
[] nm = 0 -> V(enter)
fi
```

Meaning:

- after finishing the critical section, if more processes are waiting at `mutex`, continue serving them
- if the inner group is empty, reopen `enter` so the next outer group can proceed

This creates the batch-like flow of the algorithm.

## 7. Why the algorithm avoids starvation

The core reason is:

- new arrivals do not compete in an uncontrolled way with processes that are already deeper in the protocol
- `queue` prevents bad interference at the second `P(enter)`
- `enter` and `mutex` together regulate whether the system is:
  - admitting new contenders inward, or
  - draining the already admitted inner group

So a waiting process cannot be overtaken forever by fresh arrivals.

The paper's conclusion is that this protocol establishes:

- mutual exclusion
- no deadlock
- absence of individual starvation

using only weak semaphores.

## 8. Why this algorithm is a good project candidate

This algorithm is a strong fit for the CE356 project because:

1. it is a **specific named protocol**, not a toy mutex
2. it directly matches the course topic: weak semaphores + `n`-process mutual exclusion
3. it has both:
   - a safety side: mutual exclusion
   - a liveness side: starvation freedom
4. it is structured enough to build a meaningful TLA+ model

## 9. What you would model in TLA+

A reasonable TLA+ model would include:

- `Proc`: the process set
- `pc[i]`: control location of process `i`
- binary semaphores:
  - `enter`
  - `queue`
  - `mutex`
- counters:
  - `ne`
  - `nm`

Typical control states might be:

- `idle`
- `at_enter_1`
- `at_queue`
- `at_enter_2`
- `at_mutex`
- `cs`
- `exit`

Main safety property:

- at most one process is in `cs`

Main liveness question:

- how to express and check absence of starvation under the chosen fairness assumptions

## 10. One-sentence summary

Udding's algorithm is a staged mutual exclusion protocol that uses `enter`, `queue`, and `mutex` plus counters `ne` and `nm` to prevent individual starvation even when the underlying semaphores are weak.
