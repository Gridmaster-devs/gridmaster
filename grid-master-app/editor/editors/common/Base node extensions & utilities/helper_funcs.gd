class_name HelperFuncs

# takes a string as a parameter, and if the optionbutton has the string as one of the options, it selects that option 
static func select_with_text(ob : OptionButton, search_text : String) -> bool:
	var found = false
	
	for i in ob.item_count:
		var t = ob.get_item_text(i)
		if (t == search_text):
			found = true
			ob.select(i)
	
	return found
	
static func get_text_selected(ob : OptionButton) -> String:
	var s : int = ob.selected
	if (s != -1):
		return ob.get_item_text(s)
	else:
		return ""
