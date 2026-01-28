
## Prompts the user for a download of a file with a specific content and filename
func webDownload(content : Variant, filename : String) -> void:
	var data : PackedByteArray = var_to_bytes_with_objects(content)
	JavaScriptBridge.download_buffer(data, filename)
