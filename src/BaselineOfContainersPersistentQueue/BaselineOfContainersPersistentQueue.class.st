Class {
	#name : 'BaselineOfContainersPersistentQueue',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfContainersPersistentQueue',
	#package : 'BaselineOfContainersPersistentQueue'
}

{ #category : 'baselines' }
BaselineOfContainersPersistentQueue >> baseline: spec [
    <baseline>
    spec for: #common do: [
        spec
            package: 'Containers-PersistentQueue';
            package: 'Containers-PersistentQueue-Tests' with: [ 
                spec requires: #('Containers-PersistentQueue') ] ]
]
