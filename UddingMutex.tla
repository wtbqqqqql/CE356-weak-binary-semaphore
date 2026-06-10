------------------------------- MODULE UddingMutex -------------------------------
EXTENDS Naturals, FiniteSets

\* Udding-style weak-semaphore mutual exclusion protocol.
\* The control flow follows the staged admission structure:
\*
\*   P(enter); ne := ne + 1; V(enter);
\*   P(queue); P(enter);
\*   nm := nm + 1; ne := ne - 1;
\*   if ne > 0 then V(enter) else V(mutex);
\*   V(queue);
\*   P(mutex); nm := nm - 1;
\*   CS;
\*   if nm > 0 then V(mutex) else V(enter)

CONSTANT Proc

ASSUME Proc /= {}

VARIABLES pc, enter, queue, mutex, ne, nm

Vars == << pc, enter, queue, mutex, ne, nm >>

\* PC labels:
\* "ncs"      : non-critical section
\* "e1"       : waiting at first P(enter)
\* "ne_inc"   : execute ne := ne + 1
\* "e1_rel"   : execute first V(enter)
\* "q_wait"   : waiting at P(queue)
\* "e2_wait"  : waiting at second P(enter)
\* "nm_inc"   : execute nm := nm + 1
\* "ne_dec"   : execute ne := ne - 1
\* "handoff"  : execute if ne > 0 then V(enter) else V(mutex)
\* "q_rel"    : execute V(queue)
\* "mu_wait"  : waiting at P(mutex)
\* "nm_dec"   : execute nm := nm - 1
\* "cs"       : critical section

Init ==
    /\ pc = [i \in Proc |-> "ncs"]
    /\ enter = 1
    /\ queue = 1
    /\ mutex = 0
    /\ ne = 0
    /\ nm = 0

StartAttempt(i) ==
    /\ pc[i] = "ncs"
    /\ pc' = [pc EXCEPT ![i] = "e1"]
    /\ UNCHANGED << enter, queue, mutex, ne, nm >>

PEnter1(i) ==
    /\ pc[i] = "e1"
    /\ enter = 1
    /\ pc' = [pc EXCEPT ![i] = "ne_inc"]
    /\ enter' = 0
    /\ UNCHANGED << queue, mutex, ne, nm >>

IncNE(i) ==
    /\ pc[i] = "ne_inc"
    /\ pc' = [pc EXCEPT ![i] = "e1_rel"]
    /\ ne' = ne + 1
    /\ UNCHANGED << enter, queue, mutex, nm >>

VEnter1(i) ==
    /\ pc[i] = "e1_rel"
    /\ enter = 0
    /\ pc' = [pc EXCEPT ![i] = "q_wait"]
    /\ enter' = 1
    /\ UNCHANGED << queue, mutex, ne, nm >>

PQueue(i) ==
    /\ pc[i] = "q_wait"
    /\ queue = 1
    /\ pc' = [pc EXCEPT ![i] = "e2_wait"]
    /\ queue' = 0
    /\ UNCHANGED << enter, mutex, ne, nm >>

PEnter2(i) ==
    /\ pc[i] = "e2_wait"
    /\ enter = 1
    /\ pc' = [pc EXCEPT ![i] = "nm_inc"]
    /\ enter' = 0
    /\ UNCHANGED << queue, mutex, ne, nm >>

IncNM(i) ==
    /\ pc[i] = "nm_inc"
    /\ pc' = [pc EXCEPT ![i] = "ne_dec"]
    /\ nm' = nm + 1
    /\ UNCHANGED << enter, queue, mutex, ne >>

DecNE(i) ==
    /\ pc[i] = "ne_dec"
    /\ ne > 0
    /\ pc' = [pc EXCEPT ![i] = "handoff"]
    /\ ne' = ne - 1
    /\ UNCHANGED << enter, queue, mutex, nm >>

