extends Control

# Text editor prototype

class Line:
	var text = ""
	var format = []


class Wrap:
	var line_index = -1
	var start = 0
	var length = 0


const HL_DEFAULT = 0
const HL_KEYWORD = 1
const HL_COMMENT = 2
const HL_SYMBOL = 3
const HL_STRING = 4
const HL_TYPE = 5
const HL_NUMBER = 6
const HL_FUNCTION = 7
const HL_COUNT = 8


var _font : Font
var _tab_size = 4
var _tab_width = 0
var _tab_ord = "\t".ord_at(0)
var _default_text_color = Color(1, 1, 1, 1)
var _formats = []
var _scroll_speed = 4

var _scroll_offset = 0
var _smooth_scroll_offset = 0
var _smooth_scroll_offset_prev = 0.0
var _smooth_scroll_time = 0.0
var _smooth_scroll_duration = 0.1
var _lines = []
var _wraps = []

var _line_numbers_gutter_width = 70
var _line_numbers_color = Color(0x666666ff)
var _line_numbers_right_padding = 25

var _keyword_regex = null
var _symbol_regex = null
var _string_regex = null
var _capitalized_word_regex = null
var _number_regex = null
var _func_regex = null


func _ready():
	_set_font(load("res://fonts/hack_regular.tres"))
	_load_colors()
	_load_syntax()
	_open_file("D:/PROJETS/INFO/GODOT/Plugins/HTerrain/heightmap/addons/zylann.hterrain/hterrain.gd")


func _load_colors():
	_formats.resize(HL_COUNT)
	_formats[HL_DEFAULT] = { "name": "default", "color": Color(0xdfdfdfff) }
	_formats[HL_KEYWORD] = { "name": "keyword", "color": Color(0xffaa44ff) }
	_formats[HL_COMMENT] = { "name": "comment", "color": Color(0x888888ff) }
	_formats[HL_SYMBOL] = { "name": "symbol", "color": Color(0xdd88ffff) }
	_formats[HL_STRING] = { "name": "string", "color": Color(0x66ff55ff) }
	_formats[HL_TYPE] = { "name": "type", "color": Color(0xffff55ff) }
	_formats[HL_NUMBER] = { "name": "number", "color": Color(0x6699ffff) }
	_formats[HL_FUNCTION] = { "name": "function", "color": Color(0xaaddffff) }


func _load_syntax():
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
		"is",
		"as",
		"range",
		"return",
		"break",
		"continue",
		"breakpoint",
		"preload",
		"yield",
		"onready",
		"const",
		"signal",
		"export",
		"static",
		"tool",
		"self",
		"and",
		"or",
		"xor",
		"not",
		
		"true",
		"false",
		"null",

		"load",
		"floor",
		"ceil",
		"round",
		"sqrt",
		"sign",
		"stepify",
		"exp",
		"ease",
		"decimals",
		"db2linear",
		"sin",
		"sinh",
		"asin",
		"cos",
		"cosh",
		"acos",
		"tan",
		"tanh",
		"atan",
		"atan2",
		"min",
		"max",
		"clamp",
		"print",
		"printerr",
		"print_stack",
		"print_debug",
		"str2var",
		"str",
		"int",
		"float",
		"bool",
		"seed",
		"randf",
		"randi",
		"randomize",
		"rand_range",
		"lerp",
		"range_lerp",
		"assert",
		"convert",
		"typeof",
		"type_exists",
		"weakref",
		"to_json",
		"wrapf",
		"wrapi"
	]
	
	var keywords_regex_string = ""
	for i in len(keywords):
		if i != 0:
			keywords_regex_string += "|"
		keywords_regex_string = str(keywords_regex_string, "\\b", keywords[i], "\\b")
	_keyword_regex = RegEx.new()
	_keyword_regex.compile(keywords_regex_string)
	
	var symbols = ".-*+/=[]()<>{}:,!|^"
	var symbols_regex_string = "["
	for i in len(symbols):
		symbols_regex_string = str(symbols_regex_string, "\\", symbols[i])
	symbols_regex_string += "]"
	_symbol_regex = RegEx.new()
	_symbol_regex.compile(symbols_regex_string)
	
	_string_regex = RegEx.new()
	_string_regex.compile('"(?:[^"\\\\]|\\\\.)*"')
	
	_capitalized_word_regex = RegEx.new()
	_capitalized_word_regex.compile("\\b[A-Z]+[a-zA-Z0-9_]+\\b")
	
	_number_regex = RegEx.new()
	_number_regex.compile("(?:-|\\b)[0-9]x?[0-9a-fA-F\\.]*")
	
	_func_regex = RegEx.new()
	_func_regex.compile("\\w+\\(")


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			
			if event.button_index == BUTTON_WHEEL_UP:
				_scroll(-_scroll_speed)
				
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_scroll(_scroll_speed)


