extends RefCounted

## Keeps generated island cells compatible with the coast atlas.
static func smooth_and_sanitize_land(
	land_cells: Dictionary,
	map_width: int,
	map_height: int,
	supported_coast_tiles: Dictionary
) -> Dictionary:
	var smoothed: Dictionary = land_cells.duplicate()
	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var neighbor_count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if land_cells.has(cell + Vector2i(dx, dy)):
						neighbor_count += 1
			if land_cells.has(cell) and neighbor_count <= 2:
				smoothed.erase(cell)
			elif not land_cells.has(cell) and neighbor_count >= 7:
				smoothed[cell] = true
	return _sanitize_coast_geometry(smoothed, map_width, map_height, supported_coast_tiles)


static func _sanitize_coast_geometry(
	land_cells: Dictionary,
	map_width: int,
	map_height: int,
	supported_coast_tiles: Dictionary
) -> Dictionary:
	var result: Dictionary = land_cells.duplicate()
	# Trim narrow tips/necks that would otherwise need a coast shape absent from the atlas.
	for _pass in range(maxi(map_width, map_height)):
		var to_remove: Array[Vector2i] = []
		for cell_value in result.keys():
			var cell: Vector2i = cell_value
			var missing_mask := missing_cardinal_mask(result, cell)
			if missing_mask != 0 and not supported_coast_tiles.has(missing_mask):
				to_remove.append(cell)
		if to_remove.is_empty():
			break
		for cell in to_remove:
			result.erase(cell)
	return _keep_largest_landmass(result)


static func _keep_largest_landmass(land_cells: Dictionary) -> Dictionary:
	var visited: Dictionary = {}
	var largest_component: Array[Vector2i] = []
	for cell_value in land_cells.keys():
		var start: Vector2i = cell_value
		if visited.has(start):
			continue
		var component: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start]
		visited[start] = true
		var queue_index := 0
		while queue_index < queue.size():
			var current: Vector2i = queue[queue_index]
			queue_index += 1
			component.append(current)
			for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var neighbor: Vector2i = current + direction
				if land_cells.has(neighbor) and not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
		if component.size() > largest_component.size():
			largest_component = component
	var result: Dictionary = {}
	for cell in largest_component:
		result[cell] = true
	return result


static func missing_cardinal_mask(land_cells: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	if not land_cells.has(cell + Vector2i.UP):
		mask |= 1
	if not land_cells.has(cell + Vector2i.RIGHT):
		mask |= 2
	if not land_cells.has(cell + Vector2i.DOWN):
		mask |= 4
	if not land_cells.has(cell + Vector2i.LEFT):
		mask |= 8
	return mask


static func missing_diagonal_mask(land_cells: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	if not land_cells.has(cell + Vector2i(1, -1)):
		mask |= 1
	if not land_cells.has(cell + Vector2i(1, 1)):
		mask |= 2
	if not land_cells.has(cell + Vector2i(-1, 1)):
		mask |= 4
	if not land_cells.has(cell + Vector2i(-1, -1)):
		mask |= 8
	return mask


static func coast_tile_for_missing_mask(missing_mask: int, coast_tiles_by_mask: Dictionary) -> Vector2i:
	if coast_tiles_by_mask.has(missing_mask):
		return coast_tiles_by_mask[missing_mask]
	var best_tile: Vector2i = coast_tiles_by_mask[1]
	var best_overlap := -1
	for supported_mask in coast_tiles_by_mask:
		var overlap := _count_mask_bits(missing_mask & int(supported_mask))
		if overlap > best_overlap:
			best_overlap = overlap
			best_tile = coast_tiles_by_mask[supported_mask]
	return best_tile


static func _count_mask_bits(mask: int) -> int:
	var result := 0
	for bit in [1, 2, 4, 8]:
		if (mask & bit) != 0:
			result += 1
	return result
