@icon("uid://oslyo7kflpe1")
extends Node
class_name ProgressRequirementComponent

## Here we setup the required flags that unlocks the interactable.
## the 'flag' as a Stingname -> and the 'bool' to check the state of each flag.
@export var required_flags: Array[StringName] = []

func is_satisfied() -> bool:
	for flag in required_flags:
		if not ProgressManager.has_completed(flag):
			return false
	
	return true
