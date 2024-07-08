extends Control


@onready var graphics_screen: TextureRect = $TextureRect
@onready var char_id: Label = $charID
@onready var coords: Label = $coords
@onready var file_result: Label = $fileResult
@onready var file_open_dialog: FileDialog = $FileOpenDialog
@onready var file_save_dialog: FileDialog = $FileSaveDialog


var graphics_buffer: Image
var graphics_texture : ImageTexture
var activechar: int = 0
var chardb: Array[String] = []
var charFlag: Array[int] = []


func _ready() -> void:
	chardb.resize(2056)
	charFlag.resize(256)
	setup_graphics()


func _on_gui_input(event: InputEvent) -> void:
	if InputEventMouse and event.is_pressed():
		var x: int = int(event.position.x)
		var y: int = int(event.position.y)
		
		if x <= 320 and y <= 320:
			x = int(float(x)/40)
			y = int(float(y)/40)
			flip_char_bit(x,y)
	
	if event.position.x <= 320 and event.position.y <= 320:		
		coords.text = str(int(event.position.x/40)) + "," + str(int(event.position.y/40))


func _on_load_button_pressed() -> void:
	file_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_open_dialog.set_use_native_dialog(true)
	file_open_dialog.set_root_subfolder("/users/trigcharters/documents/coding/viro/")
	file_open_dialog.set_current_path("/users/trigcharters/documents/coding/viro/")
	file_open_dialog.set_filters(PackedStringArray(["*.db ; Font Files"]))
	file_open_dialog.show()


func _on_file_open_dialog_file_selected(path: String) -> void:
	if path.ends_with(".db"):
		load_font_db(path)
	else:
		file_result.text = "Invalid Font file Name."


func load_font_db(path: String) -> void:
	var fileData: String = get_file_contents(path)
	if fileData.begins_with("Error"):
		file_result.text = fileData
	else:
		var sectionData: Array = fileData.split("|",false)
		var charFlags: Array = sectionData[0].split(",",false)
		for i in range(charFlags.size()):
			charFlag[i] = charFlags[i].to_int()
				
		var fileLines: Array = sectionData[1].split(",",false)
		for i: int in range(fileLines.size()):
			if fileLines[i] == "0":
				chardb[i] = ""
			else:
				chardb[i] = to_binary(fileLines[i].to_int())

	activechar = 0
	draw_chararcter()	

func _on_load_internal_button_pressed() -> void:
	load_font_db("res://font.db")


func _on_save_button_pressed() -> void:
	file_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_save_dialog.set_use_native_dialog(true)
	file_save_dialog.set_root_subfolder("/users/trigcharters/documents/coding/viro/")
	file_save_dialog.set_current_path("/users/trigcharters/documents/coding/viro/")
	file_save_dialog.set_filters(PackedStringArray(["*.db ; Font Files"]))
	file_save_dialog.show()


func _on_file_save_dialog_file_selected(path: String) -> void:
	if path.ends_with(".db"):
		save_font_db(path)
	else:
		file_result.text = "Invalid Font file Name."


func save_font_db(path: String) -> void:
	var savedb: Array[String] = chardb.duplicate()
	var flagdb: Array[String] = []
	
	for i: int in range(charFlag.size()):
		flagdb.append(str(charFlag[i]))
			
	for i: int in range(savedb.size()):
		if savedb[i].is_empty() or savedb[i] == "00000000":
			savedb[i] = "0"

	for i: int in range(savedb.size()):
		if savedb[i] != "0":
			var val: int = binary_to_int(savedb[i])
			savedb[i] = str(val)
	
	var flagData: String = ",".join(flagdb)		
	var fileData: String = ",".join(savedb)
	file_result.text = save_file(path, flagData + "|" + fileData)


func _on_clear_button_pressed() -> void:
	for i: int in range(8):
		chardb[(activechar * 8) + i] = ""
	draw_chararcter()


func _on_plus_10_pressed() -> void:
	activechar += 10
	if activechar > 255:
		activechar = 255
	draw_chararcter()


func _on_minus_10_pressed() -> void:
	activechar -= 10
	if activechar < 0:
		activechar = 0
	draw_chararcter()


func _on_pre_button_pressed() -> void:
	if activechar > 0:
		activechar -= 1
		draw_chararcter()


func _on_next_button_pressed() -> void:
	if activechar < 255:
		activechar += 1
		draw_chararcter()


