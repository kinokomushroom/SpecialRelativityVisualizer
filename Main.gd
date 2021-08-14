tool
extends Node2D


var viewport_size : Vector2

export var background_color : Color = Color.black
export var graph_background_color : Color = Color.black
export var graph_border_color : Color = Color.white
export var x_axis_color : Color = Color.red
export var y_axis_color : Color = Color.green
export var light_color : Color = Color.yellow
export var grid_color_gradient : Gradient
export var single_grid_color : Color = Color.white
export var base_grid_color : Color = Color.white
export var line_default_color : Color = Color.white
export var point_default_color : Color = Color.white
export var length_contraction_color : Color = Color.blue
export var time_dilation_color : Color = Color.red
export var grid_display_count : int = 2
export var line_display_count : int = 4
export var point_display_count : int = 5
export var point_size : float = 4.0

export var display_grids : bool = true
export var display_lines : bool = true
export var display_points : bool = true
export var display_single_grid : bool = true
export var display_base_grid : bool = true
export var display_extra_data : bool = true

export var graph_center : Vector2 = Vector2(0.5, 0.5)
export var graph_extent : Vector2 = Vector2(0.4, 0.4)
export var graph_unit_length : float = 0.1
export var grid_line_number : int = 4

export var change : float = 0.0

var light_basis_positive : Vector2 = Vector2(100, 100)
var light_basis_negative : Vector2 = Vector2(-100, 100)


func map_range(value : float, from_start : float, from_end : float, to_start : float, to_end : float) -> float:
	var result : float = value
	result -= from_start
	result /= (from_end - from_start)
	result *= (to_end - to_start)
	result += to_start
	return result

func add_velocities(velocity_1 : float, velocity_2 : float) -> float:
	return (velocity_1 + velocity_2) / (1 + velocity_1 * velocity_2)

func change_velocity(amount : float, acceleration : float) -> float:
	return 2 / (pow(2 / (acceleration + 1) - 1, amount) + 1) - 1

func velocity_to_transform(velocity : float) -> Transform2D:
	if velocity == 1.0:
		return Transform2D(light_basis_positive, light_basis_positive, Vector2(0, 0))
	elif velocity == -1.0:
		return Transform2D(light_basis_negative, light_basis_negative, Vector2(0, 0))
	else:
		var gamma : float = 1.0 / sqrt(1.0 - velocity * velocity)
		var x_basis : Vector2 = Vector2(gamma, velocity * gamma)
		var y_basis : Vector2 = Vector2(velocity * gamma, gamma)
		return Transform2D(x_basis, y_basis, Vector2(0, 0))

func grid_to_graph(grid_transform : Transform2D, grid_coord : Vector2) -> Vector2:
	return grid_transform.xform(grid_coord)

func graph_to_viewport(graph_coord : Vector2) -> Vector2:
	return (graph_center + graph_unit_length * graph_coord) * viewport_size * Vector2(1, -1) + Vector2(0, viewport_size.y)

func graph_draw_line(grid_transform : Transform2D, line_center : Vector2, line_direction : Vector2, line_width : float, line_color : Color):
	var line_start : Vector2 = graph_to_viewport(grid_to_graph(grid_transform, line_center - line_direction * grid_line_number))
	var line_end : Vector2 = graph_to_viewport(grid_to_graph(grid_transform, line_center + line_direction * grid_line_number))
	draw_line(line_start, line_end, line_color, line_width)

func graph_draw_point(grid_transform : Transform2D, point_coord : Vector2, point_size : float, point_color : Color):
	draw_circle(graph_to_viewport(grid_to_graph(grid_transform, point_coord)), point_size, point_color)

func draw_grid(grid_transform : Transform2D, color : Color):
	for line_index in range(1, grid_line_number):
		graph_draw_line(grid_transform, Vector2(line_index, 0), Vector2(0, 1), 1.0, color)
		graph_draw_line(grid_transform, Vector2(-line_index, 0), Vector2(0, 1), 1.0, color)
		graph_draw_line(grid_transform, Vector2(0, line_index), Vector2(1, 0), 1.0, color)
		graph_draw_line(grid_transform, Vector2(0, -line_index), Vector2(1, 0), 1.0, color)
	graph_draw_line(grid_transform, Vector2(0, 0), Vector2(1, 0), 2.0, color)
	graph_draw_line(grid_transform, Vector2(0, 0), Vector2(0, 1), 2.0, color)

