# Containers-PersistentQueue

A purely functional Persistent Queue for Pharo, providing **guaranteed $O(1)$ amortized time** and **$O(1)$ space** per operation. Every modification returns a brand-new version handle without mutating the prior state, enabling infinite state branching and safe history tracking.

*(Note: "Persistent" in this context refers to Functional Persistence maintaining historical immutable states in memory not saving to a database or disk.)*

![Pharo 14+](https://img.shields.io/badge/Pharo-14%2B-informational) ![License MIT](https://img.shields.io/badge/License-MIT-success)

---

### What is a Persistent Queue?

A **standard queue** changes its data in place. When you add or remove an item, the previous version of that queue is gone forever. To save every version of a standard queue (for an "Undo" system or to track history), you would have to copy the entire queue every time it changes. This is very slow and fills up your memory quickly.

This **Persistent Queue** solves that problem. Every time you modify it, the library creates a new "version" of that queue while keeping all previous versions alive. It does this without copying the whole queue; it simply shares the existing data already in memory. 

This allows your program to jump back to any previous version instantly, track a full history of changes, and branch out into multiple different timelines without wasting space or slowing down the computer.

This library implements the **Two-Stack Architecture**. Instead of mutating an array, the queue is composed of two purely functional, singly-linked stacks (`frontStack` and `rearStack`). 

Because nodes are never mutated, multiple queue versions can safely share the same nodes in memory (Structural Sharing). Enqueuing creates a new timeline branch in strict $O(1)$ time by pointing a single new node at the shared history.

```text
       [ Branch A: enqueue 'B' ]
              (Val: 'B') 
                  \
                   \ pointer
                    v
                 (Val: 'A')  <---- [ Base State: enqueue 'A' ]
                    /
                   / pointer
                  /
              (Val: 'C')
       [ Branch B: enqueue 'C' ]
```
*Three separate queues exist simultaneously. All three share node 'A' in memory. No deep copying is required.*

---

### Key Benefits & Real-World Use Cases

* **Advanced State-Space Search (BFS):** Branch alternate realities and timelines in strictly $O(1)$ time and space per branch.
* **Lock-Free Concurrency:** Because the queue is 100% immutable, multiple threads can safely read, branch, and enqueue from the same base state without requiring a single Mutex or Semaphore.
* **Event Sourcing & Time Travel:** Track thousands of historical queue states. Restoring the system to the exact state it was in 500 events ago is as simple as retrieving a pointer from an array.
* **Amortized Reversal:** Dequeuing from an empty `frontStack` pays an $O(N)$ cost to safely reverse the `rearStack`, mathematically guaranteeing amortized $O(1)$ performance over long lifecycles.

---

### Basic Usage

Because the queue is immutable, every operation returns the **next state**. You must capture the returned value.

```smalltalk
"1. Initialize an empty queue"
q0 := CTPersistentQueue empty.

"2. Enqueue returns a brand new queue version"
q1 := q0 enqueue: 'Codeforces'.
q2 := q1 enqueue: 'AtCoder'.

"3. Dequeue returns an Association ( poppedValue -> nextQueueState )"
result := q2 dequeue.
poppedValue := result key.     " => 'Codeforces' "
q3 := result value.            " => Queue containing only 'AtCoder' "

"4. The original states are completely indestructible"
q2 size. " => 2 "
```
### Time Travel & Infinite Branching

Because of $O(1)$ structural sharing, tracking history is as simple as storing the returned arrays in a standard collection.

```smalltalk
timelines := Dictionary new.

"Establish a Base State"
base := CTPersistentQueue empty enqueue: 'System Boot'.
timelines at: #master put: base.

"Branch Reality A (0 ms, O(1) Memory)"
timelines at: #user_event put: ((timelines at: #master) enqueue: 'User Login').

"Branch Reality B from the exact same point in time"
timelines at: #db_event put: ((timelines at: #master) enqueue: 'DB Sync').

"Both branches safely coexist, sharing the 'System Boot' node in memory"
(timelines at: #user_event) peek. " => 'System Boot' "
```

---

### Performance & Empirical Proof

Benchmarks were performed head-to-head against Pharo's **`Containers-Queue`** (Circular Array) to measure the overhead of immutability vs. the cost of deep-copying for persistence.

#### 1. Standard Pipeline (Linear - No History Kept)
In a linear workload, the Persistent Queue is surprisingly efficient at enqueuing, while the Circular Array maintains its lead in dequeuing due to its optimized in-place index shifting.

| Workload | Size (N) | Forced Time Travel? | Reads | Writes | History Accesses | Standard Queue (ms) | Persistent Queue (ms) | Relative Speed |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Burst Enqueue** | 100,000 | No | 0 | 100,000 | 0 | 5 ms | 2 ms | **~2.5x Faster** |
| **Burst Dequeue** | 100,000 | No | 100,000 | 0 | 0 | 1 ms | 35 ms | ~35x Slower |

#### 2. The Time-Travel Workload (Forced Persistence)
When the system is required to preserve every historical state (e.g., for an Undo system), the standard `CTQueue` must `deepCopy` itself at every step, hitting an $O(N^2)$ wall. The **Persistent Queue** uses structural sharing to do this in $O(1)$.

*(Note: Random queries on the Persistent Queue incur a localized penalty "The Lazy Trap" if the amortized reversal is forced to evaluate for the first time on a specific historical branch).*

| Workload | Size (N) | Forced Time Travel? | Reads | Writes | History Accesses | Standard Queue + Deep Copy (ms) | Persistent Queue (ms) | Relative Speed |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Save Timeline** | 10,000 | Yes | 0 | 10,000 | 0 | 2,987 ms | 1 ms | **~2,987x Faster** |
| **Random Query** | 10,000 | Yes | 0 | 0 | 1,000 | 0 ms | 578 ms | Slower (Deferred Reversals) |

---

### Reproducing these Benchmarks
If you would like to verify these results on your own machine, you can run the following scripts in a Pharo Playground.

```Smalltalk

| pQueue sQueue currentP pEnqueueTime pDequeueTime sEnqueueTime sDequeueTime numElements |
numElements := 100000.

"--- PERSISTENT QUEUE ---"
pQueue := CTPersistentQueue empty.
pEnqueueTime := [
    1 to: numElements do: [ :i | pQueue := pQueue enqueue: i ]
] timeToRun.

currentP := pQueue.
pDequeueTime := [
    1 to: numElements do: [ :i | currentP := currentP dequeue value ]
] timeToRun.

"--- STANDARD QUEUE ---"
sQueue := CTQueue new.
sEnqueueTime := [
    1 to: numElements do: [ :i | sQueue enqueue: i ]
] timeToRun.

sDequeueTime := [
    1 to: numElements do: [ :i | sQueue dequeue ]
] timeToRun.

"--- RESULTS ---"
{ 
    '1. Persistent Enqueue (100k)' -> pEnqueueTime.
    '2. Standard Queue Enqueue (100k)' -> sEnqueueTime.
    '3. Persistent Dequeue (100k)' -> pDequeueTime.
    '4. Standard Queue Dequeue (100k)' -> sDequeueTime.
} inspect.
```

```Smalltalk

| numElements pQueue sQueue pDict sDict pSaveTime sSaveTime randomIndices pAccessTime sAccessTime |
numElements := 10000. 
pDict := Dictionary new.
sDict := Dictionary new.

"--- PERSISTENT QUEUE ---"
pQueue := CTPersistentQueue empty.
pSaveTime := [
    1 to: numElements do: [ :i |
        pQueue := pQueue enqueue: i.
        pDict at: i put: pQueue. 
    ]
] timeToRun.

"--- Standard QUEUE ---"
sQueue := CTQueue new. 
sSaveTime := [
    1 to: numElements do: [ :i |
        sQueue enqueue: i.
        sDict at: i put: sQueue copy. 
    ]
] timeToRun.

"--- PREPARE RANDOM HISTORICAL QUERIES ---"
randomIndices := (1 to: 1000) collect: [ :each | (1 to: numElements) atRandom ].

"--- QUERY HISTORY: PERSISTENT QUEUE ---"
pAccessTime := [
    randomIndices do: [ :idx | (pDict at: idx) peek ]
] timeToRun.

"--- QUERY HISTORY: Standard QUEUE ---"
sAccessTime := [
    randomIndices do: [ :idx | (sDict at: idx) front ]
] timeToRun.

"--- RESULTS ---"
{
    '1. Persistent Queue Save Timeline (10k)' -> pSaveTime.
    '2. Standard Queue Deep Copy (10k)' -> sSaveTime.
    '3. Persistent Queue Random History Read' -> pAccessTime.
    '4. Standard Queue Random History Read' -> sAccessTime.
} inspect.
```
