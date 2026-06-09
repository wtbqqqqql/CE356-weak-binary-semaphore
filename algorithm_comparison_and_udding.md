# Weak Binary Semaphore Project: Algorithm Comparison and Udding Notes

## 1. What this project needs

According to the course requirement, the project topic is:

- implement `n`-process mutual exclusion
- use **only weak binary semaphores**
- show correctness using **TLA+**

So the project should not stop at a generic "critical section" model.  
It should verify a **specific algorithm** under a weak-semaphore setting.

The most relevant algorithm families for this project are:

1. Morris-style starvation-free semaphore algorithms
2. Udding-style weak-semaphore starvation-free algorithms
3. Szymanski / multi-gate mutual exclusion algorithms
4. Tournament / tree-style extensions for `n` processes

## 2. Comparison with the current project

### 2.1 Quick summary table

| Algorithm family | Main idea | Fit for `weak binary semaphore` topic | Good for TLA+ modeling | Main risk |
|---|---|---|---|---|
| Morris | Starvation-free mutual exclusion using weak-style binary semaphores with structured entry discipline | Good | Medium | Old paper style; algorithm details are less friendly at first reading |
| Udding | Avoid individual starvation under weak semaphores using staged/room-style control | Very good | Good | Need careful reading of weak-semaphore assumptions |
| Szymanski | Multi-phase gate protocol for `n`-process mutual exclusion | Medium | Very good | Not the most direct match if the report emphasizes semaphores only |
| Tournament / tree-based | Compose local contention into an `n`-process structure | Medium | Good | Can drift away from the exact weak-semaphore focus |

### 2.2 Morris vs current project

**Why it matches**

- It is a classical mutual exclusion algorithm, not just a toy lock.
- It directly addresses starvation, which is one of the core difficulties caused by weak semaphores.
- It gives you a concrete protocol to model and verify.

**Why it may be less convenient**

- The presentation is older and more compact.
- If the team is still getting comfortable with the semantics, the algorithm can feel harder to unpack than Udding.

**Project fit**

- Good if you want a classic, literature-backed baseline.
- Better as a comparison point or backup choice than as the easiest first implementation.

### 2.3 Udding vs current project

**Why it matches especially well**

- The paper title itself is about **absence of individual starvation using weak semaphores**.
- That is almost exactly the conceptual center of your project.
- It gives you a concrete algorithmic answer to the question:  
  "What can we guarantee when the synchronization primitive is only a weak semaphore?"

**Why it is a strong project candidate**

- It is much closer to the wording of your topic than cache coherence is.
- It naturally supports both:
  - `safety` analysis: mutual exclusion
  - `liveness` analysis: starvation / overtaking / fairness
- It is specific enough to be a real algorithm, not just a vague model.

**Project fit**

- Best single-algorithm candidate for the current project.
- Strong choice if the report wants a clear identity and low risk of scope drift.

### 2.4 Szymanski vs current project

**Why it is still relevant**

- It is a well-known `n`-process mutual exclusion protocol.
- Its multi-stage gate structure is excellent for TLA+ state-machine modeling.

**Why it is not the best direct fit**

- It is more useful as structural inspiration than as the most literal answer to a weak-semaphore-only project.
- If you choose it, you need to explain more carefully how it relates to the weak semaphore setting.

**Project fit**

- Good reference for modeling style and phased entry design.
- Less direct than Udding for this project statement.

### 2.5 Tournament / tree-based algorithms vs current project

**Why they are interesting**

- They provide a clean way to scale local contention rules to `n` processes.
- They are helpful if you want to discuss scalability or structured composition.

**Why they are risky**

- The project can start drifting toward "general `n`-process construction" instead of "weak semaphore semantics".
- They may be better used as a secondary comparison idea, not as the main algorithm.

**Project fit**

- Useful as an extension idea.
- Not the best first choice for the core report.

## 3. Why Udding looks like the best fit

If the project goal is to be:

- clearly different from cache coherence
- clearly more than a tiny homework model
- tightly aligned with the official topic

then Udding is a strong fit because it gives you:

1. a **named algorithm**
2. a **weak-semaphore-centered problem**
3. a **nontrivial liveness angle**
4. a natural path to TLA+ modeling

In other words, Udding lets the project be about:

> the correctness boundary of mutual exclusion under weak semaphore semantics

rather than about:

> a generic critical section example

## 4. Udding algorithm: what it is

### 4.1 High-level idea

Udding's algorithm is designed to avoid **individual starvation** even when the synchronization primitive is only a **weak semaphore**.

The central problem is this:

- a weak semaphore can preserve mutual exclusion
- but it may still allow one process to be overtaken indefinitely

Udding's algorithm addresses that by introducing a more structured entry discipline, instead of letting every contender race directly for the same final access point.

At a high level, the algorithm works like a **multi-stage admission protocol**:

- processes announce their intent to enter
- they pass through controlled waiting regions
- the protocol separates "current contenders" from "new arrivals"
- this reduces the possibility that a waiting process is endlessly bypassed by later ones

