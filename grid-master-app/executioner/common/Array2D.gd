class_name Array2D
## Class that represents a 2D array

var internal_array : Array[Variant] = [] ## The internal 1D array storing all the elements
var width : int ## Width of the array
var height : int ## Height of the array


## Makes sure the parameters of a function call are within bounds
func checkBounds(x : int, y : int):
	assert(x >= 0 and x < width and y >= 0 and y < height, "Array2D parameters out of bounds!")


## Returns the item at the specified index
func getItem(x : int, y : int) -> Variant:
	checkBounds(x, y)
	return internal_array[width * y + x]
	

## Sets the item at the specified index to value
func setItem(x : int, y : int, value : Variant) -> void:
	checkBounds(x, y)
	internal_array[width * y + x] = value


## Function that maps an array to another array
##
## Returns an array of the same size as the original, but where each element
## has been processed by the process function.
## Use the ignore null flag to pass over items that are null
func map(process_func : Callable, ignore_null : bool) -> Array2D:
	var return_array = Array2D.new(width, height)
	
	for i in height:
		for j in width:
			var item = getItem(i, j)
			
			if (item == null) and (ignore_null == true) :
				return_array.setItem(i, j, null)
			else:
				return_array.setItem(i, j, process_func.call(item))

	return return_array


## Function that calls the process function for each element in the array
##
## Use the ignore null flag to pass over elements that are null
func foreach(process_func : Callable, ignore_null : bool) -> void:
	for i in height:
		for j in width:
			var item = getItem(i, j)
			
			if (item == null) and (ignore_null == true) :
				pass
			else:
				process_func.call(item)


## Sets the element at each index based on the fill function
##
## The fill function takes the width and height indices as parameters
func fill(fill_func : Callable):
	for i in height:
		for j in width: 
			setItem(i, j, fill_func.call(i, j))


## Calls the to string function on all the elements
func printAll():
	for i in height:
		for j in width:
			var ret_string : String = ""
			ret_string += ("(%s, %s) " % [j, i])
			var obj = getItem(j, i)
			if (obj == null):
				ret_string += ("N/A")
			else:
				ret_string += (obj._to_string())
			
			print(ret_string)
			
			#if (j == width - 1):
				#print("\n")
			#else:
				#print(", ")


func contentToString() -> String:
	var ret_string : String = ""
	for i in height:
		for j in width:
			ret_string += ("(%s, %s) " % [j, i])
			var obj = getItem(j, i)
			if (obj == null):
				ret_string += ("N/A")
			else:
				ret_string += (obj._to_string())
			
			ret_string += "\n"
			
	return ret_string


func _init(width_p : int, height_p : int):
	width = width_p
	height = height_p
	
	internal_array.resize(width * height)
