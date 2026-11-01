extends Node2D

## Standalone prototype for the island map. Press R to generate a new island.
const ISLAND_COAST_GEOMETRY := preload("res://script/map/island_coast_geometry.gd")
const TILE_SIZE := 32
const MAP_WIDTH := 44
const MAP_HEIGHT := 28
const OCEAN_TEXTURE: Texture2D = preload("res://art/tileset/32x32mapchip_20210215/Autotile_Expanded/No_Animation/[A]Water1_pipo.png")
const GRASS_TEXTURE: Texture2D = preload("res://art/tileset/32x32mapchip_20210215/Autotile_Expanded/[A]Grass1-Grass2_pipo.png")
const OCEAN_TILE := Vector2i(6, 1)
const GRASS_TILE := Vector2i(6, 1)

## sample4.tmx の境界レイヤーから取得した基本形。
## 欠け方向は上・右・下・左 = 1・2・4・8。
const COAST_TILE_BY_MISSING_MASK := {
	1: Vector2i(6, 2),
	2: Vector2i(5, 1),
	4: Vector2i(6, 0),
	8: Vector2i(7, 1),
	3: Vector2i(5, 3),
	6: Vector2i(5, 4),
	9: Vector2i(4, 3),
	12: Vector2i(4, 4),
}
const DIAGONAL_CORNER_TILE := Vector2i(5, 2)
const DIAGONAL_TRANSFORM_BY_MISSING_MASK := {
	1: 0,
	2: TileSetAtlasSource.TRANSFORM_FLIP_V,
	4: TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	8: TileSetAtlasSource.TRANSFORM_FLIP_H,
}
## sample4.tmx で形状を確認できた角チップ。キーは「上下左右の欠け/斜めの欠け」。
const COAST_CORNER_TILE_BY_TOPOLOGY := {
	"3/3": Vector2i(5, 3),
	"3/11": Vector2i(5, 3),
	"9/13": Vector2i(4, 3),
	"12/14": Vector2i(4, 4),
}

var _ocean_layer: TileMapLayer
var _land_layer: TileMapLayer
var _coast_layer: TileMapLayer
var _rng := RandomNumberGenerator.new()
var _seed_value: int
var _seed_label: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_preview()
	_regenerate()


func _build_preview() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(MAP_WIDTH, MAP_HEIGHT) * TILE_SIZE * 0.5
	camera.zoom = Vector2(0.75, 0.75)
	camera.enabled = true
	add_child(camera)

	_ocean_layer = TileMapLayer.new()
	_ocean_layer.tile_set = _make_tileset(OCEAN_TEXTURE, [OCEAN_TILE])
	_ocean_layer.z_index = 0
	add_child(_ocean_layer)

	_land_layer = TileMapLayer.new()
	_land_layer.tile_set = _make_tileset(GRASS_TEXTURE, [GRASS_TILE])
	_land_layer.z_index = 1
	add_child(_land_layer)

	var coast_coords: Array[Vector2i] = []
	for tile_value in COAST_TILE_BY_MISSING_MASK.values():
		_append_unique_tile(coast_coords, tile_value)
	for tile_value in COAST_CORNER_TILE_BY_TOPOLOGY.values():
		_append_unique_tile(coast_coords, tile_value)
	_append_unique_tile(coast_coords, DIAGONAL_CORNER_TILE)
	_coast_layer = TileMapLayer.new()
	_coast_layer.tile_set = _make_tileset(OCEAN_TEXTURE, coast_coords)
	_coast_layer.z_index = 2
	add_child(_coast_layer)

	var overlay := CanvasLayer.new()
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.add_theme_stylebox_override("panel", _make_header_style())
	overlay.add_child(panel)
	_seed_label = Label.new()
	_seed_label.add_theme_font_size_override("font_size", 20)
	_seed_label.add_theme_color_override("font_color", Color(0.93, 0.97, 0.91))
	panel.add_child(_seed_label)


func _make_tileset(texture: Texture2D, coords: Array[Vector2i]) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for coords_value in coords:
		atlas.create_tile(coords_value)
	tile_set.add_source(atlas, 0)
	return tile_set