func _scroll(delta):
	_scroll_offset += delta
	
	if _scroll_offset < 0:
		_scroll_offset = 0
	elif _scroll_offset >= len(_wraps):
		_scroll_offset = len(_wraps) - 1
	
	if _smooth_scroll_duration > 0.01:
		_smooth_scroll_time = _smooth_scroll_duration
		_smooth_scroll_offset_prev = _smooth_scroll_offset
	else:
		_smooth_scroll_time = 0.0
		_smooth_scroll_offset = _scroll_offset
	
	update()


func _process(delta):
	if _smooth_scroll_time > 0.0:
		_smooth_scroll_time -= delta
		if _smooth_scroll_time < 0.0:
			_smooth_scroll_time = 0.0
		var t = clamp(1.0 - _smooth_scroll_time / _smooth_scroll_duration, 0.0, 1.0)
		t = sqrt(t)
		_smooth_scroll_offset = lerp(_smooth_scroll_offset_prev, _scroll_offset, t)
		update()


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
	var time_before = OS.get_ticks_usec()
	
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
	
	var time_spent = OS.get_ticks_usec() - time_before
	print("_set_text time: ", time_spent / 1000.0, "ms")
	update()


func _compute_line_format(text):
	var format = []
	format.resize(len(text))
	for i in len(format):
		format[i] = HL_DEFAULT
	
	var results
	
	# TODO Keywords take about 40% of the time, find a way to optimize this
	results = _keyword_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			format[i] = HL_KEYWORD
	
	results = _number_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			if format[i] == HL_DEFAULT:
				format[i] = HL_NUMBER

	results = _symbol_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			if format[i] == HL_DEFAULT:
				format[i] = HL_SYMBOL

	results = _string_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			format[i] = HL_STRING
	
	var comment_start = text.find("#")
	while comment_start != -1:
		if format[comment_start] == 4:
			comment_start = text.find("#", comment_start + 1)
		else:
			for i in range(comment_start, len(text)):
				format[i] = HL_COMMENT
			break
	
	results = _capitalized_word_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0)
		for i in range(begin, end):
			if format[i] == HL_DEFAULT:
				format[i] = HL_TYPE

	results = _func_regex.search_all(text)
	for res in results:
		var begin = res.get_start(0)
		var end = res.get_end(0) - 1
		for i in range(begin, end):
			if format[i] == HL_DEFAULT:
				format[i] = HL_FUNCTION
	
	return format


func _draw():
	var line_height = int(_font.get_height())
	var scroll_offset = _smooth_scroll_offset
	
	var y = 1.0 - line_height * (scroll_offset - int(scroll_offset))
	y += _font.get_ascent()
	
	var width = rect_size.x
	
	var visible_lines = int(rect_size.y) / line_height
	var begin_line_index = int(scroll_offset)
	var end_line_index = begin_line_index + visible_lines

	if begin_line_index >= len(_wraps):
		begin_line_index = len(_wraps) - 1
	
	if end_line_index >= len(_wraps):
		end_line_index = len(_wraps) - 1
	
	for j in range(begin_line_index, end_line_index):
		
		var wrap = _wraps[j]
		var line = _lines[wrap.line_index]
		var ci = get_canvas_item()

		var x = 0
		
		x += _line_numbers_gutter_width
		if wrap.start == 0:
			var ln = str(wrap.line_index + 1)
			var s = _font.get_string_size(ln)
			_font.draw(ci, Vector2(x - _line_numbers_right_padding - s.x, y), ln, _line_numbers_color)
		
		var col = _default_text_color
		
		for i in range(wrap.start, wrap.start + wrap.length):
			var c = line.text.ord_at(i)
			
			if len(line.format) == 0:
				col = _default_text_color
			else:
				var format_index = line.format[i]
				col = _formats[format_index].color
			
			x += _font.draw_char(ci, Vector2(x, y), c, -1, col)
			if c == _tab_ord:
				x += _tab_width
			
			if x >= width:
				# TODO Word wrap
				break
		
		y += line_height



