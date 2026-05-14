Class {
	#name : 'CTPersistentEmptyNode',
	#superclass : 'CTPersistentStackNode',
	#category : 'Containers-PersistentQueue',
	#package : 'Containers-PersistentQueue'
}

{ #category : 'testing' }
CTPersistentEmptyNode >> ifEmpty: emptyBlock ifNotEmpty: notEmptyBlock [
    ^ emptyBlock value
]

{ #category : 'testing' }
CTPersistentEmptyNode >> isEmpty [
    ^ true
]

{ #category : 'testing' }
CTPersistentEmptyNode >> reverseOnto: anAccumulatorNode [
    "Base case: end of the list. Return the accumulated reversed list."
    ^ anAccumulatorNode
]
