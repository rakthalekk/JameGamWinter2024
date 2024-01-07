class_name CardData
extends Sprite2D

enum CARDTYPE { PUNCH, KICK, GRAPPLE, FINISHER, DIRECTION, UTILITY }

@export var display_name : String
@export var type : CARDTYPE
@export_multiline var description : String
@export var damage : int
@export var health_cost : int
@export var stamina_cost : int
@export var sp_cost : int
@export var stamina_debuff_chance : int
@export var stunned_chance : int
@export var unpopular_chance : int
@export var low_health_damage_multiplier : float
