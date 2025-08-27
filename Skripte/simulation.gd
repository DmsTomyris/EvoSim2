extends Node2D

@export var num_agents: int = 10000
@export var speed: float = 50.0
@export var change_interval: float = 2.0
@export var interaction_distance: float = 15.0
@export var grid_size: int = 32   # Rastergröße für Feld und Spatial Hash

var multimesh := MultiMesh.new()
var positions: Array = []
var directions: Array = []
var timers: Array = []

var field_grid: Array = []   # deine Karte: 0 = frei, 1 = blockiert
var world_width = 1000 #2000
var world_height = 500 #2000

func _ready():
	randomize()

	# Multimesh vorbereiten
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = num_agents

	# Mesh für Sichtbarkeit
	var mesh := QuadMesh.new()
	mesh.size = Vector2(4, 4)
	multimesh.mesh = mesh

	var mm_instance = MultiMeshInstance2D.new()
	mm_instance.multimesh = multimesh
	add_child(mm_instance)

	# Spielfeld in Grid konvertieren
	_generate_field_grid()

	# Agents initialisieren
	for i in range(num_agents):
		var pos = Vector2(randf() * world_width, randf() * world_height)
		positions.append(pos)
		directions.append(Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized())
		timers.append(change_interval)
		multimesh.set_instance_transform_2d(i, Transform2D(0, pos))

func _process(delta):
	# Spatial Hash vorbereiten
	var hash := {}
	for i in range(positions.size()):
		var cell = Vector2i(int(positions[i].x / grid_size), int(positions[i].y / grid_size))
		if not hash.has(cell):
			hash[cell] = []
		hash[cell].append(i)

	# Agents updaten
	for i in range(positions.size()):
		# Richtung ändern?
		timers[i] -= delta
		if timers[i] <= 0.0:
			var angle = randf() * TAU
			directions[i] = Vector2(cos(angle), sin(angle)).normalized()
			timers[i] = change_interval

		# Bewegungsvorschlag
		var new_pos = positions[i] + directions[i] * speed * delta

		# Feld-Kollision prüfen
		if _is_free(new_pos):
			positions[i] = new_pos
		else:
			# Richtung umkehren bei Wand
			directions[i] = -directions[i]

		# Interaktionen prüfen (auskommentiert)
		# var cell = Vector2i(int(positions[i].x / grid_size), int(positions[i].y / grid_size))
		# for x in range(-1, 2):
		#     for y in range(-1, 2):
		#         var neighbor_cell = cell + Vector2i(x, y)
		#         if hash.has(neighbor_cell):
		#             for j in hash[neighbor_cell]:
		#                 if j != i and positions[i].distance_to(positions[j]) < interaction_distance:
		#                     # _on_interaction(i, j)  # hier wurde früher ein neuer Agent erzeugt

		# Update Multimesh
		multimesh.set_instance_transform_2d(i, Transform2D(0, positions[i]))

# Wand-Kollision gegen Feld-Grid
func _is_free(pos: Vector2) -> bool:
	var gx = int(pos.x / grid_size)
	var gy = int(pos.y / grid_size)
	if gx < 0 or gy < 0 or gx >= field_grid.size() or gy >= field_grid[0].size():
		return false
	return field_grid[gx][gy] == 0

func _generate_field_grid():
	# Beispiel: Alles frei
	var cols = int(world_width / grid_size)
	var rows = int(world_height / grid_size)
	field_grid.resize(cols)
	for x in range(cols):
		field_grid[x] = []
		for y in range(rows):
			field_grid[x].append(0)
	# hier kannst du deine CollisionShapes in Grid umwandeln!

# Auskommentierte Funktion für zukünftige Interaktion
# func _on_interaction(a: int, b: int):
#     if positions.size() < max_agents:
#         var pos = (positions[a] + positions[b]) / 2.0
#         positions.append(pos)
#         directions.append(Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized())
#         timers.append(change_interval)
#         multimesh.instance_count = positions.size()
#         multimesh.set_instance_transform_2d(positions.size()-1, Transform2D(0, pos))