func _draw():
	# graph background
	draw_rect(Rect2(Vector2(0, 0), viewport_size), graph_background_color, true)
	
	var basic_transform : Transform2D = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0))
	
	# grids
	if display_grids:
		var grid_change : float = ceil(change - grid_display_count)
		while grid_change <= floor(change + grid_display_count):
			var grid_velocity : float = change_velocity(change - grid_change, 0.5)
			var grid_color : Color = grid_color_gradient.interpolate(map_range(change - grid_change, -grid_display_count, grid_display_count, 0.0, 1.0))
			grid_color.a = pow(map_range(abs(change - grid_change), 0.0, grid_display_count, 1.0, 0.0), 1.5)
			draw_grid(velocity_to_transform(grid_velocity), grid_color)
			grid_change += 1.0
	
	if display_single_grid:
		var grid_velocity : float = change_velocity(change, 0.5)
		var grid_color : Color = single_grid_color
		grid_color.a = 1.0 / pow(velocity_to_transform(grid_velocity).x.length(), 0.5)
		draw_grid(velocity_to_transform(grid_velocity), grid_color)
	
	if display_base_grid:
		draw_grid(velocity_to_transform(0.0), base_grid_color)
	
	# x and y axes
	graph_draw_line(basic_transform, Vector2(0, 0), Vector2(1, 0), 2.0, x_axis_color)
	graph_draw_line(basic_transform, Vector2(0, 0), Vector2(0, 1), 2.0, y_axis_color)
	var x_y_added : Color = x_axis_color + y_axis_color
	x_y_added.a = 1.0
	graph_draw_point(basic_transform, Vector2(0, 0), 1.0, x_y_added)
	
	# lines
	if display_lines:
		var line_change : float = ceil(change - line_display_count)
		while line_change <= floor(change + line_display_count):
			var line_velocity : float = change_velocity(change - line_change, 0.5)
			var line_color : Color = line_default_color
			line_color.a = pow(map_range(abs(change - line_change), 0.0, line_display_count, 1.0, 0.0), 0.5)
			graph_draw_line(velocity_to_transform(line_velocity), Vector2(0, 0), Vector2(0, 1), 2.0, line_color)
			line_change += 1.0
	
	# light
	graph_draw_line(velocity_to_transform(1.0), Vector2(0, 0), Vector2(0, 1), 2.0, light_color)
	graph_draw_line(velocity_to_transform(-1.0), Vector2(0, 0), Vector2(0, 1), 2.0, light_color)
	
	# points
	if display_points:
		var point_change : float = ceil(change - point_display_count)
		while point_change <= floor(change + point_display_count):
			var point_velocity : float = change_velocity(change - point_change, 0.5)
			graph_draw_point(velocity_to_transform(point_velocity), Vector2(0, 1), point_size, point_default_color)
			point_change += 1.0
	
	var graph_bottom_left : Vector2 = graph_to_viewport(graph_extent / graph_unit_length * Vector2(-1, -1))
	var graph_bottom_right : Vector2 = graph_to_viewport(graph_extent / graph_unit_length * Vector2(1, -1))
	var graph_top_left : Vector2 = graph_to_viewport(graph_extent / graph_unit_length * Vector2(-1, 1))
	var graph_top_right : Vector2 = graph_to_viewport(graph_extent / graph_unit_length * Vector2(1, 1))
	
	# length contraction and time dilation
	if display_extra_data:
		var velocity = change_velocity(change, 0.5)
		var gamma : float = 1.0 / sqrt(1.0 - velocity * velocity)
		# length contraction
		graph_draw_point(velocity_to_transform(0.0), Vector2(1, 0), point_size, length_contraction_color)
		graph_draw_point(velocity_to_transform(0.0), Vector2(1, 0) / gamma, point_size, length_contraction_color)
		# time dilation
		var start_point : Vector2 = graph_to_viewport(velocity_to_transform(velocity).xform(Vector2(0, 1)))
		var end_point : Vector2 = graph_to_viewport(Vector2(0, 1) * gamma)
		draw_line(start_point, end_point, time_dilation_color, 1.0)
		graph_draw_point(velocity_to_transform(0.0), Vector2(0, 1), point_size, time_dilation_color)
		graph_draw_point(velocity_to_transform(velocity), Vector2(0, 1), point_size, time_dilation_color)
		graph_draw_point(velocity_to_transform(0.0), Vector2(0, 1) * gamma, point_size, time_dilation_color)
	
	# graph surrounding background
	draw_rect(Rect2(Vector2(0, 0), Vector2(graph_bottom_left.x, viewport_size.y)), background_color, true)
	draw_rect(Rect2(Vector2(0, 0), Vector2(viewport_size.x, graph_top_right.y)), background_color, true)
	draw_rect(Rect2(Vector2(graph_top_right.x, 0), viewport_size - Vector2(graph_top_right.x, 0)), background_color, true)
	draw_rect(Rect2(Vector2(0, graph_bottom_left.y), viewport_size - Vector2(0, graph_bottom_left.y)), background_color, true)
	
	# graph border lines
	draw_line(graph_bottom_left, graph_bottom_right, graph_border_color, 2.0)
	draw_line(graph_top_left, graph_top_right, graph_border_color, 2.0)
	draw_line(graph_bottom_left, graph_top_left, graph_border_color, 2.0)
	draw_line(graph_bottom_right, graph_top_right, graph_border_color, 2.0)

func _ready():
	pass

func _process(delta):
	viewport_size = get_viewport_rect().size
	
	# display time dilation and length contraction
	$Control/extra.visible = display_extra_data
	var velocity = change_velocity(change, 0.5)
	var gamma : float = 1.0 / sqrt(1.0 - velocity * velocity)
	$Control/extra/time_dilation.text = String(gamma)
	$Control/extra/length_contraction.text = String(1.0 / gamma)
	
	update()


func _on_grids_toggled(button_pressed):
	display_grids = button_pressed

func _on_lines_toggled(button_pressed):
	display_lines = button_pressed

func _on_points_toggled(button_pressed):
	display_points = button_pressed

func _on_base_grid_toggled(button_pressed):
	display_base_grid = button_pressed

func _on_single_grid_toggled(button_pressed):
	display_single_grid = button_pressed

func _on_extra_data_toggled(button_pressed):
	display_extra_data = button_pressed

func _on_change_value_changed(value):
	change = value