func flip_char_bit(x: int, y: int) -> void:
	var charLine: String = chardb[(8 * activechar) + y]
	if charLine.is_empty():
		charLine = "00000000"

	var charBits: Array = charLine.split("",true)
	if charBits[x] == "0":
		charBits[x] = "1"
	else:
		charBits[x] = "0"

	chardb[(8 * activechar) + y] = "".join(charBits)
	
	var startline: int = 7
	var endLine: int = 0
	
	#Set the has data flag
	charFlag[activechar] = 0
	for i: int in range(8):
		if chardb[(8 * activechar) + i].is_empty() or chardb[(8 * activechar) + i] == "00000000":
			pass
		else:
			charFlag[activechar] = 1
			if i < startline: startline = i
			if i > endLine: endLine = i
			
	if charFlag[activechar] > 0:
		charFlag[activechar] = ((endLine + 1) * 100) + startline
	
	draw_chararcter()


func draw_chararcter() -> void:
	var charLine: int = 8 * activechar
	graphics_buffer.fill(Color.BLACK)
	for i: int in range(8):
		var charLineBits: String = chardb[charLine + i]
		if charLineBits.is_empty() == false:
			var BitPos: int = charLineBits.find("1",0)
			while BitPos > -1:
				graphics_buffer.fill_rect(Rect2i((BitPos*40) + 3,(i*40) + 3,35,35),Color.WHITE)
				BitPos = charLineBits.find("1",BitPos + 1)
	
	draw_grid()
	update_graphics()
	char_id.text = "ASCII Code: " + str(activechar)


func setup_graphics() -> void:
	graphics_buffer = Image.create(320,320,true,Image.FORMAT_RGBA8)
	graphics_buffer.fill(Color.BLACK)
	graphics_texture = ImageTexture.create_from_image(graphics_buffer)
	graphics_screen.texture = graphics_texture


func draw_grid() -> void:
	var x: int = 0
	for i in range(8):
		if x > 0:
			plot_line(x,0,x,320)
		x += 40
	
	var y: int = 0
	for i in range(8):
		if y > 0:
			plot_line(0,y,320,y)
		y += 40
		
	update_graphics()


func update_graphics() -> void:
	graphics_texture.update(graphics_buffer)


func plot_pixel(x: int, y:int) -> void:
	if range(0,graphics_buffer.get_width()).has(x):
		if range(0,graphics_buffer.get_height()).has(y):
			graphics_buffer.set_pixel(x,y,Color.LIGHT_GRAY)


func plot_line(x0: int, y0: int, x1: int, y1: int) -> void:
	var dx: int = absi(x1 - x0)
	var sx: int = -1
	if x0 < x1: sx = 1 
	var dy: int = - absi(y1 - y0)
	var sy: int = -1
	if y0 < y1: sy = 1 
	var error: int = dx + dy
	var e2: int = 0
		
	while true:
		plot_pixel(x0, y0)
		if x0 == x1 and y0 == y1: break
		e2 = 2 * error
		if e2 >= dy:
			if x0 == x1: break
			error = error + dy
			x0 = x0 + sx
		if e2 <= dx:
			if y0 == y1: break
			error = error + dx
			y0 = y0 + sy

#---------------------------------------------------
# Binary Tools
#---------------------------------------------------
func binary_to_int(binString: String) -> int:
	var rtn_int: int = 0
	var binArray: Array = binString.split("",true)
	var bitValue: int = 1
	for i: int in range(binArray.size() - 1, -1, -1):
		if binArray[i] == "1":
			rtn_int += bitValue
		bitValue *= 2
	return rtn_int


func to_binary(intValue: int) -> String:
	var bin_str: String = ""
	bin_str = String.num_int64(intValue, 2, false)
	while bin_str.length() < 8:
		bin_str = "0" + bin_str
		
	return bin_str


#---------------------------------------------------
# File Tools
#---------------------------------------------------
func get_file_contents(path: String) -> String:
	var file: Object = FileAccess.open(path, FileAccess.READ)
	if file:
		var filedata: String = file.get_as_text()
		var error: int = file.get_error()
		file.close()
		if error == OK:
			return filedata
		else:
			return "Error Reading File."
	else:
		return "Error Opening File."
		
	
func save_file(path: String, filedata: String) -> String:
	var file: Object = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(filedata)
		var error: int = file.get_error()
		file.close()
		if error == OK:
			return "File Saved."
		else:
			return "Error saving file."
	else: 
		return "An error occurred when trying to save the file."






