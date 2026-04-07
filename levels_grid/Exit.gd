extends Area2D

@export var target_viewport: SubViewport

@onready var icon_sprite = $Icon

func _ready():
	# subviewport porad delal problemy, nedoporucuji (porad mizel z inspectoru)
	if target_viewport != null:
		icon_sprite.texture = target_viewport.get_texture()
