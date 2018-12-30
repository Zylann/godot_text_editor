extends Container


onready var _text_edit = get_node("TextEdit")
onready var _scrollbar = get_node("Scrollbar")


func _ready():
	_text_edit.connect("scroll_offset_changed", _scrollbar, "set_scroll_offset")
	_text_edit.connect("wrap_count_changed", _scrollbar, "set_total_lines")
	_scrollbar.set_total_lines(_text_edit.get_wrap_count())


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout():
	var scrollbar_ratio = 0.1
	var scrollbar_max_width = 140.0
	
	var scrollbar_width = rect_size.x * scrollbar_ratio
	if scrollbar_width > scrollbar_max_width:
		scrollbar_width = scrollbar_max_width
	
	var text_edit_width = rect_size.x - scrollbar_width
	
	fit_child_in_rect(_text_edit, Rect2(0, 0, text_edit_width, rect_size.y))
	fit_child_in_rect(_scrollbar, Rect2(text_edit_width, 0, scrollbar_width, rect_size.y))
	
	_scrollbar.set_region_lines_count(_text_edit.get_visible_lines_count())
