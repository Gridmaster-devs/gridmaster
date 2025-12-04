extends OptionButton

# takes a string as a parameter, and if the optionbutton has the string as one of the options, it selects that option 
func select_with_text(search_text : String) -> bool:
	var found = false
	
	for i in self.item_count:
		var t = self.get_item_text(i)
		if (t == search_text):
			found = true
			select(i)
	
	return found