InnerHandoff(i) ==
    /\ pc[i] = "handoff"
    /\ pc' = [pc EXCEPT ![i] = "q_rel"]
    /\ IF ne > 0
          THEN /\ enter' = 1
               /\ mutex' = mutex
          ELSE /\ mutex' = 1
               /\ enter' = enter
    /\ UNCHANGED << queue, ne, nm >>

VQueue(i) ==
    /\ pc[i] = "q_rel"
    /\ queue = 0
    /\ pc' = [pc EXCEPT ![i] = "mu_wait"]
    /\ queue' = 1
    /\ UNCHANGED << enter, mutex, ne, nm >>

PMutex(i) ==
    /\ pc[i] = "mu_wait"
    /\ mutex = 1
    /\ pc' = [pc EXCEPT ![i] = "nm_dec"]
    /\ mutex' = 0
    /\ UNCHANGED << enter, queue, ne, nm >>

DecNM(i) ==
    /\ pc[i] = "nm_dec"
    /\ nm > 0
    /\ pc' = [pc EXCEPT ![i] = "cs"]
    /\ nm' = nm - 1
    /\ UNCHANGED << enter, queue, mutex, ne >>

LeaveCS(i) ==
    /\ pc[i] = "cs"
    /\ pc' = [pc EXCEPT ![i] = "ncs"]
    /\ IF nm > 0
          THEN /\ mutex' = 1
               /\ enter' = enter
          ELSE /\ enter' = 1
               /\ mutex' = mutex
    /\ UNCHANGED << queue, ne, nm >>

ProcStep(i) ==
       StartAttempt(i)
    \/ PEnter1(i)
    \/ IncNE(i)
    \/ VEnter1(i)
    \/ PQueue(i)
    \/ PEnter2(i)
    \/ IncNM(i)
    \/ DecNE(i)
    \/ InnerHandoff(i)
    \/ VQueue(i)
    \/ PMutex(i)
    \/ DecNM(i)
    \/ LeaveCS(i)

Next ==
    \E i \in Proc : ProcStep(i)

TypeOK ==
    /\ pc \in [Proc -> {"ncs", "e1", "ne_inc", "e1_rel", "q_wait", "e2_wait",
                        "nm_inc", "ne_dec", "handoff", "q_rel",
                        "mu_wait", "nm_dec", "cs"}]
    /\ enter \in {0, 1}
    /\ queue \in {0, 1}
    /\ mutex \in {0, 1}
    /\ ne \in Nat
    /\ nm \in Nat

SplitBinary ==
    enter + mutex \in {0, 1}

InCS ==
    {i \in Proc : pc[i] = "cs"}

MutualExclusion ==
    Cardinality(InCS) <= 1

InCSProc(i) ==
    pc[i] = "cs"

Requesting(i) ==
    pc[i] \in {"e1", "ne_inc", "e1_rel", "q_wait", "e2_wait",
               "nm_inc", "ne_dec", "handoff", "q_rel",
               "mu_wait", "nm_dec"}

\* If a process has started one admission attempt, we want it to
\* eventually reach the critical section under the fairness assumptions.
StarvationFree(i) ==
    Requesting(i) ~> InCSProc(i)

NoStarvation ==
    \A i \in Proc : StarvationFree(i)

\* Weak process fairness: if a process step remains continuously enabled,
\* the scheduler cannot ignore it forever.
ProcessFairness ==
    \A i \in Proc : WF_Vars(ProcStep(i))

\* Service fairness for the blocking semaphore acquisitions. This is the
\* fairness layer that rules out the liveness counterexample where the
\* same process keeps winning the same contention point forever.
SemaphoreFairness ==
    \A i \in Proc :
        /\ SF_Vars(PEnter1(i))
        /\ SF_Vars(PQueue(i))
        /\ SF_Vars(PEnter2(i))
        /\ SF_Vars(PMutex(i))

Spec ==
    Init /\ [][Next]_Vars

FairSpec ==
    Spec /\ ProcessFairness /\ SemaphoreFairness

=============================================================================
