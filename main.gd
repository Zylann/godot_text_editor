extends Control

# Text editor prototype

class Line:
	var text = ""
	var format = []


class Wrap:
	var line_index = -1
	var start = 0
	var length = 0


var _font : Font
var _lines = []
var _wraps = []
var _tab_size = 4
var _tab_width = 0
var _tab_ord = "\t".ord_at(0)
var _default_text_color = Color(1, 1, 1, 1)
var _formats = []

var _keyword_regex = null
var _symbol_regex = null
var _string_regex = null
var _comment_regex = null


func _ready():
	_set_font(load("res://fonts/hack_regular.tres"))
	
	_formats = [
		{ "name": "default", "color": Color(0xddddddff) }, # Temporary
		{ "name": "keyword", "color": Color(0xffaa44ff) },
		{ "name": "comment", "color": Color(0x666666ff) },
		{ "name": "symbol", "color": Color(0xdd88ffff) },
		{ "name": "string", "color": Color(0x66ff55ff) }
	]

	var keywords = [
		"func",
		"var",
		"in",
		"len",
		"for",
		"while",
		"if",
		"elif",
		"else",
		"match",
		"class",
		"extends",
		"range",
		"return",
		"break",
		"continue",
		"load",
		"preload"
	]
	
	var keywords_regex_string = ""
	for i in len(keywords):
		if i != 0:
			keywords_regex_string += "|"
		keywords_regex_string = str(keywords_regex_string, "\\b", keywords[i], "\\b")
	_keyword_regex = RegEx.new()
	_keyword_regex.compile(keywords_regex_string)
	
	_symbol_regex = RegEx.new()
	_symbol_regex.compile("[\\.\\-\\*\\+/=\\[\\]\\(\\)\\<\\>\\{\\}\\:\\,]")
	
	_string_regex = RegEx.new()
	_string_regex.compile('"(?:[^"\\\\]|\\\\.)*"')
	
	_comment_regex = RegEx.new()
	_comment_regex.compile("#.*")

	_open_file("main.gd")


func _set_font(font):
	assert(font != null)
	if _font == font:
		return
	_font = font
	var char_width = _font.get_string_size("A").x
	_tab_width = char_width * _tab_size
	update()


func _open_file(path):
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file ", path, ", error ", err)
		return false
	var text = f.get_as_text()
	_set_text(text)
	return true


func _set_text(text):
	# TODO Preserve line endings
	var lines = text.split("\n")
	
	_lines.clear()
	_wraps.clear()
	
	for j in len(lines):
		
		var line = Line.new()
		line.text = lines[j]
		line.format = _compute_line_format(line.text)
		_lines.append(line)
		
		var wrap = Wrap.new()
		wrap.line_index = j
		wrap.start = 0
		wrap.length = len(line.text)
		_wraps.append(wrap)
	
	update()


func _compute_line_format(text):
	var format = []
	format.resize(len(text))
	for i in len(format):
		format[i] = 0
	
	var results = _keyword_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			format[i] = 1
	
	results = _symbol_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			format[i] = 3

	results = _string_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			format[i] = 4
	
	return format


func _draw():
	var line_height = _font.get_height()
	
	# TODO Use wraps for real vs logical lines representation
	for j in len(_lines):
		var line = _lines[j]
		var ci = get_canvas_item()
		var y = j * line_height + _font.get_ascent()
		
		var x = 0
		var col = _default_text_color
		
		for i in len(line.text):
			var c = line.text.ord_at(i)
			
			if len(line.format) == 0:
				col = _default_text_color
			else:
				var format_index = line.format[i]
				col = _formats[format_index].color
			
			x += _font.draw_char(ci, Vector2(x, y), c, -1, col)
			if c == _tab_ord:
				x += _tab_width



