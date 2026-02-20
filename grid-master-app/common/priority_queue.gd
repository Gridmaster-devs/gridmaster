class_name PriorityQueue
extends RefCounted
## Simple priority queue implementation

# Highest priority (lowest priority value) is always the last element
# in the array. The array is always sorted.
var _items : Array[Variant] = []

## Function that the priority of the items is defined by.
## MUST return an int.
var _priority_func : Callable
	

func add_item(item : Variant):
	# If there are no items in the array we can just put the item in
	if (_items.is_empty()):
		_items.append(item)

	# If there are items in the array, we must keep the array sorted
	# We find the first element with a priority
	else:
		var priority = _priority_func.call(item) # Priority of the item to be added
		
		# Function that returns true if the item's priority is lower or equal
		# to the priority of the item to be added
		var find_func = func(i : Variant) -> bool: 
			return (_priority_func.call(i) <= priority)
		
		var first_found : int = _items.find_custom(find_func, 0)
		
		# The item to be added has a lower priority than all items in the queue,
		# so we will put it last
		if (first_found == -1):
			_items.append(item)
		
		# There was an item with lower or equal priority in the queue,
		# so we will put the new item right before it
		else:
			_items.insert(first_found, item)

## Returns and removes the item with the lowest priority value from the queue.
func pop_first() -> Variant:
	return _items.pop_back()


## Returns the item with the lowest priority value from the queue.
func get_first() -> Variant:
	if _items.is_empty():
		return null
	else:
		return _items.back()


## Returns the number of items in the queue.
func item_count() -> int:
	return _items.size()


## The priority func must return an int when fed
## an object of the stored type.
func _init(priority_func : Callable) -> void:
	_priority_func = priority_func
