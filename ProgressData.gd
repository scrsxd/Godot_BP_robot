extends Node

var has_antenna: bool = false
var has_jet: bool = false
var has_engine: bool = false
var next_level: PackedScene = null

var part_to_animate: String = ""

# reset vseho kdyby byl restart
func reset_progress():
	has_antenna = false
	has_jet = false
	has_engine = false
	part_to_animate = ""
