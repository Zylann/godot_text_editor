extends Control


var _font : Font = load("res://fonts/hack_regular.tres")
var _lines = []
#var _colors = []


func _ready():
	_open_file("main.gd")


func _open_file(path):
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file ", path, ", error ", err)
		return false
	var text = f.get_as_text()
	_lines = text.split("\n")
	return true


func _draw():
	var line_height = _font.get_height()
	var char_width = _font.get_string_size("A").x
	var tab_width = char_width * 4
	var tab_ord = "\t".ord_at(0)
	
	for j in len(_lines):
		var line : String = _lines[j]
		var ci = get_canvas_item()
		var y = j * line_height + _font.get_ascent()
		
		var x = 0
		
		for i in len(line):
			var c = line.ord_at(i)
			x += _font.draw_char(ci, Vector2(x, y), c, -1, Color(1, 1, 1, 1))
			if c == tab_ord:
				x += tab_width



