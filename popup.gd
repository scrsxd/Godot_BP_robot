extends Control

signal popup_closed
signal peek_started
signal peek_ended

@onready var title_label = %Title
@onready var desc_label = %Description
@onready var action_btn = %ButtonNext
@onready var peek_btn = %PeekButton

func _ready():
	hide() 
	modulate.a = 0.0 
	action_btn.pressed.connect(_on_button_pressed)
	
	peek_btn.focus_mode = Control.FOCUS_NONE 
	
	peek_btn.mouse_entered.connect(_on_peek_entered)
	peek_btn.mouse_exited.connect(_on_peek_exited)

func show_message(title_text: String, desc_text: String, btn_text: String, show_peek: bool = false):
	if not is_node_ready():
		await ready

	title_label.text = title_text
	desc_label.text = desc_text
	action_btn.text = btn_text
	
	peek_btn.visible = show_peek
	
	desc_label.visible_ratio = 0.0
	action_btn.disabled = true
	
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	show()
	
	var anim_tween = create_tween()
	anim_tween.set_parallel(true)
	anim_tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	anim_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.set_parallel(false)
	
	var typing_speed = desc_text.length() * 0.015
	anim_tween.tween_property(desc_label, "visible_ratio", 1.0, typing_speed)
	anim_tween.tween_callback(func(): action_btn.disabled = false)


func _on_peek_entered():
	peek_started.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.05, 0.15) 

func _on_peek_exited():
	peek_ended.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func _on_button_pressed():
	var out_tween = create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	out_tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	
	await out_tween.finished
	hide()
	popup_closed.emit()
