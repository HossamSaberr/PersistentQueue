Class {
	#name : 'CTPersistentQueue',
	#superclass : 'Object',
	#instVars : [
		'frontStack',
		'rearStack'
	],
	#category : 'Containers-PersistentQueue',
	#package : 'Containers-PersistentQueue'
}

{ #category : 'requirements' }
CTPersistentQueue class >> empty [
    ^ self new
]

{ #category : 'as yet unclassified' }
CTPersistentQueue class >> front: aFrontStack rear: aRearStack [
    ^ self basicNew initializeFront: aFrontStack rear: aRearStack
]

{ #category : 'comparing' }
CTPersistentQueue >> = anObject [
    "Two queues are equal if they have the same elements in the same order."
    self == anObject ifTrue: [ ^ true ].
    self class = anObject class ifFalse: [ ^ false ].
    self size = anObject size ifFalse: [ ^ false ].
    
    ^ self asArray = anObject asArray
]

{ #category : 'enumerating' }
CTPersistentQueue >> asArray [
    "Extracts the queue's elements into a native Pharo array."
    | extracted |
    extracted := OrderedCollection new.
    self do: [ :each | extracted add: each ].
    ^ extracted asArray
]

{ #category : 'actions' }
CTPersistentQueue >> dequeue [
    ^ frontStack 
        ifEmpty: [ 
            | reversedRear |
            "The front is empty, so we pay the O(N) cost to reverse the rear stack"
            reversedRear := rearStack reversed.
            reversedRear 
                ifEmpty: [ self error: 'Cannot dequeue from an empty queue' ]
                ifNotEmpty: [ :newFront |
                    "Pop the first value, and create the new queue state"
                    newFront value -> (self class 
                        front: newFront next 
                        rear: CTPersistentEmptyNode new) ] ]
        ifNotEmpty: [ :front |
            "The front has elements! O(1) pop and structural sharing of the rear"
            front value -> (self class 
                front: front next 
                rear: rearStack) ]
]

{ #category : 'enumerating' }
CTPersistentQueue >> do: aBlock [
    "Evaluates aBlock for each element in the queue, perfectly preserving the historical state."
    | current currentState |
    current := self.
    [ current isEmpty ] whileFalse: [ 
        currentState := current dequeue.
        aBlock value: currentState key.
        current := currentState value ]
]

{ #category : 'initialization' }
CTPersistentQueue >> enqueue: anObject [
    ^ self class 
        front: frontStack 
        rear: (rearStack push: anObject)
]

{ #category : 'comparing' }
CTPersistentQueue >> hash [
    "Polymorphic hash based on content to match equality."
    ^ self class hash bitXor: self asArray hash
]

{ #category : 'initialization' }
CTPersistentQueue >> initialize [
    super initialize.
    frontStack := CTPersistentEmptyNode new.
    rearStack := CTPersistentEmptyNode new.

]

{ #category : 'initialization' }
CTPersistentQueue >> initializeFront: aFrontStack rear: aRearStack [
    frontStack := aFrontStack.
    rearStack := aRearStack.
    ^ self
]

{ #category : 'as yet unclassified' }
CTPersistentQueue >> inspectionElements: aBuilder [
    <inspectorPresentationOrder: 0 title: 'Queue Elements'>
    
    ^ aBuilder newTable
        addColumn: (SpStringTableColumn 
            title: 'Index (FIFO)' 
            evaluated: [ :assoc | assoc key asString ]);
        addColumn: (SpStringTableColumn 
            title: 'Value' 
            evaluated: [ :assoc | assoc value printString ]);
        items: (self asArray withIndexCollect: [ :each :index | index -> each ]);
        yourself
]

{ #category : 'initialization' }
CTPersistentQueue >> isEmpty [
    ^ frontStack isEmpty and: [ rearStack isEmpty ]
]

{ #category : 'accessing' }
CTPersistentQueue >> peek [
    ^ frontStack 
        ifEmpty: [ 
            | reversedRear |
            reversedRear := rearStack reversed.
            reversedRear 
                ifEmpty: [ self error: 'Cannot peek into an empty queue' ]
                ifNotEmpty: [ :newFront | newFront value ] ]
        ifNotEmpty: [ :front | 
            front value ]
]

{ #category : 'comparing' }
CTPersistentQueue >> printOn: aStream [
    "Standard Smalltalk printing for better debugger visibility."
    | isFirst |
    super printOn: aStream.
    aStream nextPut: $(.
    
    isFirst := true.
    self do: [ :each | 
        isFirst 
            ifTrue: [ isFirst := false ]
            ifFalse: [ aStream nextPutAll: ', ' ].
        each printOn: aStream ].
        
    aStream nextPut: $)
]

{ #category : 'comparing' }
CTPersistentQueue >> size [
    "O(N) size calculation for now. (We can optimize this with a slot later)."
    | count |
    count := 0.
    self do: [ :each | count := count + 1 ].
    ^ count
]