That makes it much richer than a trivial one-semaphore lock.

### 4.2 Why it is interesting for this class

Udding is a good CE356 project choice because it naturally supports formal questions such as:

- Does the algorithm satisfy `MutualExclusion`?
- Under what semaphore semantics does it avoid starvation?
- What fairness assumptions are required in TLA+?
- How should "absence of individual starvation" be expressed as a temporal property?

This is exactly the kind of question that turns the project from "a few lines of code" into a real specification-and-verification exercise.

### 4.3 What you would model in TLA+

You do **not** need to model cache internals to use Udding.

A clean model would include:

- a set of processes `Proc`
- each process state `pc[i]`
- the weak binary semaphores used by the algorithm
- any algorithm-specific counters / room variables / gates

The actions would correspond to the algorithm's admission protocol, for example:

- announce intent
- pass gate / room 1
- pass gate / room 2
- enter critical section
- leave and release

The key properties would be:

- `MutualExclusion`
- no global deadlock, if you choose to analyze it
- absence of starvation, or a carefully stated liveness property

## 5. Recommended project framing if you choose Udding

A good report framing could be:

1. Explain weak binary semaphores and why starvation is the hard part.
2. Introduce Udding as a concrete algorithm for absence of individual starvation under weak semaphores.
3. Give pseudocode or a structured algorithm summary.
4. Build a TLA+ model of the algorithm.
5. Verify safety first.
6. Then study liveness / fairness assumptions and starvation-related behavior.

This keeps the project:

- clearly algorithm-centered
- clearly different from cache coherence
- clearly stronger than a small homework-style mutex model

## 6. Suggested references

### 6.1 Most important paper for the current direction

- J. T. Udding, **"Absence of individual starvation using weak semaphores"**, *Information Processing Letters*, 23(3), 1986, pp. 159-162.  
  DOI: [10.1016/0020-0190(86)90117-1](https://doi.org/10.1016/0020-0190(86)90117-1)  
  ScienceDirect page: [Absence of individual starvation using weak semaphores](https://www.sciencedirect.com/science/article/pii/0020019086901171/pdf?md5=e32678b239f425a7fd498e8e89ebfafa&pid=1-s2.0-0020019086901171-main.pdf)  
  Eindhoven research portal page: [TU/e entry for Udding 1986](https://research.tue.nl/en/publications/absence-of-individual-starvation-using-weak-semaphores/)

### 6.2 Closely related classic paper

- J. M. Morris, **"A starvation-free solution to the mutual exclusion problem"**, *Information Processing Letters*, 8(2), 1979, pp. 76-80.  
  DOI: [10.1016/0020-0190(79)90147-9](https://doi.org/10.1016/0020-0190(79)90147-9)  
  ScienceDirect page: [A starvation-free solution to the mutual exclusion problem](https://www.sciencedirect.com/science/article/pii/0020019079901479)

### 6.3 Best overview / comparison paper

- Wim H. Hesselink and Mark IJbema, **"Starvation-free mutual exclusion with semaphores"**, *Formal Aspects of Computing*, 25, 2013, pp. 947-969.  
  DOI: [10.1007/s00165-011-0219-y](https://doi.org/10.1007/s00165-011-0219-y)  
  Springer page: [Starvation-free mutual exclusion with semaphores](https://link.springer.com/article/10.1007/s00165-011-0219-y)

This paper is especially useful because it explicitly discusses several classical semaphore-based algorithms and compares their assumptions.

### 6.4 Supporting algorithm reference

- B. K. Szymanski, **"Mutual exclusion revisited"**, Proceedings of the Fifth Jerusalem Conference on Information Technology, 1990, pp. 110-117.  
  Citation context appears in the Hesselink & IJbema reference list above.

## 7. PPT and course materials you can directly reference

### 7.1 Your local course slide deck

- [Lecture5.pptx](/D:/nu_courses/ce356/lectures/Lecture5.pptx)

How it helps:

- shows the course style of moving from a real system example to an abstract formal model
- useful as support for how to write the modeling section
- especially relevant for the idea of abstract interface vs inner mechanism

### 7.2 Official course project requirements

- [projects.pdf](/D:/nu_courses/ce356/course_files_export0408/projects.pdf)

How it helps:

- confirms that your exact topic is:
  - implement `n`-process mutual exclusion
  - use only weak binary semaphores
  - show correctness using TLA+

## 8. Practical recommendation

If the team wants the lowest-risk, highest-fit plan, a strong direction is:

1. Use **Udding** as the main algorithmic reference.
2. Use **Morris** as background / comparison.
3. Use **Hesselink & IJbema** to explain the broader algorithm family and terminology.
4. Build a TLA+ model around the Udding-style admission structure.

That would give the project a clear identity:

- not cache coherence
- not a trivial semaphore toy model
- but a concrete formal study of a named weak-semaphore mutual exclusion algorithm
