class_name FaceBadge
extends Control

## A small drawn face so each person is recognizable on the paper.

var skin := Color("e2b896")
var hair := Color("241c18")
var shirt := Color("2f7d72")


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var scale := minf(size.x, size.y) / 48.0
	if scale <= 0.0:
		return
	var mid := size * 0.5
	draw_circle(mid + Vector2(0, 8.0 * scale), 16.0 * scale, shirt)
	draw_circle(mid + Vector2(0, -2.0 * scale), 14.0 * scale, skin)
	draw_circle(mid + Vector2(0, -10.0 * scale), 11.0 * scale, hair)
	draw_circle(mid + Vector2(-5.0 * scale, -1.0 * scale), 1.8 * scale, Color("2b241c"))
	draw_circle(mid + Vector2(5.0 * scale, -1.0 * scale), 1.8 * scale, Color("2b241c"))


static func for_id(id: String) -> FaceBadge:
	var badge := FaceBadge.new()
	badge.apply_id(id)
	return badge


func apply_id(id: String) -> void:
	var look: Dictionary = LOOKS.get(id, {})
	if look.has("skin"):
		skin = look["skin"]
	if look.has("hair"):
		hair = look["hair"]
	if look.has("shirt"):
		shirt = look["shirt"]
	queue_redraw()


const LOOKS := {
	"mina": {"shirt": Color("2f7d72"), "hair": Color("241c18"), "skin": Color("e2b896")},
	"june": {"shirt": Color("3d5a80"), "hair": Color("6d4030"), "skin": Color("e8c4a8")},
	"otto": {"shirt": Color("c46a32"), "hair": Color("c4a060"), "skin": Color("dcb08a")},
	"ben": {"shirt": Color("a33d4e"), "hair": Color("2c2622"), "skin": Color("d4a888")},
	"rosa": {"shirt": Color("6e4d78"), "hair": Color("2a1814"), "skin": Color("e0b090")},
	"ken": {"shirt": Color("3f6b4a"), "hair": Color("1e1a16"), "skin": Color("d8b090")},
	"priya": {"shirt": Color("8a5a3a"), "hair": Color("1a1412"), "skin": Color("c48a62")},
	"sam": {"shirt": Color("3d6a8a"), "hair": Color("d4b48a"), "skin": Color("efc4a4")},
	"noor": {"shirt": Color("8a3d48"), "hair": Color("3a241c"), "skin": Color("e2b898")},
	"auntie": {"shirt": Color("8a5a3a"), "hair": Color("6d4030"), "skin": Color("e8c4a8")},
	"lau": {"shirt": Color("3d5a80"), "hair": Color("1e1a16"), "skin": Color("d4a888")},
	"influencer": {"shirt": Color("a33d4e"), "hair": Color("241c18"), "skin": Color("efc4a4")},
	"cafe": {"shirt": Color("3f6b4a"), "hair": Color("3a241c"), "skin": Color("e2b896")},
	"school": {"shirt": Color("5d7380"), "hair": Color("2c2622"), "skin": Color("e0b090")},
	"steady": {"shirt": Color("5f7d68"), "hair": Color("3a2c24"), "skin": Color("e2b896")},
	"cheap": {"shirt": Color("c46a32"), "hair": Color("c4a060"), "skin": Color("dcb08a")},
	"north": {"shirt": Color("5d7380"), "hair": Color("241c18"), "skin": Color("d4a888")},
	"harbor": {"shirt": Color("3d5a80"), "hair": Color("6d4030"), "skin": Color("e8c4a8")},
	"ink": {"shirt": Color("6e4d78"), "hair": Color("1a1412"), "skin": Color("e0b090")},
	"oak": {"shirt": Color("8a5a3a"), "hair": Color("3a241c"), "skin": Color("e2b896")},
	"cloth": {"shirt": Color("7d6a5a"), "hair": Color("d4b48a"), "skin": Color("efc4a4")},
	"glass": {"shirt": Color("4d6654"), "hair": Color("1e1a16"), "skin": Color("d8b090")},
	"nia": {"shirt": Color("c46a32"), "hair": Color("6d4030"), "skin": Color("e8c4a8")},
	"ellis": {"shirt": Color("3d5a80"), "hair": Color("1e1a16"), "skin": Color("d4a888")},
	"remy": {"shirt": Color("a33d4e"), "hair": Color("241c18"), "skin": Color("efc4a4")},
	"jordan": {"shirt": Color("3f6b4a"), "hair": Color("2c2622"), "skin": Color("e0b090")},
	"sable": {"shirt": Color("6e4d78"), "hair": Color("1a1412"), "skin": Color("e2b898")},
}
