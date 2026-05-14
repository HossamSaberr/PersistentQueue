Class {
	#name : 'CTPersistentStackNode',
	#superclass : 'Object',
	#category : 'Containers-PersistentQueue',
	#package : 'Containers-PersistentQueue'
}

{ #category : 'converting' }
CTPersistentStackNode >> ifEmpty: emptyBlock ifNotEmpty: notEmptyBlock [
    ^ self subclassResponsibility
]

{ #category : 'testing' }
CTPersistentStackNode >> isEmpty [
    ^ self subclassResponsibility
]

{ #category : 'adding' }
CTPersistentStackNode >> push: anObject [
    ^ CTPersistentValueNode value: anObject next: self
]

{ #category : 'converting' }
CTPersistentStackNode >> reverseOnto: anAccumulatorNode [
    ^ self subclassResponsibility
]

{ #category : 'converting' }
CTPersistentStackNode >> reversed [
    "Initiate the functional reversal with an empty accumulator"
    ^ self reverseOnto: CTPersistentEmptyNode new
]
