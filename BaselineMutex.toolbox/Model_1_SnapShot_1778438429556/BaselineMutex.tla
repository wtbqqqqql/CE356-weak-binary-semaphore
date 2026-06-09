------------------------------ MODULE BaselineMutex ------------------------------
EXTENDS Naturals, FiniteSets

\* Baseline weak-binary-semaphore mutual exclusion model.
\* Each process repeatedly executes:
\* NCS; P(mutex); CS; V(mutex)

CONSTANT Proc

ASSUME Proc /= {}

VARIABLES pc, mutex

Vars == << pc, mutex >>

\* Control-state labels for each process:
\* "ncs"    : non-critical section
\* "trying" : attempting to acquire mutex
\* "cs"     : inside critical section
\* "exit"   : leaving critical section and releasing mutex

Init ==
    /\ pc = [i \in Proc |-> "ncs"]
    /\ mutex = 1

EnterTrying(i) ==
    /\ pc[i] = "ncs"
    /\ pc' = [pc EXCEPT ![i] = "trying"]
    /\ mutex' = mutex

AcquireMutex(i) ==
    /\ pc[i] = "trying"
    /\ mutex = 1
    /\ pc' = [pc EXCEPT ![i] = "cs"]
    /\ mutex' = 0

LeaveCS(i) ==
    /\ pc[i] = "cs"
    /\ pc' = [pc EXCEPT ![i] = "exit"]
    /\ mutex' = mutex

ReleaseMutex(i) ==
    /\ pc[i] = "exit"
    /\ mutex = 0
    /\ pc' = [pc EXCEPT ![i] = "ncs"]
    /\ mutex' = 1

ProcStep(i) ==
    EnterTrying(i)
    \/ AcquireMutex(i)
    \/ LeaveCS(i)
    \/ ReleaseMutex(i)

Next ==
    \E i \in Proc : ProcStep(i)

TypeOK ==
    /\ pc \in [Proc -> {"ncs", "trying", "cs", "exit"}]
    /\ mutex \in {0, 1}

InCS ==
    {i \in Proc : pc[i] = "cs"}

MutualExclusion ==
    Cardinality(InCS) <= 1

Spec ==
    Init /\ [][Next]_Vars

=============================================================================
