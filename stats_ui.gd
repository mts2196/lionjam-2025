extends Control

# Stats (0-100 scale)
var integrity: int = 100
var oxygen: int = 100
var power: int = 100
var growth: int = 0

# References to labels
@onready var integrity_label = $VBoxContainer/IntegrityLabel
@onready var oxygen_label = $VBoxContainer/OxygenLabel
@onready var power_label = $VBoxContainer/PowerLabel
@onready var growth_label = $VBoxContainer/GrowthLabel

func _ready():
	update_stats_display()  # Update the display when the game starts

# Updates the UI labels
func update_stats_display():
	integrity_label.text = "Integrity: %d" % integrity
	oxygen_label.text = "Oxygen: %d" % oxygen
	power_label.text = "Power: %d" % power
	growth_label.text = "Growth: %d" % growth

# Example function to modify stats (call this from gameplay events)
func modify_stats(delta_integrity=0, delta_oxygen=0, delta_power=0, delta_growth=0):
	integrity = clamp(integrity + delta_integrity, 0, 100)
	oxygen = clamp(oxygen + delta_oxygen, 0, 100)
	power = clamp(power + delta_power, 0, 100)
	growth = clamp(growth + delta_growth, 0, 100)
	update_stats_display()