func _make_header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.09, 0.88)
	style.border_color = Color(0.42, 0.75, 0.67, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _append_unique_tile(coords: Array[Vector2i], tile: Vector2i) -> void:
	if not coords.has(tile):
		coords.append(tile)


func _regenerate() -> void:
	_seed_value = int(Time.get_ticks_usec()) ^ randi()
	_rng.seed = _seed_value
	_seed_label.text = "Random Island   seed: %d   [R] regenerate" % _seed_value
	_ocean_layer.clear()
	_land_layer.clear()
	_coast_layer.clear()
	var land_cells := _generate_land_mask()
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			_ocean_layer.set_cell(Vector2i(x, y), 0, OCEAN_TILE)
	for cell_value in land_cells:
		var cell: Vector2i = cell_value
		_land_layer.set_cell(cell, 0, GRASS_TILE)
	for cell_value in land_cells:
		var cell: Vector2i = cell_value
		var missing_mask := _missing_cardinal_mask(land_cells, cell)
		var diagonal_missing_mask := _missing_diagonal_mask(land_cells, cell)
		var topology_key := "%d/%d" % [missing_mask, diagonal_missing_mask]
		var coast_tile := _choose_coast_tile(missing_mask)
		var transform := 0
		if COAST_CORNER_TILE_BY_TOPOLOGY.has(topology_key):
			coast_tile = COAST_CORNER_TILE_BY_TOPOLOGY[topology_key]
		elif missing_mask == 0 and DIAGONAL_TRANSFORM_BY_MISSING_MASK.has(diagonal_missing_mask):
			coast_tile = DIAGONAL_CORNER_TILE
			transform = DIAGONAL_TRANSFORM_BY_MISSING_MASK[diagonal_missing_mask]
		elif missing_mask == 0:
			continue
		_coast_layer.set_cell(cell, 0, coast_tile, transform)


func _generate_land_mask() -> Dictionary:
	# Irregular radial profile gives a single connected main island with coves and peninsulas.
	var center := Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5)
	var radius_x: float = MAP_WIDTH * _rng.randf_range(0.34, 0.39)
	var radius_y: float = MAP_HEIGHT * _rng.randf_range(0.34, 0.40)
	var profile: Array[float] = []
	const PROFILE_SAMPLES := 24
	for index in range(PROFILE_SAMPLES):
		profile.append(_rng.randf_range(0.90, 1.10))
	var smoothed_profile := profile.duplicate()
	for index in range(PROFILE_SAMPLES):
		var previous: float = profile[posmod(index - 1, PROFILE_SAMPLES)]
		var current: float = profile[index]
		var next: float = profile[(index + 1) % PROFILE_SAMPLES]
		smoothed_profile[index] = previous * 0.25 + current * 0.5 + next * 0.25

	var bays: Array[Dictionary] = []
	for _bay_index in range(_rng.randi_range(2, 4)):
		bays.append({
			"angle": _rng.randf_range(-PI, PI),
			"width": _rng.randf_range(0.16, 0.28),
			"depth": _rng.randf_range(0.12, 0.27),
		})

	var land: Dictionary = {}
	var phase: float = _rng.randf_range(0.0, TAU)
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var offset := Vector2((float(x) + 0.5 - center.x) / radius_x, (float(y) + 0.5 - center.y) / radius_y)
			var angle := atan2(offset.y, offset.x)
			var profile_position: float = (angle + PI) / TAU * PROFILE_SAMPLES
			var profile_index := int(floor(profile_position)) % PROFILE_SAMPLES
			var profile_next := (profile_index + 1) % PROFILE_SAMPLES
			var profile_mix: float = profile_position - floor(profile_position)
			var limit: float = lerpf(smoothed_profile[profile_index], smoothed_profile[profile_next], profile_mix)
			limit += sin(angle * 5.0 + phase) * 0.035 + cos(angle * 9.0 - phase) * 0.02
			for bay in bays:
				var angle_delta: float = wrapf(angle - float(bay["angle"]), -PI, PI)
				var width: float = float(bay["width"])
				limit -= float(bay["depth"]) * exp(-pow(angle_delta / width, 2.0))
			if offset.length() <= limit:
				land[Vector2i(x, y)] = true

	# Remove single-cell teeth and tiny holes before selecting shoreline tiles.
	# The old detached-islet pass could create one-cell islands, which have no
	# matching coast tile and therefore appeared as stray slivers in the ocean.
	return ISLAND_COAST_GEOMETRY.smooth_and_sanitize_land(land, MAP_WIDTH, MAP_HEIGHT, COAST_TILE_BY_MISSING_MASK)


func _missing_cardinal_mask(land_cells: Dictionary, cell: Vector2i) -> int:
	return ISLAND_COAST_GEOMETRY.missing_cardinal_mask(land_cells, cell)


func _missing_diagonal_mask(land_cells: Dictionary, cell: Vector2i) -> int:
	return ISLAND_COAST_GEOMETRY.missing_diagonal_mask(land_cells, cell)


func _choose_coast_tile(missing_mask: int) -> Vector2i:
	return ISLAND_COAST_GEOMETRY.coast_tile_for_missing_mask(missing_mask, COAST_TILE_BY_MISSING_MASK)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_regenerate()
