Class {
	#name : 'CTPersistentQueueTest',
	#superclass : 'TestCase',
	#instVars : [
		'emptyQueue'
	],
	#category : 'Containers-PersistentQueue-Tests',
	#package : 'Containers-PersistentQueue-Tests'
}

{ #category : 'tests' }
CTPersistentQueueTest >> testBoundaryConditionsAndPeek [
    | q0 q1 |
    q0 := CTPersistentQueue empty.
    
    "1. Dequeuing an empty queue should fail safely"
    self should: [ q0 dequeue ] raise: Error description: 'Empty queue must raise an Error on dequeue'.
    
    "2. Peek should return the value without altering the queue"
    q1 := q0 enqueue: 'Target'.
    self assert: q1 peek equals: 'Target'.
    
    "3. Ensure peek didn't drain the queue"
    self deny: q1 isEmpty.
    self assert: q1 dequeue key equals: 'Target'.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testDequeueTriggersAmortizedReversal [
    | q0 q1 q2 q3 result1 result2 newQueue |
    
    q0 := CTPersistentQueue empty.
    q1 := q0 enqueue: 'A'.
    q2 := q1 enqueue: 'B'.
    q3 := q2 enqueue: 'C'.
    
    "Right now, frontStack is empty, rearStack has (C -> B -> A)"
    
    result1 := q3 dequeue.
    self assert: result1 key equals: 'A'.
    
    newQueue := result1 value.
    result2 := newQueue dequeue.
    self assert: result2 key equals: 'B'.
    
    "CRITICAL: The original q3 must remain completely intact despite the reversal!"
    self assert: q3 dequeue key equals: 'A'.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testDoIteratesInFifoOrder [
    | q elements |
    q := CTPersistentQueue empty.
    q := q enqueue: 'First'.
    q := q enqueue: 'Second'.
    q := q enqueue: 'Third'.

    elements := OrderedCollection new.
    q do: [ :each | elements add: each ].

    "Standard SUnit equality assertion"
    self assert: elements asArray equals: #('First' 'Second' 'Third').


]

{ #category : 'tests' }
CTPersistentQueueTest >> testEmptyQueueHasNoElements [
    | queue |
    queue := CTPersistentQueue empty.
    
    self assert: queue isEmpty.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testEnqueuePreservesImmutability [
    | q1 q2 |
    q1 := CTPersistentQueue empty.
    q2 := q1 enqueue: 'A'.
    
    self assert: q1 isEmpty description: 'The original queue must remain completely empty'.
    self deny: q2 isEmpty description: 'The new queue state should contain the enqueued element'.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testEquality [
    | q1 q2 q3 |
    q1 := CTPersistentQueue empty enqueue: 'A'.
    q1 := q1 enqueue: 'B'.
    
    q2 := CTPersistentQueue empty enqueue: 'A'.
    q2 := q2 enqueue: 'B'.
    
    q3 := CTPersistentQueue empty enqueue: 'A'.
    q3 := q3 enqueue: 'C'.
    
    self assert: q1 equals: q2.
    self deny: q1 = q3.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testHash [
    | q1 q2 q3 |
    q1 := CTPersistentQueue empty enqueue: 'A'.
    q1 := q1 enqueue: 'B'.
    
    q2 := CTPersistentQueue empty enqueue: 'A'.
    q2 := q2 enqueue: 'B'.
    
    q3 := CTPersistentQueue empty enqueue: 'A'.
    q3 := q3 enqueue: 'C'.
    
    self assert: q1 hash equals: q2 hash.
    self deny: q1 = q3.
]

{ #category : 'tests' }
CTPersistentQueueTest >> testPrintOn [
    | q string |
    q := CTPersistentQueue empty enqueue: 1.
    q := q enqueue: 2.
    
    string := String streamContents: [ :str | q printOn: str ].
    
    self assert: (string includesSubstring: '1').
    self assert: (string includesSubstring: '2').
]
