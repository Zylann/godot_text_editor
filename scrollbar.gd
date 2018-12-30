extends Control


var _offset = 0
var _region_line_count = 10
var _line_height = 2
var _total_lines = 0
var _region_color = Color(0xffffff22)


func set_scroll_offset(so):
	if _offset == so:
		return
	_offset = so
	update()


func set_region_lines_count(lc):
	if _region_line_count == lc:
		return
	_region_line_count = lc
	update()


func set_total_lines(count):
	if _total_lines == count:
		return
	_total_lines = count
	update()


func _draw():
	draw_rect(_get_region_pixel_rect(), _region_color)


func _get_region_pixel_rect():
	var h = _region_line_count * _line_height
	var y = 0
	if _total_lines > 0:
		y = (rect_size.y - h) * float(_offset) / float(_total_lines)
	return Rect2(0, y, rect_size.x, h)

